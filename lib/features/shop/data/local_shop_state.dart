import 'package:flutter/foundation.dart';

import '../../../core/cosmetics/react_cosmetics.dart';

/// Local cosmetic ownership/equipment state.
///
/// Release builds only own CORE until a future verified store entitlement
/// grants a paid cosmetic. Debug builds deliberately unlock the implemented
/// visual themes so they can be tested on-device before billing exists.
abstract final class LocalShopState {
  static const corePackId = 'core';
  static const redlinePackId = 'redline';
  static const synthwavePackId = 'synthwave';
  static const monoPackId = 'mono';

  static const Set<String> _builtInOwnedPacks = {corePackId};
  static const Set<String> _implementedVisualPacks = {
    corePackId,
    redlinePackId,
    synthwavePackId,
    monoPackId,
  };

  static bool get debugVisualUnlocksEnabled => kDebugMode;

  static Future<void> load() => ReactCosmetics.load();

  static Future<String> equippedPack() async =>
      ReactCosmetics.currentTheme.packId;

  static bool isOwned(String packId) {
    if (_builtInOwnedPacks.contains(packId)) return true;
    return kDebugMode && _implementedVisualPacks.contains(packId);
  }

  static bool isImplementedVisualPack(String packId) =>
      _implementedVisualPacks.contains(packId);

  static Future<void> equip(String packId) async {
    if (!isOwned(packId) || !isImplementedVisualPack(packId)) return;
    final theme = ReactVisualTheme.fromPackId(packId);
    if (theme == null) return;
    await ReactCosmetics.equipTheme(theme);
  }
}
