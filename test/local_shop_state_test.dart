import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/shop/data/local_shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    await LocalShopState.load();
  });

  test('core cosmetic is owned and equipped by default', () async {
    expect(LocalShopState.isOwned(LocalShopState.corePackId), isTrue);
    expect(await LocalShopState.equippedPack(), LocalShopState.corePackId);
  });

  test('implemented visual themes are unlocked in debug builds', () {
    expect(LocalShopState.debugVisualUnlocksEnabled, isTrue);
    expect(LocalShopState.isOwned(LocalShopState.redlinePackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.synthwavePackId), isTrue);
    expect(LocalShopState.isOwned(LocalShopState.monoPackId), isTrue);
    expect(LocalShopState.isOwned('arcade_sfx'), isFalse);
  });

  test('debug visual theme can be equipped and persisted', () async {
    await LocalShopState.equip(LocalShopState.synthwavePackId);
    expect(await LocalShopState.equippedPack(), LocalShopState.synthwavePackId);

    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    await LocalShopState.load();

    expect(await LocalShopState.equippedPack(), LocalShopState.synthwavePackId);
  });

  test('unimplemented paid cosmetic cannot be equipped locally', () async {
    await LocalShopState.equip('arcade_sfx');

    expect(await LocalShopState.equippedPack(), LocalShopState.corePackId);
  });
}
