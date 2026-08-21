-- Rebalance only later S01 rewards that had no unlocks when this feature was
-- prepared. The NOT EXISTS guard is intentional: if a player earns one of
-- these exact rows before this migration reaches an environment, their earned
-- cosmetic is preserved rather than silently changing identity.
with replacements(
  tier_number,
  track,
  reward_kind,
  reward_key,
  name,
  description,
  payload
) as (
  values
    (10, 'free', 'arena_theme', 'arena_ion_trace', 'ION TRACE ARENA',
      'Thin ion arena treatment for the central circle, ring and timer track only.',
      '{"family":"arena","variant":"ion_trace"}'::jsonb),
    (11, 'free', 'particle_pack', 'particle_ion_drift', 'ION DRIFT',
      'Slow ion particle drift behind Classic, Blitz, Endless, Daily and Pass It runs.',
      '{"family":"particles","variant":"ion_drift"}'::jsonb),
    (17, 'free', 'input_reaction_pack', 'reaction_pulse', 'PULSE REACTION',
      'Soft multi-ring input feedback with reduced burst density in gesture-based runs.',
      '{"family":"reaction","variant":"pulse"}'::jsonb),
    (20, 'free', 'hud_style', 'hud_pressure_rail', 'PRESSURE HUD',
      'Angular rail-style gameplay HUD cards. Does not change the arena or gameplay rules.',
      '{"family":"hud","variant":"pressure_rail"}'::jsonb),
    (21, 'free', 'particle_pack', 'particle_voltage_storm', 'VOLTAGE STORM',
      'Dense fast-moving particle storm behind Classic, Blitz, Endless, Daily and Pass It runs.',
      '{"family":"particles","variant":"voltage_storm"}'::jsonb),
    (22, 'free', 'arena_theme', 'arena_reactor_heavy', 'REACTOR ARENA',
      'Heavy reactor-style central arena and timer-ring treatment only.',
      '{"family":"arena","variant":"reactor_heavy"}'::jsonb),
    (26, 'free', 'input_reaction_pack', 'reaction_shock', 'REFLEX SHOCK',
      'Sharp dual-shockwave success and miss feedback in gesture-based runs.',
      '{"family":"reaction","variant":"shock"}'::jsonb),
    (28, 'free', 'particle_pack', 'particle_neon_dust', 'NEON DUST',
      'Sparse bright neon dust drifting behind Classic, Blitz, Endless, Daily and Pass It runs.',
      '{"family":"particles","variant":"neon_dust"}'::jsonb),
    (29, 'free', 'hud_style', 'hud_limit_neon', 'LIMIT BREAK HUD',
      'Neon gameplay HUD card treatment without changing arena colours, timing or rules.',
      '{"family":"hud","variant":"limit_neon"}'::jsonb)
), target as (
  select
    r.id as reward_id,
    x.reward_kind,
    x.reward_key,
    x.name,
    x.description,
    x.payload
  from public.react_season_rewards r
  join public.react_season_tiers t on t.id = r.tier_id
  join public.react_seasons s on s.id = r.season_id
  join replacements x
    on x.tier_number = t.tier_number
   and x.track = r.track
  where s.code = 'S01_OVERDRIVE'
    and not exists (
      select 1
      from public.react_player_unlocks u
      where u.reward_id = r.id
    )
)
update public.react_season_rewards r
set reward_kind = target.reward_kind,
    reward_key = target.reward_key,
    name = target.name,
    description = target.description,
    payload = coalesce(r.payload, '{}'::jsonb) || target.payload
from target
where r.id = target.reward_id;
