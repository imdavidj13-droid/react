create extension if not exists pgcrypto;

create table public.player_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint player_profiles_display_name_length
    check (char_length(display_name) between 3 and 20)
);

create unique index player_profiles_display_name_unique
  on public.player_profiles (lower(display_name));

create or replace function public.handle_new_react_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.player_profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      'PLAYER-' || upper(substr(replace(new.id::text, '-', ''), 1, 6))
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created_react_profile
after insert on auth.users
for each row execute function public.handle_new_react_user();

create table public.leaderboard_submissions (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.player_profiles(id) on delete cascade,
  client_submission_id text not null,
  schema_version smallint not null default 1,
  mode text not null,
  score integer not null,
  successful_commands integer not null,
  average_reaction_seconds double precision not null,
  misses integer not null,
  max_streak integer not null,
  outcome text not null,
  completed_at timestamptz not null,
  daily_date date,
  daily_modifier_label text,
  created_at timestamptz not null default now(),
  constraint leaderboard_submission_client_id_length
    check (char_length(client_submission_id) between 8 and 128),
  constraint leaderboard_submission_schema_version
    check (schema_version = 1),
  constraint leaderboard_submission_mode
    check (mode in ('classic', 'blitz', 'endless', 'daily', 'sequence')),
  constraint leaderboard_submission_score
    check (score >= 0 and successful_commands >= 0 and score = successful_commands),
  constraint leaderboard_submission_average
    check (
      average_reaction_seconds >= 0
      and average_reaction_seconds <= 15
      and (successful_commands = 0 or average_reaction_seconds > 0)
    ),
  constraint leaderboard_submission_misses
    check (misses between 0 and 3),
  constraint leaderboard_submission_streak
    check (max_streak >= 0 and max_streak <= successful_commands),
  constraint leaderboard_submission_outcome
    check (outcome in ('missedCommand', 'timeUp', 'completed')),
  constraint leaderboard_submission_daily_identity
    check (
      (mode = 'daily' and daily_date is not null and nullif(trim(daily_modifier_label), '') is not null)
      or
      (mode <> 'daily' and daily_date is null and daily_modifier_label is null)
    ),
  constraint leaderboard_submission_terminal_shape
    check (
      (mode = 'classic' and outcome = 'missedCommand' and misses = 3)
      or
      (mode = 'blitz' and outcome = 'timeUp')
      or
      (mode = 'endless' and outcome = 'missedCommand' and misses = 1)
      or
      (mode = 'sequence' and outcome = 'missedCommand' and misses = 3)
      or
      (mode = 'daily' and (
        (outcome = 'missedCommand' and misses = 1)
        or
        (outcome = 'completed' and misses = 0)
      ))
    ),
  constraint leaderboard_submission_not_far_future
    check (completed_at <= now() + interval '5 minutes'),
  unique (player_id, client_submission_id)
);

create index leaderboard_submissions_mode_score_idx
  on public.leaderboard_submissions (mode, score desc, average_reaction_seconds asc, completed_at asc);

create index leaderboard_submissions_daily_idx
  on public.leaderboard_submissions (daily_date, score desc, average_reaction_seconds asc, completed_at asc)
  where mode = 'daily';

alter table public.player_profiles enable row level security;
alter table public.leaderboard_submissions enable row level security;

revoke all on table public.player_profiles from anon, authenticated;
revoke all on table public.leaderboard_submissions from anon, authenticated;

grant select on table public.player_profiles to anon, authenticated;
grant update (display_name) on table public.player_profiles to authenticated;
grant select on table public.leaderboard_submissions to anon, authenticated;

create policy player_profiles_public_read
on public.player_profiles
for select
using (true);

create policy player_profiles_update_self
on public.player_profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy leaderboard_submissions_public_read
on public.leaderboard_submissions
for select
using (true);

create or replace function public.submit_leaderboard_score(
  p_client_submission_id text,
  p_schema_version smallint,
  p_mode text,
  p_score integer,
  p_successful_commands integer,
  p_average_reaction_seconds double precision,
  p_misses integer,
  p_max_streak integer,
  p_outcome text,
  p_completed_at timestamptz,
  p_daily_date date default null,
  p_daily_modifier_label text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_id uuid;
begin
  if v_player_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.player_profiles (id, display_name)
  values (
    v_player_id,
    'PLAYER-' || upper(substr(replace(v_player_id::text, '-', ''), 1, 6))
  )
  on conflict (id) do nothing;

  insert into public.leaderboard_submissions (
    player_id,
    client_submission_id,
    schema_version,
    mode,
    score,
    successful_commands,
    average_reaction_seconds,
    misses,
    max_streak,
    outcome,
    completed_at,
    daily_date,
    daily_modifier_label
  ) values (
    v_player_id,
    p_client_submission_id,
    p_schema_version,
    p_mode,
    p_score,
    p_successful_commands,
    p_average_reaction_seconds,
    p_misses,
    p_max_streak,
    p_outcome,
    p_completed_at,
    p_daily_date,
    p_daily_modifier_label
  )
  on conflict (player_id, client_submission_id)
  do update set client_submission_id = excluded.client_submission_id
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.submit_leaderboard_score(
  text, smallint, text, integer, integer, double precision, integer, integer, text, timestamptz, date, text
) from public, anon;

grant execute on function public.submit_leaderboard_score(
  text, smallint, text, integer, integer, double precision, integer, integer, text, timestamptz, date, text
) to authenticated;

create view public.leaderboard_global_best
with (security_invoker = true)
as
select distinct on (s.player_id, s.mode)
  s.player_id,
  p.display_name,
  s.mode,
  s.score,
  s.successful_commands,
  s.average_reaction_seconds,
  s.misses,
  s.max_streak,
  s.completed_at
from public.leaderboard_submissions s
join public.player_profiles p on p.id = s.player_id
where s.mode in ('classic', 'blitz', 'endless', 'sequence')
order by
  s.player_id,
  s.mode,
  s.score desc,
  s.average_reaction_seconds asc,
  s.completed_at asc;

create view public.leaderboard_daily_best
with (security_invoker = true)
as
select distinct on (s.player_id, s.daily_date)
  s.player_id,
  p.display_name,
  s.daily_date,
  s.daily_modifier_label,
  s.score,
  s.successful_commands,
  s.average_reaction_seconds,
  s.misses,
  s.max_streak,
  s.completed_at
from public.leaderboard_submissions s
join public.player_profiles p on p.id = s.player_id
where s.mode = 'daily'
order by
  s.player_id,
  s.daily_date,
  s.score desc,
  s.average_reaction_seconds asc,
  s.completed_at asc;

grant select on public.leaderboard_global_best to anon, authenticated;
grant select on public.leaderboard_daily_best to anon, authenticated;
