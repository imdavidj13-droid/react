import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/shop/data/local_shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactCosmetics.currentTheme = ReactVisualTheme.core;
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

  test('debug build exposes every implemented cosmetic', () {
    expect(LocalShopState.isOwned(LocalShopState.redlinePackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.synthwavePackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.monoPackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.arcadeSfxPackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.glitchCommandsPackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.proShareCardsPackId), isTrue);
  });

  test('all four cosmetic slots can be equipped together', () async {
    await LocalShopState.equip(LocalShopState.redlinePackId);
    await LocalShopState.equip(LocalShopState.arcadeSfxPackId);
    await LocalShopState.equip(LocalShopState.glitchCommandsPackId);
    await LocalShopState.equip(LocalShopState.proShareCardsPackId);

    expect(await LocalShopState.equippedPackIds(), {
      LocalShopState.redlinePackId,
      LocalShopState.arcadeSfxPackId,
      LocalShopState.glitchCommandsPackId,
      LocalShopState.proShareCardsPackId,
    });
    expect(ReactCosmetics.currentTheme, ReactVisualTheme.redline);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
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

  test('equipped cosmetic slots persist after reload', () async {
    await LocalShopState.equip(LocalShopState.synthwavePackId);
    await LocalShopState.equip(LocalShopState.arcadeSfxPackId);
    await LocalShopState.equip(LocalShopState.glitchCommandsPackId);
    await LocalShopState.equip(LocalShopState.proShareCardsPackId);

    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    ReactCosmetics.currentSoundPack = ReactSoundPack.core;
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;
    ReactCosmetics.currentShareStyle = ReactShareStyle.core;
    await LocalShopState.load();

    expect(ReactCosmetics.currentTheme, ReactVisualTheme.synthwave);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
    expect(ReactCosmetics.currentShareStyle, ReactShareStyle.pro);
  });
}
