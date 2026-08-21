alter table public.react_season_rewards
  drop constraint react_season_rewards_reward_kind_check;

alter table public.react_season_rewards
  add constraint react_season_rewards_reward_kind_check
  check (reward_kind = any (array[
    -- Legacy S01 aliases.
    'reaction_pack'::text,
    'command_style'::text,
    'share_style'::text,
    'home_theme'::text,
    'score_effect'::text,
    'success_effect'::text,
    'failure_effect'::text,
    -- Canonical gameplay families.
    'gameplay_theme'::text,
    'arena_theme'::text,
    'command_pack'::text,
    'countdown_style'::text,
    'sound_pack'::text,
    'input_reaction_pack'::text,
    'success_reaction'::text,
    'failure_reaction'::text,
    'hud_style'::text,
    'particle_pack'::text,
    -- Canonical home/profile/social families.
    'home_background'::text,
    'mode_card_skin'::text,
    'profile_frame'::text,
    'profile_badge'::text,
    'title'::text,
    'emblem'::text,
    'player_code_style'::text,
    'share_card'::text,
    'result_score_style'::text,
    'result_success_style'::text,
    'result_failure_style'::text,
    'result_card_style'::text
  ]));
