import 'package:shared_preferences/shared_preferences.dart';

/// Local cosmetic ownership/equipment state.
///
/// Paid packs are deliberately not unlockable here. A future store service can
/// grant ownership after verified platform purchases without changing the Shop
/// UI contract.
abstract final class LocalShopState {
  static const _equippedPackKey = 'shop_equipped_pack';
  static const corePackId = 'core';

  static const Set<String> _builtInOwnedPacks = {corePackId};

  static Future<String> equippedPack() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_equippedPackKey);
    if (saved == null || !_builtInOwnedPacks.contains(saved)) {
      return corePackId;
    }
    return saved;
  }

  static bool isOwned(String packId) => _builtInOwnedPacks.contains(packId);

  static Future<void> equip(String packId) async {
    if (!isOwned(packId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedPackKey, packId);
  }
}
