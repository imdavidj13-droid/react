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
    await LocalShopState.load();
  });

  test('core visual style is equipped by default', () async {
    expect(LocalShopState.isOwned(LocalShopState.corePackId), isTrue);
    expect(await LocalShopState.equippedPack(), LocalShopState.corePackId);
    expect(await LocalShopState.equippedPackIds(), {LocalShopState.corePackId});
  });

  test('debug build exposes implemented cosmetics', () {
    expect(LocalShopState.isOwned(LocalShopState.redlinePackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.synthwavePackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.monoPackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.arcadeSfxPackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.glitchCommandsPackId), isTrue);
    expect(LocalShopState.isOwned('pro_share_cards'), isFalse);
  });

  test('visual, audio and command cosmetics can be equipped together', () async {
    await LocalShopState.equip(LocalShopState.redlinePackId);
    await LocalShopState.equip(LocalShopState.arcadeSfxPackId);
    await LocalShopState.equip(LocalShopState.glitchCommandsPackId);

    expect(await LocalShopState.equippedPackIds(), {
      LocalShopState.redlinePackId,
      LocalShopState.arcadeSfxPackId,
      LocalShopState.glitchCommandsPackId,
    });
    expect(ReactCosmetics.currentTheme, ReactVisualTheme.redline);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
  });

  test('core SFX can be restored without changing other slots', () async {
    await LocalShopState.equip(LocalShopState.monoPackId);
    await LocalShopState.equip(LocalShopState.arcadeSfxPackId);
    await LocalShopState.equip(LocalShopState.glitchCommandsPackId);
    await LocalShopState.equipCoreAudio();

    expect(ReactCosmetics.currentTheme, ReactVisualTheme.mono);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.core);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
  });

  test('core command style can be restored without changing other slots', () async {
    await LocalShopState.equip(LocalShopState.synthwavePackId);
    await LocalShopState.equip(LocalShopState.arcadeSfxPackId);
    await LocalShopState.equip(LocalShopState.glitchCommandsPackId);
    await LocalShopState.equipCoreCommandStyle();

    expect(ReactCosmetics.currentTheme, ReactVisualTheme.synthwave);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.core);
  });

  test('equipped cosmetic slots persist after reload', () async {
    await LocalShopState.equip(LocalShopState.synthwavePackId);
    await LocalShopState.equip(LocalShopState.arcadeSfxPackId);
    await LocalShopState.equip(LocalShopState.glitchCommandsPackId);

    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    ReactCosmetics.currentSoundPack = ReactSoundPack.core;
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;
    await LocalShopState.load();

    expect(ReactCosmetics.currentTheme, ReactVisualTheme.synthwave);
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
  });
}
