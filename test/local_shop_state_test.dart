import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/shop/data/local_shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('core cosmetic is owned and equipped by default', () async {
    expect(LocalShopState.isOwned(LocalShopState.corePackId), isTrue);
    expect(LocalShopState.isOwned('redline'), isFalse);
    expect(await LocalShopState.equippedPack(), LocalShopState.corePackId);
  });

  test('locked paid pack cannot be equipped locally', () async {
    await LocalShopState.equip('redline');

    expect(await LocalShopState.equippedPack(), LocalShopState.corePackId);
  });

  test('owned core cosmetic persists when equipped', () async {
    await LocalShopState.equip(LocalShopState.corePackId);

    expect(await LocalShopState.equippedPack(), LocalShopState.corePackId);
  });
}
