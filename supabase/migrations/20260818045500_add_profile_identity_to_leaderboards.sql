drop view if exists public.leaderboard_global_best;
drop view if exists public.leaderboard_daily_best;

create view public.leaderboard_global_best
with (security_invoker = true)
as
select distinct on (s.player_id, s.mode)
  s.player_id,
  p.display_name,
  p.player_code,
  p.avatar_path,
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
  p.player_code,
  p.avatar_path,
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
