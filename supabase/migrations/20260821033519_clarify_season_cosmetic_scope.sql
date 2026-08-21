update public.react_season_rewards r
set description = case r.reward_kind
  when 'reaction_pack' then 'Full gameplay colour theme: rethemes run backgrounds, arena surfaces, HUD accents and feedback colours.'
  when 'command_style' then 'Command-word styling for gesture-based runs. Does not affect Sequence dots or other UI text.'
  when 'countdown_style' then 'Pre-run 3-2-1 countdown presentation. Does not change the in-run timer ring.'
  when 'sound_pack' then 'Gameplay sound set for countdown, command, success, miss, warning, handoff and completion cues.'
  when 'share_style' then 'Exported share-card style. Does not restyle the normal Results screen.'
  when 'profile_frame' then 'Outer cosmetic frame around the Player Profile screen.'
  when 'profile_badge' then 'Named badge shown below your avatar on the Player Profile identity card.'
  when 'player_code_style' then 'Styles your RX player-code container on Player Profile only.'
  when 'home_theme' then 'Home-screen visual treatment only.'
  when 'score_effect' then 'Final-score treatment on the Results screen.'
  when 'success_effect' then 'Successful/completed outcome treatment on the Results screen.'
  when 'failure_effect' then 'Miss/failure outcome treatment on the Results screen.'
  when 'mode_card_skin' then 'Restyles cards in the Modes catalogue.'
  when 'title' then 'Equippable title shown directly below your player name on Player Profile.'
  when 'emblem' then 'Equippable emblem shown beside your RX player code on Player Profile.'
  else r.description
end
from public.react_seasons s
where r.season_id = s.id
  and s.code = 'S01_OVERDRIVE';
