import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/shop/data/local_shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    ReactCosmetics.currentCountdownStyle = ReactCountdownStyle.core;
    ReactCosmetics.currentSoundPack = ReactSoundPack.core;
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;
    ReactCosmetics.currentShareStyle = ReactShareStyle.core;
    await LocalShopState.load();
  });

  test('core visual style is equipped by default', () async {
    expect(LocalShopState.isOwned(LocalShopState.corePackId), isTrue);
    expect(await LocalShopState.equippedPack(), LocalShopState.corePackId);
    expect(await LocalShopState.equippedPackIds(), {LocalShopState.corePackId});
  });

  test('debug build exposes every implemented cosmetic family', () {
    for (final packId in <String>[
      LocalShopState.redlinePackId,
      LocalShopState.synthwavePackId,
      LocalShopState.monoPackId,
      LocalShopState.greenlinePackId,
      LocalShopState.voltagePackId,
      LocalShopState.emberPackId,
      LocalShopState.hotPinkPackId,
      LocalShopState.ringsCountdownPackId,
      LocalShopState.cardsCountdownPackId,
      LocalShopState.terminalCountdownPackId,
      LocalShopState.pulseCountdownPackId,
      LocalShopState.arcadeSfxPackId,
      LocalShopState.pulseSfxPackId,
      LocalShopState.bassSfxPackId,
      LocalShopState.minimalSfxPackId,
      LocalShopState.laserSfxPackId,
      LocalShopState.glitchCommandsPackId,
      LocalShopState.terminalCommandsPackId,
      LocalShopState.arcadeCommandsPackId,
      LocalShopState.minimalCommandsPackId,
      LocalShopState.impactCommandsPackId,
      LocalShopState.proShareCardsPackId,
    ]) {
      expect(LocalShopState.isOwned(packId), isTrue, reason: packId);
      expect(LocalShopState.isImplemented(packId), isTrue, reason: packId);
    }
  });

  test('all five cosmetic slots can be equipped together', () async {
    await LocalShopState.equip(LocalShopState.greenlinePackId);
    await LocalShopState.equip(LocalShopState.terminalCountdownPackId);
    await LocalShopState.equip(LocalShopState.bassSfxPackId);
    await LocalShopState.equip(LocalShopState.impactCommandsPackId);
    await LocalShopState.equip(LocalShopState.proShareCardsPackId);

    expect(await LocalShopState.equippedPackIds(), {
      LocalShopState.greenlinePackId,
      LocalShopState.terminalCountdownPackId,
      LocalShopState.bassSfxPackId,
      LocalShopState.impactCommandsPackId,
      LocalShopState.proShareCardsPackId,
    });
    expect(ReactCosmetics.currentReactionPack, ReactReactionPack.greenline);
    expect(ReactCosmetics.currentCountdownStyle, ReactCountdownStyle.terminal);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.bass);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.impact);
    expect(ReactCosmetics.currentShareStyle, ReactShareStyle.pro);
  });

  test('core share style restores only the share slot', () async {
    await LocalShopState.equip(LocalShopState.monoPackId);
    await LocalShopState.equip(LocalShopState.arcadeSfxPackId);
    await LocalShopState.equip(LocalShopState.glitchCommandsPackId);
    await LocalShopState.equip(LocalShopState.proShareCardsPackId);
    await LocalShopState.equipCoreShareStyle();

    expect(ReactCosmetics.currentTheme, ReactVisualTheme.mono);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
    expect(ReactCosmetics.currentShareStyle, ReactShareStyle.core);
  });

  test('new cosmetic slots persist after reload', () async {
    await LocalShopState.equip(LocalShopState.hotPinkPackId);
    await LocalShopState.equip(LocalShopState.pulseCountdownPackId);
    await LocalShopState.equip(LocalShopState.laserSfxPackId);
    await LocalShopState.equip(LocalShopState.terminalCommandsPackId);
    await LocalShopState.equip(LocalShopState.proShareCardsPackId);

    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    ReactCosmetics.currentCountdownStyle = ReactCountdownStyle.core;
    ReactCosmetics.currentSoundPack = ReactSoundPack.core;
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;
    ReactCosmetics.currentShareStyle = ReactShareStyle.core;
    await LocalShopState.load();

    expect(ReactCosmetics.currentReactionPack, ReactReactionPack.hotPink);
    expect(ReactCosmetics.currentCountdownStyle, ReactCountdownStyle.pulse);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.laser);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.terminal);
    expect(ReactCosmetics.currentShareStyle, ReactShareStyle.pro);
  });

  test('new reaction palettes are distinct', () {
    final colors = <int>{
      ReactCosmetics.paletteForReactionPack(ReactReactionPack.greenline)
          .primary
          .toARGB32(),
      ReactCosmetics.paletteForReactionPack(ReactReactionPack.voltage)
          .primary
          .toARGB32(),
      ReactCosmetics.paletteForReactionPack(ReactReactionPack.ember)
          .primary
          .toARGB32(),
      ReactCosmetics.paletteForReactionPack(ReactReactionPack.hotPink)
          .primary
          .toARGB32(),
    };
    expect(colors.length, 4);
  });
}
