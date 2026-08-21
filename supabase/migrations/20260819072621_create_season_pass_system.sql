create schema if not exists react_private;
revoke all on schema react_private from public, anon, authenticated;

create table if not exists public.react_seasons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  subtitle text not null default '',
  theme_key text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  premium_sku text,
  created_at timestamptz not null default now(),
  check (ends_at = starts_at + interval '21 days')
);

create table if not exists public.react_season_tiers (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.react_seasons(id) on delete cascade,
  tier_number integer not null check (tier_number between 1 and 30),
  charge_required integer not null check (charge_required >= 0),
  milestone boolean not null default false,
  unique (season_id, tier_number),
  unique (season_id, charge_required)
);

create table if not exists public.react_season_rewards (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.react_seasons(id) on delete cascade,
  tier_id uuid not null references public.react_season_tiers(id) on delete cascade,
  track text not null check (track in ('free', 'premium')),
  reward_kind text not null check (reward_kind in (
    'reaction_pack',
    'command_style',
    'countdown_style',
    'sound_pack',
    'share_style',
    'profile_frame',
    'profile_badge',
    'player_code_style',
    'home_theme',
    'score_effect',
    'success_effect',
    'failure_effect',
    'mode_card_skin',
    'title',
    'emblem'
  )),
  reward_key text not null,
  name text not null,
  description text not null default '',
  payload jsonb not null default '{}'::jsonb,
  milestone boolean not null default false,
  sort_order integer not null default 0,
  unique (season_id, reward_key)
);

create table if not exists public.react_season_progress (
  player_id uuid not null references public.player_profiles(id) on delete cascade,
  season_id uuid not null references public.react_seasons(id) on delete cascade,
  charge integer not null default 0 check (charge >= 0),
  premium_owned boolean not null default false,
  premium_granted_at timestamptz,
  first_play_date date,
  updated_at timestamptz not null default now(),
  primary key (player_id, season_id)
);

create table if not exists public.react_season_missions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.react_seasons(id) on delete cascade,
  cadence text not null check (cadence in ('daily', 'weekly', 'season')),
  metric text not null check (metric in (
    'runs',
    'personal_bests',
    'daily_runs',
    'commands',
    'score_total'
  )),
  name text not null,
  description text not null default '',
  target integer not null check (target > 0),
  charge_reward integer not null check (charge_reward > 0),
  sort_order integer not null default 0,
  active boolean not null default true
);

create table if not exists public.react_season_mission_progress (
  player_id uuid not null references public.player_profiles(id) on delete cascade,
  mission_id uuid not null references public.react_season_missions(id) on delete cascade,
  period_key text not null,
  progress integer not null default 0 check (progress >= 0),
  completed_at timestamptz,
  rewarded_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (player_id, mission_id, period_key)
);

create table if not exists public.react_player_unlocks (
  player_id uuid not null references public.player_profiles(id) on delete cascade,
  reward_id uuid not null references public.react_season_rewards(id) on delete cascade,
  season_id uuid not null references public.react_seasons(id) on delete cascade,
  reward_key text not null,
  reward_kind text not null,
  unlocked_at timestamptz not null default now(),
  primary key (player_id, reward_id)
);

create table if not exists public.react_season_events (
  player_id uuid not null references public.player_profiles(id) on delete cascade,
  season_id uuid not null references public.react_seasons(id) on delete cascade,
  event_id text not null,
  created_at timestamptz not null default now(),
  primary key (player_id, season_id, event_id)
);

create index if not exists react_seasons_window_idx
  on public.react_seasons (starts_at desc, ends_at);
create index if not exists react_season_rewards_tier_idx
  on public.react_season_rewards (tier_id, track, sort_order);
create index if not exists react_season_missions_season_idx
  on public.react_season_missions (season_id, cadence, sort_order);
create index if not exists react_player_unlocks_player_idx
  on public.react_player_unlocks (player_id, season_id);

alter table public.react_seasons enable row level security;
alter table public.react_season_tiers enable row level security;
alter table public.react_season_rewards enable row level security;
alter table public.react_season_progress enable row level security;
alter table public.react_season_missions enable row level security;
alter table public.react_season_mission_progress enable row level security;
alter table public.react_player_unlocks enable row level security;
alter table public.react_season_events enable row level security;

revoke all on table public.react_seasons from public, anon, authenticated;
revoke all on table public.react_season_tiers from public, anon, authenticated;
revoke all on table public.react_season_rewards from public, anon, authenticated;
revoke all on table public.react_season_progress from public, anon, authenticated;
revoke all on table public.react_season_missions from public, anon, authenticated;
revoke all on table public.react_season_mission_progress from public, anon, authenticated;
revoke all on table public.react_player_unlocks from public, anon, authenticated;
revoke all on table public.react_season_events from public, anon, authenticated;

grant select on table public.react_seasons to authenticated;
grant select on table public.react_season_tiers to authenticated;
grant select on table public.react_season_rewards to authenticated;
grant select on table public.react_season_missions to authenticated;
grant select on table public.react_season_progress to authenticated;
grant select on table public.react_season_mission_progress to authenticated;
grant select on table public.react_player_unlocks to authenticated;

drop policy if exists react_seasons_read_active on public.react_seasons;
create policy react_seasons_read_active
on public.react_seasons
for select
to authenticated
using (now() >= starts_at and now() < ends_at);

drop policy if exists react_season_tiers_read_active on public.react_season_tiers;
create policy react_season_tiers_read_active
on public.react_season_tiers
for select
to authenticated
using (
  exists (
    select 1 from public.react_seasons s
    where s.id = season_id
      and now() >= s.starts_at
      and now() < s.ends_at
  )
);

drop policy if exists react_season_rewards_read_active on public.react_season_rewards;
create policy react_season_rewards_read_active
on public.react_season_rewards
for select
to authenticated
using (
  exists (
    select 1 from public.react_seasons s
    where s.id = season_id
      and now() >= s.starts_at
      and now() < s.ends_at
  )
);

drop policy if exists react_season_missions_read_active on public.react_season_missions;
create policy react_season_missions_read_active
on public.react_season_missions
for select
to authenticated
using (
  active and exists (
    select 1 from public.react_seasons s
    where s.id = season_id
      and now() >= s.starts_at
      and now() < s.ends_at
  )
);

drop policy if exists react_season_progress_select_own on public.react_season_progress;
create policy react_season_progress_select_own
on public.react_season_progress
for select
to authenticated
using (player_id = (select auth.uid()));

drop policy if exists react_season_mission_progress_select_own on public.react_season_mission_progress;
create policy react_season_mission_progress_select_own
on public.react_season_mission_progress
for select
to authenticated
using (player_id = (select auth.uid()));

drop policy if exists react_player_unlocks_select_own on public.react_player_unlocks;
create policy react_player_unlocks_select_own
on public.react_player_unlocks
for select
to authenticated
using (player_id = (select auth.uid()));

create or replace function react_private.active_season_id()
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select id
  from public.react_seasons
  where now() >= starts_at and now() < ends_at
  order by starts_at desc
  limit 1;
$$;

create or replace function react_private.mission_period_key(
  p_cadence text,
  p_starts_at timestamptz,
  p_season_code text
)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select case p_cadence
    when 'daily' then to_char((now() at time zone 'utc')::date, 'YYYY-MM-DD')
    when 'weekly' then 'W' || (
      1 + floor(extract(epoch from (now() - p_starts_at)) / 604800)::integer
    )::text
    else p_season_code
  end;
$$;

create or replace function react_private.claim_reached_rewards(
  p_player_id uuid,
  p_season_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_charge integer;
  v_premium boolean;
begin
  select charge, premium_owned
  into v_charge, v_premium
  from public.react_season_progress
  where player_id = p_player_id and season_id = p_season_id;

  if not found then
    return;
  end if;

  insert into public.react_player_unlocks (
    player_id,
    reward_id,
    season_id,
    reward_key,
    reward_kind
  )
  select
    p_player_id,
    r.id,
    r.season_id,
    r.reward_key,
    r.reward_kind
  from public.react_season_rewards r
  join public.react_season_tiers t on t.id = r.tier_id
  where r.season_id = p_season_id
    and t.charge_required <= v_charge
    and (r.track = 'free' or v_premium)
  on conflict (player_id, reward_id) do nothing;
end;
$$;

create or replace function react_private.advance_missions(
  p_player_id uuid,
  p_season_id uuid,
  p_metric text,
  p_amount integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_season public.react_seasons%rowtype;
  v_mission public.react_season_missions%rowtype;
  v_period_key text;
  v_progress integer;
  v_rewarded_at timestamptz;
begin
  if p_amount <= 0 then
    return;
  end if;

  select * into v_season
  from public.react_seasons
  where id = p_season_id;

  for v_mission in
    select *
    from public.react_season_missions
    where season_id = p_season_id
      and active
      and metric = p_metric
    order by sort_order, id
  loop
    v_period_key := react_private.mission_period_key(
      v_mission.cadence,
      v_season.starts_at,
      v_season.code
    );

    insert into public.react_season_mission_progress (
      player_id,
      mission_id,
      period_key,
      progress,
      updated_at
    ) values (
      p_player_id,
      v_mission.id,
      v_period_key,
      least(p_amount, v_mission.target),
      now()
    )
    on conflict (player_id, mission_id, period_key) do update
    set progress = least(
          v_mission.target,
          public.react_season_mission_progress.progress + excluded.progress
        ),
        updated_at = now()
    returning progress, rewarded_at into v_progress, v_rewarded_at;

    if v_progress >= v_mission.target and v_rewarded_at is null then
      update public.react_season_mission_progress
      set completed_at = coalesce(completed_at, now()),
          rewarded_at = now(),
          updated_at = now()
      where player_id = p_player_id
        and mission_id = v_mission.id
        and period_key = v_period_key
        and rewarded_at is null;

      if found then
        update public.react_season_progress
        set charge = charge + v_mission.charge_reward,
            updated_at = now()
        where player_id = p_player_id and season_id = p_season_id;
      end if;
    end if;
  end loop;
end;
$$;

create or replace function react_private.season_snapshot(
  p_player_id uuid,
  p_season_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_season public.react_seasons%rowtype;
  v_progress public.react_season_progress%rowtype;
  v_result jsonb;
begin
  select * into v_season
  from public.react_seasons
  where id = p_season_id;

  if not found then
    return null;
  end if;

  insert into public.react_season_progress (player_id, season_id)
  values (p_player_id, p_season_id)
  on conflict (player_id, season_id) do nothing;

  perform react_private.claim_reached_rewards(p_player_id, p_season_id);

  select * into v_progress
  from public.react_season_progress
  where player_id = p_player_id and season_id = p_season_id;

  select jsonb_build_object(
    'id', v_season.id,
    'code', v_season.code,
    'name', v_season.name,
    'subtitle', v_season.subtitle,
    'theme_key', v_season.theme_key,
    'starts_at', v_season.starts_at,
    'ends_at', v_season.ends_at,
    'charge', v_progress.charge,
    'premium_owned', v_progress.premium_owned,
    'tiers', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'number', t.tier_number,
          'charge_required', t.charge_required,
          'milestone', t.milestone,
          'rewards', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'id', r.id,
                'tier', t.tier_number,
                'track', r.track,
                'kind', r.reward_kind,
                'reward_key', r.reward_key,
                'name', r.name,
                'description', r.description,
                'payload', r.payload,
                'milestone', r.milestone
              ) order by r.track, r.sort_order, r.id
            )
            from public.react_season_rewards r
            where r.tier_id = t.id
          ), '[]'::jsonb)
        ) order by t.tier_number
      )
      from public.react_season_tiers t
      where t.season_id = v_season.id
    ), '[]'::jsonb),
    'missions', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', m.id,
          'cadence', m.cadence,
          'metric', m.metric,
          'name', m.name,
          'description', m.description,
          'target', m.target,
          'charge_reward', m.charge_reward,
          'period_key', react_private.mission_period_key(
            m.cadence,
            v_season.starts_at,
            v_season.code
          ),
          'progress', coalesce(mp.progress, 0),
          'completed', mp.rewarded_at is not null
        ) order by
          case m.cadence when 'daily' then 0 when 'weekly' then 1 else 2 end,
          m.sort_order,
          m.id
      )
      from public.react_season_missions m
      left join public.react_season_mission_progress mp
        on mp.player_id = p_player_id
       and mp.mission_id = m.id
       and mp.period_key = react_private.mission_period_key(
         m.cadence,
         v_season.starts_at,
         v_season.code
       )
      where m.season_id = v_season.id and m.active
    ), '[]'::jsonb),
    'unlocked_reward_keys', coalesce((
      select jsonb_agg(u.reward_key order by u.unlocked_at, u.reward_key)
      from public.react_player_unlocks u
      where u.player_id = p_player_id and u.season_id = v_season.id
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

create or replace function public.get_react_active_season()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player uuid := auth.uid();
  v_season uuid;
begin
  if v_player is null then
    raise exception 'authentication_required';
  end if;

  v_season := react_private.active_season_id();
  if v_season is null then
    return null;
  end if;

  return react_private.season_snapshot(v_player, v_season);
end;
$$;

create or replace function public.record_react_season_run(
  p_event_id text,
  p_score integer,
  p_successful_commands integer,
  p_is_personal_best boolean,
  p_is_daily boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player uuid := auth.uid();
  v_season uuid;
  v_today date := (now() at time zone 'utc')::date;
  v_base_charge integer := 25;
  v_new_event boolean := false;
  v_first_play boolean := false;
begin
  if v_player is null then
    raise exception 'authentication_required';
  end if;
  if p_event_id is null or length(trim(p_event_id)) < 8 then
    raise exception 'invalid_event_id';
  end if;

  v_season := react_private.active_season_id();
  if v_season is null then
    return null;
  end if;

  insert into public.react_season_progress (player_id, season_id)
  values (v_player, v_season)
  on conflict (player_id, season_id) do nothing;

  insert into public.react_season_events (player_id, season_id, event_id)
  values (v_player, v_season, trim(p_event_id))
  on conflict (player_id, season_id, event_id) do nothing;
  v_new_event := found;

  if not v_new_event then
    return react_private.season_snapshot(v_player, v_season);
  end if;

  update public.react_season_progress
  set first_play_date = v_today,
      updated_at = now()
  where player_id = v_player
    and season_id = v_season
    and first_play_date is distinct from v_today;
  v_first_play := found;

  if coalesce(p_is_personal_best, false) then
    v_base_charge := v_base_charge + 75;
  end if;
  if coalesce(p_is_daily, false) then
    v_base_charge := v_base_charge + 100;
  end if;
  if v_first_play then
    v_base_charge := v_base_charge + 50;
  end if;

  update public.react_season_progress
  set charge = charge + v_base_charge,
      updated_at = now()
  where player_id = v_player and season_id = v_season;

  perform react_private.advance_missions(v_player, v_season, 'runs', 1);
  perform react_private.advance_missions(
    v_player,
    v_season,
    'commands',
    greatest(0, least(coalesce(p_successful_commands, 0), 10000))
  );
  perform react_private.advance_missions(
    v_player,
    v_season,
    'score_total',
    greatest(0, least(coalesce(p_score, 0), 100000))
  );

  if coalesce(p_is_personal_best, false) then
    perform react_private.advance_missions(v_player, v_season, 'personal_bests', 1);
  end if;
  if coalesce(p_is_daily, false) then
    perform react_private.advance_missions(v_player, v_season, 'daily_runs', 1);
  end if;

  perform react_private.claim_reached_rewards(v_player, v_season);
  return react_private.season_snapshot(v_player, v_season);
end;
$$;

create or replace function public.set_react_season_premium_entitlement(
  p_player_id uuid,
  p_season_id uuid,
  p_owned boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.react_season_progress (
    player_id,
    season_id,
    premium_owned,
    premium_granted_at
  ) values (
    p_player_id,
    p_season_id,
    p_owned,
    case when p_owned then now() else null end
  )
  on conflict (player_id, season_id) do update
  set premium_owned = excluded.premium_owned,
      premium_granted_at = case
        when excluded.premium_owned then coalesce(
          public.react_season_progress.premium_granted_at,
          now()
        )
        else null
      end,
      updated_at = now();

  if p_owned then
    perform react_private.claim_reached_rewards(p_player_id, p_season_id);
  end if;
end;
$$;

revoke all on function react_private.active_season_id() from public, anon, authenticated;
revoke all on function react_private.mission_period_key(text, timestamptz, text) from public, anon, authenticated;
revoke all on function react_private.claim_reached_rewards(uuid, uuid) from public, anon, authenticated;
revoke all on function react_private.advance_missions(uuid, uuid, text, integer) from public, anon, authenticated;
revoke all on function react_private.season_snapshot(uuid, uuid) from public, anon, authenticated;

revoke all on function public.get_react_active_season() from public, anon, authenticated;
revoke all on function public.record_react_season_run(text, integer, integer, boolean, boolean) from public, anon, authenticated;
revoke all on function public.set_react_season_premium_entitlement(uuid, uuid, boolean) from public, anon, authenticated;

grant execute on function public.get_react_active_season() to authenticated;
grant execute on function public.record_react_season_run(text, integer, integer, boolean, boolean) to authenticated;
grant execute on function public.set_react_season_premium_entitlement(uuid, uuid, boolean) to service_role;

insert into public.react_seasons (
  code,
  name,
  subtitle,
  theme_key,
  starts_at,
  ends_at,
  premium_sku
) values (
  'S01_OVERDRIVE',
  'SEASON 01 — OVERDRIVE',
  'PUSH THE LIMIT',
  'overdrive',
  '2026-08-19 00:00:00+00'::timestamptz,
  '2026-09-09 00:00:00+00'::timestamptz,
  'react_season_01_premium'
)
on conflict (code) do update
set name = excluded.name,
    subtitle = excluded.subtitle,
    theme_key = excluded.theme_key,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    premium_sku = excluded.premium_sku;

with active as (
  select id from public.react_seasons where code = 'S01_OVERDRIVE'
)
insert into public.react_season_tiers (
  season_id,
  tier_number,
  charge_required,
  milestone
)
select
  active.id,
  n,
  (n - 1) * 200,
  n % 5 = 0
from active
cross join generate_series(1, 30) as n
on conflict (season_id, tier_number) do update
set charge_required = excluded.charge_required,
    milestone = excluded.milestone;

with reward_seed(tier_number, track, reward_kind, reward_key, name, description, milestone) as (
  values
    (1, 'free', 'title', 'title_quick_start', 'QUICK START', 'Season title', false),
    (1, 'premium', 'profile_badge', 'badge_overdrive_01', 'IGNITION BADGE', 'Overdrive profile badge', false),
    (2, 'free', 'emblem', 'emblem_charge_cell', 'CHARGE CELL', 'Player emblem', false),
    (2, 'premium', 'player_code_style', 'code_style_voltage_trace', 'VOLTAGE TRACE', 'Player-code styling', false),
    (3, 'free', 'reaction_pack', 'greenline', 'GREENLINE', 'Reaction colour pack', false),
    (3, 'premium', 'score_effect', 'score_effect_arc', 'ARC SCORE', 'Score burst effect', false),
    (4, 'free', 'profile_badge', 'badge_live_wire', 'LIVE WIRE', 'Profile badge', false),
    (4, 'premium', 'command_style', 'terminal_commands', 'TERMINAL COMMANDS', 'Command text style', false),
    (5, 'free', 'emblem', 'emblem_overdrive_mark', 'OVERDRIVE MARK', 'Milestone emblem', true),
    (5, 'premium', 'profile_frame', 'frame_overdrive_01', 'OVERDRIVE FRAME', 'Milestone profile frame', true),
    (6, 'free', 'countdown_style', 'rings_countdown', 'RINGS COUNTDOWN', 'Countdown style', false),
    (6, 'premium', 'success_effect', 'success_effect_surge', 'SURGE SUCCESS', 'Success effect', false),
    (7, 'free', 'title', 'title_high_voltage', 'HIGH VOLTAGE', 'Season title', false),
    (7, 'premium', 'home_theme', 'home_theme_overdrive_grid', 'OVERDRIVE GRID', 'Home theme', false),
    (8, 'free', 'player_code_style', 'code_style_blue_pulse', 'BLUE PULSE', 'Player-code styling', false),
    (8, 'premium', 'reaction_pack', 'hot_pink', 'HOT PINK', 'Reaction colour pack', false),
    (9, 'free', 'sound_pack', 'arcade_sfx', 'ARCADE SFX', 'Sound pack', false),
    (9, 'premium', 'failure_effect', 'failure_effect_shatter', 'SHATTER FAIL', 'Failure effect', false),
    (10, 'free', 'title', 'title_redline_ready', 'REDLINE READY', 'Milestone title', true),
    (10, 'premium', 'home_theme', 'home_theme_overdrive', 'OVERDRIVE HOME', 'Milestone home theme', true),
    (11, 'free', 'profile_badge', 'badge_reflex_core', 'REFLEX CORE', 'Profile badge', false),
    (11, 'premium', 'mode_card_skin', 'mode_skin_ion', 'ION MODE CARDS', 'Mode-card skin', false),
    (12, 'free', 'command_style', 'glitch_commands', 'GLITCH COMMANDS', 'Command text style', false),
    (12, 'premium', 'share_style', 'pro_share_cards', 'PRO SHARE CARDS', 'Share and result-card style', false),
    (13, 'free', 'emblem', 'emblem_split_second', 'SPLIT SECOND', 'Player emblem', false),
    (13, 'premium', 'countdown_style', 'terminal_countdown', 'TERMINAL COUNTDOWN', 'Countdown style', false),
    (14, 'free', 'score_effect', 'score_effect_streak', 'STREAK SPARK', 'Score effect', false),
    (14, 'premium', 'profile_frame', 'frame_ion_ring', 'ION RING', 'Profile frame', false),
    (15, 'free', 'reaction_pack', 'voltage', 'VOLTAGE', 'Milestone reaction colour pack', true),
    (15, 'premium', 'command_style', 'impact_commands', 'IMPACT COMMANDS', 'Milestone command text style', true),
    (16, 'free', 'success_effect', 'success_effect_flash', 'REFLEX FLASH', 'Success effect', false),
    (16, 'premium', 'title', 'title_overclocked', 'OVERCLOCKED', 'Season title', false),
    (17, 'free', 'profile_badge', 'badge_charge_17', 'CHARGE XVII', 'Profile badge', false),
    (17, 'premium', 'sound_pack', 'bass_sfx', 'BASS SFX', 'Sound pack', false),
    (18, 'free', 'mode_card_skin', 'mode_skin_gridline', 'GRIDLINE CARDS', 'Mode-card skin', false),
    (18, 'premium', 'player_code_style', 'code_style_overclock', 'OVERCLOCK CODE', 'Player-code styling', false),
    (19, 'free', 'failure_effect', 'failure_effect_red_arc', 'RED ARC FAIL', 'Failure effect', false),
    (19, 'premium', 'reaction_pack', 'redline', 'REDLINE', 'Reaction colour pack', false),
    (20, 'free', 'profile_badge', 'badge_pressure_20', 'PRESSURE XX', 'Milestone profile badge', true),
    (20, 'premium', 'countdown_style', 'pulse_countdown', 'PULSE COUNTDOWN', 'Milestone countdown style', true),
    (21, 'free', 'title', 'title_stay_charged', 'STAY CHARGED', 'Season title', false),
    (21, 'premium', 'score_effect', 'score_effect_overload', 'OVERLOAD SCORE', 'Score effect', false),
    (22, 'free', 'emblem', 'emblem_reactor', 'REACTOR', 'Player emblem', false),
    (22, 'premium', 'sound_pack', 'pulse_sfx', 'PULSE SFX', 'Sound pack', false),
    (23, 'free', 'player_code_style', 'code_style_23', 'CURRENT FLOW', 'Player-code styling', false),
    (23, 'premium', 'profile_frame', 'frame_current', 'CURRENT FRAME', 'Profile frame', false),
    (24, 'free', 'command_style', 'arcade_commands', 'ARCADE COMMANDS', 'Command text style', false),
    (24, 'premium', 'success_effect', 'success_effect_overdrive', 'OVERDRIVE SUCCESS', 'Success effect', false),
    (25, 'free', 'mode_card_skin', 'mode_skin_overdrive', 'OVERDRIVE MODE CARDS', 'Milestone mode-card skin', true),
    (25, 'premium', 'sound_pack', 'laser_sfx', 'LASER SFX', 'Milestone sound pack', true),
    (26, 'free', 'profile_badge', 'badge_reflex_26', 'REFLEX XXVI', 'Profile badge', false),
    (26, 'premium', 'home_theme', 'home_theme_neon_rail', 'NEON RAIL', 'Home theme', false),
    (27, 'free', 'countdown_style', 'cards_countdown', 'CARDS COUNTDOWN', 'Countdown style', false),
    (27, 'premium', 'failure_effect', 'failure_effect_blackout', 'BLACKOUT FAIL', 'Failure effect', false),
    (28, 'free', 'emblem', 'emblem_peak_signal', 'PEAK SIGNAL', 'Player emblem', false),
    (28, 'premium', 'reaction_pack', 'synthwave', 'SYNTHWAVE', 'Reaction colour pack', false),
    (29, 'free', 'title', 'title_limit_breaker', 'LIMIT BREAKER', 'Season title', false),
    (29, 'premium', 'share_style', 'share_style_overdrive', 'OVERDRIVE SHARE', 'Share and result-card style', false),
    (30, 'free', 'reaction_pack', 'ember', 'EMBER', 'Final milestone reaction colour pack', true),
    (30, 'premium', 'emblem', 'emblem_overdrive_elite', 'OVERDRIVE ELITE', 'Final milestone emblem', true)
), season as (
  select id from public.react_seasons where code = 'S01_OVERDRIVE'
)
insert into public.react_season_rewards (
  season_id,
  tier_id,
  track,
  reward_kind,
  reward_key,
  name,
  description,
  milestone
)
select
  season.id,
  tier.id,
  seed.track,
  seed.reward_kind,
  seed.reward_key,
  seed.name,
  seed.description,
  seed.milestone
from reward_seed seed
cross join season
join public.react_season_tiers tier
  on tier.season_id = season.id and tier.tier_number = seed.tier_number
on conflict (season_id, reward_key) do update
set tier_id = excluded.tier_id,
    track = excluded.track,
    reward_kind = excluded.reward_kind,
    name = excluded.name,
    description = excluded.description,
    milestone = excluded.milestone;

with mission_seed(cadence, metric, name, description, target, charge_reward, sort_order) as (
  values
    ('daily', 'runs', 'WARM UP', 'Complete 3 runs today', 3, 75, 1),
    ('daily', 'commands', 'FAST HANDS', 'Clear 40 commands today', 40, 100, 2),
    ('daily', 'daily_runs', 'DAILY SIGNAL', 'Complete today''s Daily', 1, 125, 3),
    ('weekly', 'runs', 'KEEP MOVING', 'Complete 15 runs this week', 15, 250, 1),
    ('weekly', 'commands', 'HIGH OUTPUT', 'Clear 300 commands this week', 300, 300, 2),
    ('weekly', 'personal_bests', 'BREAK YOUR LIMIT', 'Set 3 personal bests this week', 3, 350, 3),
    ('season', 'runs', 'OVERDRIVE REGULAR', 'Complete 50 runs this season', 50, 600, 1),
    ('season', 'commands', 'FULL CURRENT', 'Clear 1,200 commands this season', 1200, 800, 2),
    ('season', 'daily_runs', 'DAILY DISCIPLINE', 'Complete 14 Daily runs this season', 14, 700, 3),
    ('season', 'score_total', 'TOTAL OUTPUT', 'Score 5,000 points across the season', 5000, 500, 4)
), season as (
  select id from public.react_seasons where code = 'S01_OVERDRIVE'
)
insert into public.react_season_missions (
  season_id,
  cadence,
  metric,
  name,
  description,
  target,
  charge_reward,
  sort_order
)
select
  season.id,
  seed.cadence,
  seed.metric,
  seed.name,
  seed.description,
  seed.target,
  seed.charge_reward,
  seed.sort_order
from mission_seed seed
cross join season
where not exists (
  select 1
  from public.react_season_missions existing
  where existing.season_id = season.id
    and existing.cadence = seed.cadence
    and existing.metric = seed.metric
    and existing.name = seed.name
);
