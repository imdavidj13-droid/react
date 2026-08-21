create or replace function public.get_react_owned_cosmetics()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_player uuid := auth.uid();
  v_result jsonb;
begin
  if v_player is null then
    return '[]'::jsonb;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'season_id', s.id,
        'season_code', s.code,
        'season_name', s.name,
        'tier', t.tier_number,
        'track', r.track,
        'kind', r.reward_kind,
        'reward_key', r.reward_key,
        'name', r.name,
        'description', r.description,
        'milestone', r.milestone,
        'payload', r.payload,
        'unlocked_at', u.unlocked_at
      )
      order by u.unlocked_at desc, t.tier_number desc
    ),
    '[]'::jsonb
  )
  into v_result
  from public.react_player_unlocks u
  join public.react_season_rewards r on r.id = u.reward_id
  join public.react_season_tiers t on t.id = r.tier_id
  join public.react_seasons s on s.id = u.season_id
  where u.player_id = v_player;

  return v_result;
end;
$$;

revoke all on function public.get_react_owned_cosmetics() from public;
revoke all on function public.get_react_owned_cosmetics() from anon;
grant execute on function public.get_react_owned_cosmetics() to authenticated;
