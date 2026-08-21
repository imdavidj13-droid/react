create or replace function public.record_react_season_run(
  p_event_id text,
  p_mode text,
  p_score integer,
  p_successful_commands integer,
  p_is_personal_best boolean,
  p_daily_modifier text,
  p_completed_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player uuid := auth.uid();
  v_season uuid;
  v_play_date date;
  v_score integer := greatest(0, least(coalesce(p_score, 0), 100000));
  v_commands integer := greatest(0, least(coalesce(p_successful_commands, 0), 10000));
  v_runs_today integer := 0;
  v_base_charge integer := 0;
  v_new_event boolean := false;
  v_first_play boolean := false;
  v_daily_credit boolean := false;
  v_pb_credit boolean := false;
  v_pb_scope text;
  v_prior_best integer := -1;
  v_charge_before integer := 0;
  v_charge_after integer := 0;
  v_charge_earned integer := 0;
  v_daily_modifier text := upper(trim(coalesce(p_daily_modifier, '')));
begin
  if v_player is null then
    raise exception 'authentication_required';
  end if;
  if p_event_id is null or length(trim(p_event_id)) < 8 then
    raise exception 'invalid_event_id';
  end if;
  if p_mode is null or p_mode not in ('classic','blitz','endless','daily','passIt','sequence') then
    raise exception 'invalid_mode';
  end if;
  if p_completed_at is null
      or p_completed_at > now() + interval '5 minutes'
      or p_completed_at < now() - interval '30 days' then
    raise exception 'invalid_completed_at';
  end if;

  select id into v_season
  from public.react_seasons
  where p_completed_at >= starts_at
    and p_completed_at < ends_at
  order by starts_at desc
  limit 1;

  if v_season is null then
    return null;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(v_player::text || ':' || v_season::text, 0)
  );

  v_play_date := (p_completed_at at time zone 'utc')::date;

  if p_mode = 'daily' and v_daily_modifier in (
    'LIGHTS OUT','SURGE','NO CLOCK','ECHO','REVERSE','CHAIN','REDLINE'
  ) then
    v_pb_scope := 'daily:' || v_daily_modifier;
  else
    v_pb_scope := p_mode;
  end if;

  select count(*)::integer into v_runs_today
  from public.react_season_events e
  where e.player_id = v_player
    and e.season_id = v_season
    and e.completed_at is not null
    and (e.completed_at at time zone 'utc')::date = v_play_date;

  if v_runs_today < 10 then
    v_base_charge := 10;
  elsif v_runs_today < 20 then
    v_base_charge := 5;
  else
    v_base_charge := 0;
  end if;

  select coalesce(max(e.score), -1) into v_prior_best
  from public.react_season_events e
  where e.player_id = v_player
    and e.season_id = v_season
    and e.pb_scope = v_pb_scope;

  v_pb_credit := coalesce(p_is_personal_best, false)
    and v_score > 0
    and v_score > v_prior_best
    and not exists (
      select 1
      from public.react_season_events e
      where e.player_id = v_player
        and e.season_id = v_season
        and e.pb_scope = v_pb_scope
        and e.personal_best_credit_awarded
        and e.completed_at is not null
        and (e.completed_at at time zone 'utc')::date = v_play_date
    );

  v_first_play := v_runs_today = 0;

  if p_mode = 'daily' then
    select not exists (
      select 1
      from public.react_season_events e
      where e.player_id = v_player
        and e.season_id = v_season
        and e.mode = 'daily'
        and e.completed_at is not null
        and (e.completed_at at time zone 'utc')::date = v_play_date
    ) into v_daily_credit;
  end if;

  insert into public.react_season_progress (player_id, season_id)
  values (v_player, v_season)
  on conflict (player_id, season_id) do nothing;

  insert into public.react_season_events (
    player_id,
    season_id,
    event_id,
    charge_earned,
    mode,
    score,
    successful_commands,
    pb_scope,
    completed_at,
    personal_best_credit_awarded,
    daily_credit_awarded
  ) values (
    v_player,
    v_season,
    trim(p_event_id),
    0,
    p_mode,
    v_score,
    v_commands,
    v_pb_scope,
    p_completed_at,
    v_pb_credit,
    v_daily_credit
  )
  on conflict (player_id, season_id, event_id) do nothing;
  v_new_event := found;

  if not v_new_event then
    select charge_earned into v_charge_earned
    from public.react_season_events
    where player_id = v_player
      and season_id = v_season
      and event_id = trim(p_event_id);

    return react_private.season_snapshot(v_player, v_season)
      || jsonb_build_object('charge_earned', coalesce(v_charge_earned, 0));
  end if;

  select charge into v_charge_before
  from public.react_season_progress
  where player_id = v_player and season_id = v_season;

  update public.react_season_progress
  set first_play_date = greatest(coalesce(first_play_date, v_play_date), v_play_date),
      updated_at = now()
  where player_id = v_player and season_id = v_season;

  if v_pb_credit then
    v_base_charge := v_base_charge + 25;
  end if;
  if v_daily_credit then
    v_base_charge := v_base_charge + 40;
  end if;
  if v_first_play then
    v_base_charge := v_base_charge + 25;
  end if;

  update public.react_season_progress
  set charge = charge + v_base_charge,
      updated_at = now()
  where player_id = v_player and season_id = v_season;

  perform react_private.advance_missions_at(v_player, v_season, 'runs', 1, p_completed_at);
  perform react_private.advance_missions_at(v_player, v_season, 'commands', v_commands, p_completed_at);
  perform react_private.advance_missions_at(v_player, v_season, 'score_total', v_score, p_completed_at);

  if v_pb_credit then
    perform react_private.advance_missions_at(
      v_player, v_season, 'personal_bests', 1, p_completed_at
    );
  end if;
  if v_daily_credit then
    perform react_private.advance_missions_at(
      v_player, v_season, 'daily_runs', 1, p_completed_at
    );
  end if;

  perform react_private.claim_reached_rewards(v_player, v_season);

  select charge into v_charge_after
  from public.react_season_progress
  where player_id = v_player and season_id = v_season;

  v_charge_earned := greatest(0, v_charge_after - v_charge_before);

  update public.react_season_events
  set charge_earned = v_charge_earned
  where player_id = v_player
    and season_id = v_season
    and event_id = trim(p_event_id);

  return react_private.season_snapshot(v_player, v_season)
    || jsonb_build_object('charge_earned', v_charge_earned);
end;
$$;

-- Keep already-installed/debug builds compatible while the client rolls onto
-- the hardened mode-aware contract. Legacy event IDs already encode the mode.
create or replace function public.record_react_season_run(
  p_event_id text,
  p_score integer,
  p_successful_commands integer,
  p_is_personal_best boolean,
  p_is_daily boolean,
  p_completed_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mode text;
begin
  if coalesce(p_is_daily, false) then
    v_mode := 'daily';
  else
    v_mode := substring(
      trim(p_event_id)
      from '^season-(classic|blitz|endless|passIt|sequence)-'
    );
  end if;

  if v_mode is null then
    raise exception 'invalid_legacy_event_mode';
  end if;

  return public.record_react_season_run(
    p_event_id,
    v_mode,
    p_score,
    p_successful_commands,
    p_is_personal_best,
    null,
    p_completed_at
  );
end;
$$;

revoke all on function public.record_react_season_run(
  text, integer, integer, boolean, boolean, timestamptz
) from public, anon;
grant execute on function public.record_react_season_run(
  text, integer, integer, boolean, boolean, timestamptz
) to authenticated, service_role;

-- Season 01 economy: progression should reward regular engagement rather than
-- brute-force run volume. Existing earned CHARGE is intentionally untouched.
update public.react_season_missions m
set charge_reward = case m.name
  when 'WARM UP' then 20
  when 'FAST HANDS' then 30
  when 'DAILY SIGNAL' then 40
  when 'KEEP MOVING' then 125
  when 'HIGH OUTPUT' then 150
  when 'BREAK YOUR LIMIT' then 175
  when 'OVERDRIVE REGULAR' then 300
  when 'FULL CURRENT' then 400
  when 'DAILY DISCIPLINE' then 350
  when 'TOTAL OUTPUT' then 300
  else m.charge_reward
end
where m.season_id = (
  select id
  from public.react_seasons
  where code = 'S01_OVERDRIVE'
  limit 1
);