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

  test('unsupported future cosmetic cannot claim EQUIPPED', () async {
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
