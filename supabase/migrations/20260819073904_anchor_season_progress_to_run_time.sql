create or replace function react_private.mission_period_key_at(
  p_cadence text,
  p_starts_at timestamptz,
  p_season_code text,
  p_at timestamptz
)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select case p_cadence
    when 'daily' then to_char((p_at at time zone 'utc')::date, 'YYYY-MM-DD')
    when 'weekly' then 'W' || greatest(
      1,
      1 + floor(extract(epoch from (p_at - p_starts_at)) / 604800)::integer
    )::text
    else p_season_code
  end;
$$;

create or replace function react_private.advance_missions_at(
  p_player_id uuid,
  p_season_id uuid,
  p_metric text,
  p_amount integer,
  p_at timestamptz
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
    v_period_key := react_private.mission_period_key_at(
      v_mission.cadence,
      v_season.starts_at,
      v_season.code,
      p_at
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

drop function if exists public.record_react_season_run(text, integer, integer, boolean, boolean);

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
  v_player uuid := auth.uid();
  v_season uuid;
  v_play_date date;
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

  v_play_date := (p_completed_at at time zone 'utc')::date;

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
  set first_play_date = v_play_date,
      updated_at = now()
  where player_id = v_player
    and season_id = v_season
    and first_play_date is distinct from v_play_date;
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

  perform react_private.advance_missions_at(v_player, v_season, 'runs', 1, p_completed_at);
  perform react_private.advance_missions_at(
    v_player,
    v_season,
    'commands',
    greatest(0, least(coalesce(p_successful_commands, 0), 10000)),
    p_completed_at
  );
  perform react_private.advance_missions_at(
    v_player,
    v_season,
    'score_total',
    greatest(0, least(coalesce(p_score, 0), 100000)),
    p_completed_at
  );

  if coalesce(p_is_personal_best, false) then
    perform react_private.advance_missions_at(
      v_player,
      v_season,
      'personal_bests',
      1,
      p_completed_at
    );
  end if;
  if coalesce(p_is_daily, false) then
    perform react_private.advance_missions_at(
      v_player,
      v_season,
      'daily_runs',
      1,
      p_completed_at
    );
  end if;

  perform react_private.claim_reached_rewards(v_player, v_season);
  return react_private.season_snapshot(v_player, v_season);
end;
$$;

revoke all on function react_private.mission_period_key_at(text, timestamptz, text, timestamptz) from public, anon, authenticated;
revoke all on function react_private.advance_missions_at(uuid, uuid, text, integer, timestamptz) from public, anon, authenticated;
revoke all on function public.record_react_season_run(text, integer, integer, boolean, boolean, timestamptz) from public, anon, authenticated;
grant execute on function public.record_react_season_run(text, integer, integer, boolean, boolean, timestamptz) to authenticated;
