import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/season/data/season_cosmetic_state.dart';
import 'package:react/features/season/domain/season_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const greenline = SeasonReward(
    id: 'greenline',
    tier: 3,
    track: SeasonRewardTrack.free,
    kind: 'reaction_pack',
    rewardKey: 'greenline',
    name: 'GREENLINE',
    description: 'Full gameplay colour theme',
    milestone: false,
  );

  const rings = SeasonReward(
    id: 'rings',
    tier: 6,
    track: SeasonRewardTrack.free,
    kind: 'countdown_style',
    rewardKey: 'rings_countdown',
    name: 'RINGS COUNTDOWN',
    description: 'Countdown screen',
    milestone: false,
  );

  const terminal = SeasonReward(
    id: 'terminal',
    tier: 4,
    track: SeasonRewardTrack.premium,
    kind: 'command_style',
    rewardKey: 'terminal_commands',
    name: 'TERMINAL COMMANDS',
    description: 'Command text pack',
    milestone: false,
  );

  const arcadeSfx = SeasonReward(
    id: 'arcade',
    tier: 9,
    track: SeasonRewardTrack.free,
    kind: 'sound_pack',
    rewardKey: 'arcade_sfx',
    name: 'ARCADE SFX',
    description: 'Sound pack',
    milestone: false,
  );

  const reactionArc = SeasonReward(
    id: 'reaction-arc',
    tier: 8,
    track: SeasonRewardTrack.free,
    kind: 'input_reaction_pack',
    rewardKey: 'reaction_arc',
    name: 'ARC REACTION',
    description: 'Live gesture-run success and miss feedback.',
    milestone: false,
  );

  const ionParticles = SeasonReward(
    id: 'particle-ion',
    tier: 9,
    track: SeasonRewardTrack.premium,
    kind: 'particle_pack',
    rewardKey: 'particle_ion',
    name: 'ION PARTICLES',
    description: 'Ambient gameplay particles.',
    milestone: false,
  );

  const futureArena = SeasonReward(
    id: 'future-arena',
    tier: 1,
    track: SeasonRewardTrack.free,
    kind: 'arena_theme',
    rewardKey: 'arena_future',
    name: 'FUTURE ARENA',
    description: 'Not rendered yet',
    milestone: false,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SeasonCosmeticState.load();
    await SeasonCosmeticState.syncOwnedRewards(const <SeasonReward>[
      greenline,
      rings,
      terminal,
      arcadeSfx,
      reactionArc,
      ionParticles,
      futureArena,
    ]);
  });

  test('legacy Shop-era packs equip through unified SeasonCosmeticState', () async {
    expect(await SeasonCosmeticState.equip(greenline), isTrue);
    expect(ReactCosmetics.currentReactionPack, ReactReactionPack.greenline);
    expect(SeasonCosmeticState.isEquipped(greenline), isTrue);

    expect(await SeasonCosmeticState.equip(rings), isTrue);
    expect(ReactCosmetics.currentCountdownStyle, ReactCountdownStyle.rings);

    expect(await SeasonCosmeticState.equip(terminal), isTrue);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.terminal);

    expect(await SeasonCosmeticState.equip(arcadeSfx), isTrue);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
  });

  test('live reaction and particle families equip through Locker state', () async {
    expect(SeasonCosmeticState.isEquippable(reactionArc), isTrue);
    expect(await SeasonCosmeticState.equip(reactionArc), isTrue);
    expect(SeasonCosmeticState.isEquipped(reactionArc), isTrue);

    expect(SeasonCosmeticState.isEquippable(ionParticles), isTrue);
    expect(await SeasonCosmeticState.equip(ionParticles), isTrue);
    expect(SeasonCosmeticState.isEquipped(ionParticles), isTrue);

    final flame = File('lib/game/react_game.dart').readAsStringSync();
    expect(flame, contains('SeasonGameplayStyle.reactionParticleCount'));
    expect(flame, contains('SeasonGameplayStyle.reactionRingCount'));
    expect(flame, contains('SeasonGameplayStyle.particleCount(48)'));
    expect(flame, contains('SeasonGameplayStyle.particleSpeedScale()'));
  });

  test('unsupported future Arena cosmetic cannot claim EQUIPPED', () async {
    expect(SeasonCosmeticState.isOwned(futureArena.rewardKey), isTrue);
    expect(SeasonCosmeticState.isEquippable(futureArena), isFalse);
    expect(await SeasonCosmeticState.equip(futureArena), isFalse);
    expect(SeasonCosmeticState.isEquipped(futureArena), isFalse);
  });

  test('clearing a legacy family returns its renderer to CORE', () async {
    await SeasonCosmeticState.equip(greenline);
    await SeasonCosmeticState.clearKind(greenline.kind);

    expect(ReactCosmetics.currentReactionPack, ReactReactionPack.core);
    expect(SeasonCosmeticState.isEquipped(greenline), isFalse);
  });
}
