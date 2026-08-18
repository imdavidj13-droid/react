import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

enum ReactVariantMechanic {
  command,
  target,
  grid,
  memory,
  tether,
  overload,
}

enum ReactVariantMode {
  phantom,
  mosaic,
  accel,
  titan,
  beacon,
  collapse,
  magnet,
  illusion,
  checkpoint,
  reactor,
  nexus,
  prism,
  memory,
  hunter,
  ascent,
  fracture,
  tempest,
  chain,
  survivor,
  decoder,
  stealth,
  snap,
  vortex,
  timedrop,
  echo,
  orbit,
  fuse,
  shuffle,
  pulse,
  glitch,
  zenith,
  blackout,
  ricochet,
  tether,
  overload,
  lockstep,
}

extension ReactVariantModeUi on ReactVariantMode {
  String get id => name;

  String get title => switch (this) {
    ReactVariantMode.phantom => 'PHANTOM',
    ReactVariantMode.mosaic => 'MOSAIC',
    ReactVariantMode.accel => 'ACCEL',
    ReactVariantMode.titan => 'TITAN',
    ReactVariantMode.beacon => 'BEACON',
    ReactVariantMode.collapse => 'COLLAPSE',
    ReactVariantMode.magnet => 'MAGNET',
    ReactVariantMode.illusion => 'ILLUSION',
    ReactVariantMode.checkpoint => 'CHECKPOINT',
    ReactVariantMode.reactor => 'REACTOR',
    ReactVariantMode.nexus => 'NEXUS',
    ReactVariantMode.prism => 'PRISM',
    ReactVariantMode.memory => 'MEMORY',
    ReactVariantMode.hunter => 'HUNTER',
    ReactVariantMode.ascent => 'ASCENT',
    ReactVariantMode.fracture => 'FRACTURE',
    ReactVariantMode.tempest => 'TEMPEST',
    ReactVariantMode.chain => 'CHAIN',
    ReactVariantMode.survivor => 'SURVIVOR',
    ReactVariantMode.decoder => 'DECODER',
    ReactVariantMode.stealth => 'STEALTH',
    ReactVariantMode.snap => 'SNAP',
    ReactVariantMode.vortex => 'VORTEX',
    ReactVariantMode.timedrop => 'TIMEDROP',
    ReactVariantMode.echo => 'ECHO',
    ReactVariantMode.orbit => 'ORBIT',
    ReactVariantMode.fuse => 'FUSE',
    ReactVariantMode.shuffle => 'SHUFFLE',
    ReactVariantMode.pulse => 'PULSE',
    ReactVariantMode.glitch => 'GLITCH',
    ReactVariantMode.zenith => 'ZENITH',
    ReactVariantMode.blackout => 'BLACKOUT',
    ReactVariantMode.ricochet => 'RICOCHET',
    ReactVariantMode.tether => 'TETHER',
    ReactVariantMode.overload => 'OVERLOAD',
    ReactVariantMode.lockstep => 'LOCKSTEP',
  };

  String get badge => switch (this) {
    ReactVariantMode.phantom => 'GHOST CUES',
    ReactVariantMode.mosaic => 'GRID MODE',
    ReactVariantMode.accel => 'RAW SPEED',
    ReactVariantMode.titan => 'BOSS MODE',
    ReactVariantMode.beacon => 'TARGET LOCK',
    ReactVariantMode.collapse => 'CLOSING RING',
    ReactVariantMode.magnet => 'DRAG FIELD',
    ReactVariantMode.illusion => 'OPTICAL',
    ReactVariantMode.checkpoint => 'LONG RUN',
    ReactVariantMode.reactor => 'HEAT METER',
    ReactVariantMode.nexus => 'HYBRID',
    ReactVariantMode.prism => 'COLOR LOGIC',
    ReactVariantMode.memory => 'RECALL',
    ReactVariantMode.hunter => 'TRACK MODE',
    ReactVariantMode.ascent => 'LEVEL RUN',
    ReactVariantMode.fracture => 'MULTI ZONE',
    ReactVariantMode.tempest => 'STORM',
    ReactVariantMode.chain => 'COMBO CORE',
    ReactVariantMode.survivor => 'SUDDEN DEATH',
    ReactVariantMode.decoder => 'MIND MODE',
    ReactVariantMode.stealth => 'MINIMAL',
    ReactVariantMode.snap => 'BURST',
    ReactVariantMode.vortex => 'SPIN',
    ReactVariantMode.timedrop => 'TIME GAIN',
    ReactVariantMode.echo => 'REPEAT',
    ReactVariantMode.orbit => 'RING TRACK',
    ReactVariantMode.fuse => 'COMBO RUN',
    ReactVariantMode.shuffle => 'REMIX',
    ReactVariantMode.pulse => 'BEAT WINDOW',
    ReactVariantMode.glitch => 'DECOY MODE',
    ReactVariantMode.zenith => 'PEAK MODE',
    ReactVariantMode.blackout => 'LOW LIGHT',
    ReactVariantMode.ricochet => 'BOUNCE',
    ReactVariantMode.tether => 'DUAL ACTION',
    ReactVariantMode.overload => 'CHAOS',
    ReactVariantMode.lockstep => 'CADENCE',
  };

  String get subtitle => switch (this) {
    ReactVariantMode.phantom => 'Prompts flash, then disappear.',
    ReactVariantMode.mosaic => 'Tiny panels fire different cues.',
    ReactVariantMode.accel => 'Speed ramps forever with no ceiling.',
    ReactVariantMode.titan => 'Heavy boss rounds test endurance.',
    ReactVariantMode.beacon => 'Follow one live signal only.',
    ReactVariantMode.collapse => 'The arena shrinks as you play.',
    ReactVariantMode.magnet => 'Prompts pull toward the edges.',
    ReactVariantMode.illusion => 'Visual tricks distort every cue.',
    ReactVariantMode.checkpoint => 'Bank progress at safe milestones.',
    ReactVariantMode.reactor => 'Heat builds until you cool it.',
    ReactVariantMode.nexus => 'Multiple mechanics merge together.',
    ReactVariantMode.prism => 'Color-coded rules change every cue.',
    ReactVariantMode.memory => 'Recall a growing command chain.',
    ReactVariantMode.hunter => 'Find the live target fast.',
    ReactVariantMode.ascent => 'Every round climbs in difficulty.',
    ReactVariantMode.fracture => 'The arena splits into active zones.',
    ReactVariantMode.tempest => 'Modifiers shift in chaotic waves.',
    ReactVariantMode.chain => 'Drop the combo and the run ends.',
    ReactVariantMode.survivor => 'One life. Last as long as you can.',
    ReactVariantMode.decoder => 'Translate symbols into actions.',
    ReactVariantMode.stealth => 'Tiny cues with almost no HUD.',
    ReactVariantMode.snap => 'Five-action bursts at top speed.',
    ReactVariantMode.vortex => 'Targets spiral inward as you react.',
    ReactVariantMode.timedrop => 'Perfect streaks earn extra time.',
    ReactVariantMode.echo => 'Repeat one cue multiple times.',
    ReactVariantMode.orbit => 'Hit moving targets on the rim.',
    ReactVariantMode.fuse => 'Build combos before the fuse burns.',
    ReactVariantMode.shuffle => 'Rules remap in the middle.',
    ReactVariantMode.pulse => 'Act only when the arena pulses.',
    ReactVariantMode.glitch => 'Fake prompts try to fool you.',
    ReactVariantMode.zenith => 'Climb to peak pace and hold it.',
    ReactVariantMode.blackout => 'Prompts vanish between flashes.',
    ReactVariantMode.ricochet => 'Targets rebound around the ring.',
    ReactVariantMode.tether => 'Hold contact while hitting cues.',
    ReactVariantMode.overload => 'Multiple prompts stack at once.',
    ReactVariantMode.lockstep => 'Stay perfectly in strict rhythm.',
  };

  String get detail => switch (this) {
    ReactVariantMode.phantom => 'INSTANT RECALL  •  QUICK EYES',
    ReactVariantMode.mosaic => 'SCAN SPEED  •  MICRO FOCUS',
    ReactVariantMode.accel => 'PURE REACTION  •  ENDLESS CLIMB',
    ReactVariantMode.titan => 'SLOW POWER  •  BIG PRESSURE',
    ReactVariantMode.beacon => 'SIGNAL TRACK  •  DISCARD NOISE',
    ReactVariantMode.collapse => 'SPACE LOSS  •  PANIC CONTROL',
    ReactVariantMode.magnet => 'CURVED READS  •  EDGE PRESSURE',
    ReactVariantMode.illusion => 'TRICK SIGHT  •  TRUST SKILL',
    ReactVariantMode.checkpoint => 'SAVE POINTS  •  STEADY PUSH',
    ReactVariantMode.reactor => 'RISK BALANCE  •  TIMED RESET',
    ReactVariantMode.nexus => 'ALL SKILLS  •  MIXED COMMANDS',
    ReactVariantMode.prism => 'FAST READS  •  SWITCH THINKING',
    ReactVariantMode.memory => 'STACKED PATTERNS  •  NO HINTS',
    ReactVariantMode.hunter => 'FALSE LEADS  •  TARGET LOCK',
    ReactVariantMode.ascent => 'SPEED RAMP  •  NO BREAKS',
    ReactVariantMode.fracture => 'SPLIT FOCUS  •  FAST SWITCHES',
    ReactVariantMode.tempest => 'SURPRISE RULES  •  TURBULENCE',
    ReactVariantMode.chain => 'PERFECT LINKS  •  ZERO DROPS',
    ReactVariantMode.survivor => 'NO RETRIES  •  HIGH TENSION',
    ReactVariantMode.decoder => 'ICON READS  •  BRAIN SPEED',
    ReactVariantMode.stealth => 'SHARP EYES  •  QUIET FOCUS',
    ReactVariantMode.snap => 'MICRO ROUNDS  •  RAPID RESET',
    ReactVariantMode.vortex => 'SHRINKING SPACE  •  PRESSURE',
    ReactVariantMode.timedrop => 'BONUS CLOCK  •  STREAK PLAY',
    ReactVariantMode.echo => 'CHAIN INPUTS  •  AUDIO MEMORY',
    ReactVariantMode.orbit => 'ROTATING PATH  •  SPATIAL TIMING',
    ReactVariantMode.fuse => 'TIMER RESET  •  STREAK REWARD',
    ReactVariantMode.shuffle => 'CONTROL FLIPS  •  ADAPT FAST',
    ReactVariantMode.pulse => 'VISUAL RHYTHM  •  PRECISION',
    ReactVariantMode.glitch => 'UI TRICKS  •  FOCUS TEST',
    ReactVariantMode.zenith => 'RISING SPEED  •  RISK BONUS',
    ReactVariantMode.blackout => 'MEMORY TEST  •  NO PANIC',
    ReactVariantMode.ricochet => 'DEFLECT PATHS  •  QUICK CORRECTION',
    ReactVariantMode.tether => 'HOLD + TAP  •  MULTITASK',
    ReactVariantMode.overload => 'PRIORITY CHOICE  •  FAST READS',
    ReactVariantMode.lockstep => 'FIXED TEMPO  •  NO HESITATION',
  };

  String get rules => switch (this) {
    ReactVariantMode.phantom => 'Read the command while it flashes. The cue disappears after half a second, but the timer keeps running. Perform the remembered gesture before time expires.',
    ReactVariantMode.mosaic => 'A 3×3 panel grid lights one cue at a time. Tap the live panel before it moves. Wrong panels cost a life.',
    ReactVariantMode.accel => 'Clear gesture commands continuously. Every clear reduces the reaction window. A single miss ends the run.',
    ReactVariantMode.titan => 'Normal gesture rounds are interrupted by boss rounds. Bosses require three correct hits on the same command before their larger timer expires.',
    ReactVariantMode.beacon => 'Several signals appear, but only one is live. Tap the bright beacon and ignore every decoy. The live signal relocates after every clear.',
    ReactVariantMode.collapse => 'Tap the target inside the arena. Every clear shrinks the playable ring and target, leaving less room for error. Three misses end the run.',
    ReactVariantMode.magnet => 'Perform each gesture while its prompt is dragged from the centre toward a random edge. Let it reach the edge and you lose a life.',
    ReactVariantMode.illusion => 'The command remains truthful while its visual presentation rotates, scales and shifts. Ignore the distortion and perform the real gesture.',
    ReactVariantMode.checkpoint => 'Every five clears banks a checkpoint. A miss sends your score back to the last banked checkpoint instead of wiping the entire run. Three lives.',
    ReactVariantMode.reactor => 'Fast clears generate more heat than controlled clears. Heat cools over time and during cooling breaks. Reach maximum heat and the reactor fails.',
    ReactVariantMode.nexus => 'The rule changes every three clears between standard, ghost, reverse and pulse phases. Read the phase indicator before acting.',
    ReactVariantMode.prism => 'Blue cues use the gesture normally. Pink cues reverse swipe directions. The colour rule is chosen independently for every command.',
    ReactVariantMode.memory => 'Watch a growing sequence across four pads, then repeat the entire chain in order. Each clear adds one more step.',
    ReactVariantMode.hunter => 'Multiple targets appear at once. Find and tap the live target among convincing false leads before the lock timer expires.',
    ReactVariantMode.ascent => 'Five clears completes a level. Each new level shortens command windows and raises intensity without a rest phase.',
    ReactVariantMode.fracture => 'The arena is split into four zones. One zone becomes active. Tap the active zone quickly as focus jumps around the arena.',
    ReactVariantMode.tempest => 'Every four clears the storm changes rule: speed, blackout, reverse controls or pulse timing. Survive the current wave and adapt to the next.',
    ReactVariantMode.chain => 'Every correct gesture extends the combo. One wrong gesture or timeout breaks the chain and ends the run immediately.',
    ReactVariantMode.survivor => 'You have exactly one life. Commands accelerate as the score rises. Any wrong gesture or timeout ends the run.',
    ReactVariantMode.decoder => 'Only the command symbol is shown. Decode the icon and perform its gesture before the timer expires. Text hints are removed.',
    ReactVariantMode.stealth => 'The HUD is stripped back and the command cue is intentionally small. Rely on sharp visual reads. One miss ends the run.',
    ReactVariantMode.snap => 'Commands arrive in bursts of five at a very short reaction window. Complete all five to earn a brief reset before the next burst.',
    ReactVariantMode.vortex => 'Tap a target that rotates while spiralling toward the centre. Clear it before it collapses into the core.',
    ReactVariantMode.timedrop => 'Start with a limited run clock. Every five-command perfect streak adds bonus time. A miss breaks the streak but the clock keeps falling.',
    ReactVariantMode.echo => 'One gesture is selected for the round and must be repeated several times. Complete the displayed repeat count to clear the round.',
    ReactVariantMode.orbit => 'A live target continuously rotates around the arena rim. Tap the moving target before its orbit timer expires.',
    ReactVariantMode.fuse => 'The fuse constantly burns down. Correct gestures add time back to the fuse and build combo. Let the fuse reach zero and the run ends.',
    ReactVariantMode.shuffle => 'Control mappings flip every five clears. During FLIPPED phases, left/right and up/down swipe commands must be performed in the opposite direction.',
    ReactVariantMode.pulse => 'A command is always visible, but input only counts during the bright pulse window. Acting between beats is a miss.',
    ReactVariantMode.glitch => 'A fake decoy prompt flashes before some real commands. Do nothing during DECOY, then react to the LIVE prompt that follows.',
    ReactVariantMode.zenith => 'Reaction windows ramp down until peak pace. Once peak speed is reached, hold it for bonus scoring without further acceleration.',
    ReactVariantMode.blackout => 'The command repeatedly flashes on and off. Remember it through the dark interval and perform the gesture before the overall timer expires.',
    ReactVariantMode.ricochet => 'A target bounces around the arena using reflected movement. Track its changing path and tap it before the timer expires.',
    ReactVariantMode.tether => 'Keep one finger held on the tether anchor. While maintaining contact, use another finger to hit the live target. Releasing the tether is a miss.',
    ReactVariantMode.overload => 'Three prompts appear simultaneously with priority numbers. Tap all three in priority order before the overload timer expires.',
    ReactVariantMode.lockstep => 'Commands run to a strict fixed beat. Perform the displayed gesture only inside each narrow beat window. Early or late input ends the run.',
  };

  ReactVariantMechanic get mechanic => switch (this) {
    ReactVariantMode.mosaic || ReactVariantMode.fracture => ReactVariantMechanic.grid,
    ReactVariantMode.beacon ||
    ReactVariantMode.collapse ||
    ReactVariantMode.hunter ||
    ReactVariantMode.vortex ||
    ReactVariantMode.orbit ||
    ReactVariantMode.ricochet => ReactVariantMechanic.target,
    ReactVariantMode.memory => ReactVariantMechanic.memory,
    ReactVariantMode.tether => ReactVariantMechanic.tether,
    ReactVariantMode.overload => ReactVariantMechanic.overload,
    _ => ReactVariantMechanic.command,
  };

  Color get color => switch (this) {
    ReactVariantMode.phantom ||
    ReactVariantMode.accel ||
    ReactVariantMode.magnet ||
    ReactVariantMode.memory ||
    ReactVariantMode.decoder ||
    ReactVariantMode.zenith => ReactColors.electricBlueBright,
    ReactVariantMode.mosaic ||
    ReactVariantMode.hunter ||
    ReactVariantMode.prism ||
    ReactVariantMode.glitch ||
    ReactVariantMode.survivor => ReactColors.coral,
    ReactVariantMode.beacon ||
    ReactVariantMode.checkpoint ||
    ReactVariantMode.ascent ||
    ReactVariantMode.stealth ||
    ReactVariantMode.pulse => ReactColors.lime,
    ReactVariantMode.titan ||
    ReactVariantMode.reactor ||
    ReactVariantMode.tempest ||
    ReactVariantMode.snap ||
    ReactVariantMode.fuse ||
    ReactVariantMode.tether => const Color(0xFFFF8A35),
    ReactVariantMode.collapse ||
    ReactVariantMode.illusion ||
    ReactVariantMode.fracture ||
    ReactVariantMode.vortex ||
    ReactVariantMode.orbit ||
    ReactVariantMode.blackout => ReactColors.purple,
    ReactVariantMode.nexus ||
    ReactVariantMode.chain ||
    ReactVariantMode.timedrop ||
    ReactVariantMode.echo ||
    ReactVariantMode.ricochet ||
    ReactVariantMode.lockstep => const Color(0xFF37D6E8),
    ReactVariantMode.shuffle => const Color(0xFFFFD33D),
    ReactVariantMode.overload => const Color(0xFFFF526E),
  };

  IconData get icon => switch (this) {
    ReactVariantMode.phantom => Icons.visibility_off_rounded,
    ReactVariantMode.mosaic => Icons.grid_view_rounded,
    ReactVariantMode.accel => Icons.rocket_launch_rounded,
    ReactVariantMode.titan => Icons.shield_rounded,
    ReactVariantMode.beacon => Icons.gps_fixed_rounded,
    ReactVariantMode.collapse => Icons.motion_photos_off_rounded,
    ReactVariantMode.magnet => Icons.u_turn_left_rounded,
    ReactVariantMode.illusion => Icons.visibility_rounded,
    ReactVariantMode.checkpoint => Icons.flag_rounded,
    ReactVariantMode.reactor => Icons.local_fire_department_rounded,
    ReactVariantMode.nexus => Icons.hub_rounded,
    ReactVariantMode.prism => Icons.change_history_rounded,
    ReactVariantMode.memory => Icons.psychology_alt_rounded,
    ReactVariantMode.hunter => Icons.my_location_rounded,
    ReactVariantMode.ascent => Icons.keyboard_double_arrow_up_rounded,
    ReactVariantMode.fracture => Icons.hexagon_rounded,
    ReactVariantMode.tempest => Icons.cyclone_rounded,
    ReactVariantMode.chain => Icons.link_rounded,
    ReactVariantMode.survivor => Icons.dangerous_rounded,
    ReactVariantMode.decoder => Icons.code_rounded,
    ReactVariantMode.stealth => Icons.remove_red_eye_rounded,
    ReactVariantMode.snap => Icons.bolt_rounded,
    ReactVariantMode.vortex => Icons.blur_circular_rounded,
    ReactVariantMode.timedrop => Icons.more_time_rounded,
    ReactVariantMode.echo => Icons.sensors_rounded,
    ReactVariantMode.orbit => Icons.circle_outlined,
    ReactVariantMode.fuse => Icons.timer_rounded,
    ReactVariantMode.shuffle => Icons.shuffle_rounded,
    ReactVariantMode.pulse => Icons.monitor_heart_rounded,
    ReactVariantMode.glitch => Icons.art_track_rounded,
    ReactVariantMode.zenith => Icons.landscape_rounded,
    ReactVariantMode.blackout => Icons.dark_mode_rounded,
    ReactVariantMode.ricochet => Icons.sports_baseball_rounded,
    ReactVariantMode.tether => Icons.link_rounded,
    ReactVariantMode.overload => Icons.scatter_plot_rounded,
    ReactVariantMode.lockstep => Icons.graphic_eq_rounded,
  };
}
