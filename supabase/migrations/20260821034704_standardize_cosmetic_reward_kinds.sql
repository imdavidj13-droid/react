alter table public.react_season_rewards
  drop constraint react_season_rewards_reward_kind_check;

alter table public.react_season_rewards
  add constraint react_season_rewards_reward_kind_check
  check (reward_kind = any (array[
    -- Legacy S01 aliases retained for installed-client compatibility.
    'reaction_pack'::text,
    'command_style'::text,
    'share_style'::text,
    'home_theme'::text,
    'success_effect'::text,
    'failure_effect'::text,
    -- Canonical cosmetic taxonomy for current/future seasons.
    'gameplay_theme'::text,
    'arena_theme'::text,
    'command_pack'::text,
    'countdown_style'::text,
    'sound_pack'::text,
    'success_reaction'::text,
    'failure_reaction'::text,
    'score_effect'::text,
    'hud_style'::text,
    'particle_pack'::text,
    'home_background'::text,
    'mode_card_skin'::text,
    'profile_frame'::text,
    'profile_badge'::text,
    'title'::text,
    'emblem'::text,
    'player_code_style'::text,
    'share_card'::text,
    'result_card_style'::text
  ]));
