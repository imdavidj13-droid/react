import 'package:flutter/foundation.dart';

import '../../../core/cosmetics/react_cosmetics.dart';

/// Local cosmetic ownership/equipment state.
///
/// Release builds only own CORE until future verified store entitlements grant
/// paid cosmetics. Debug builds deliberately unlock implemented cosmetics so
/// they can be tested on-device before billing exists.
abstract final class LocalShopState {
  static const corePackId = 'core';
  static const redlinePackId = 'redline';
  static const synthwavePackId = 'synthwave';
  static const monoPackId = 'mono';
  static const arcadeSfxPackId = 'arcade_sfx';
  static const glitchCommandsPackId = 'glitch_commands';
  static const proShareCardsPackId = 'pro_share_cards';

  static const Set<String> _builtInOwnedPacks = {corePackId};
  static const Set<String> _implementedVisualPacks = {
    corePackId,
    redlinePackId,
    synthwavePackId,
    monoPackId,
  };
  static const Set<String> _implementedAudioPacks = {
    arcadeSfxPackId,
  };
  static const Set<String> _implementedCommandStyles = {
    glitchCommandsPackId,
  };
  static const Set<String> _implementedShareStyles = {
    proShareCardsPackId,
  };

  static bool get debugUnlocksEnabled => kDebugMode;
  static bool get debugVisualUnlocksEnabled => kDebugMode;

  static Future<void> load() => ReactCosmetics.load();

  static Future<String> equippedPack() async => ReactCosmetics.currentTheme.packId;

  static Future<Set<String>> equippedPackIds() async {
    final equipped = <String>{ReactCosmetics.currentTheme.packId};
    if (ReactCosmetics.currentSoundPack == ReactSoundPack.arcade) {
      equipped.add(arcadeSfxPackId);
    }
    if (ReactCosmetics.currentCommandStyle == ReactCommandStyle.glitch) {
      equipped.add(glitchCommandsPackId);
    }
    if (ReactCosmetics.currentShareStyle == ReactShareStyle.pro) {
      equipped.add(proShareCardsPackId);
    }
    return equipped;
  }

  static bool isOwned(String packId) {
    if (_builtInOwnedPacks.contains(packId)) return true;
    return kDebugMode && isImplemented(packId);
  }

  static bool isImplemented(String packId) =>
      _implementedVisualPacks.contains(packId) ||
      _implementedAudioPacks.contains(packId) ||
      _implementedCommandStyles.contains(packId) ||
      _implementedShareStyles.contains(packId);

  static bool isImplementedVisualPack(String packId) =>
      _implementedVisualPacks.contains(packId);

  static bool isImplementedAudioPack(String packId) =>
      _implementedAudioPacks.contains(packId);

  static bool isImplementedCommandStyle(String packId) =>
      _implementedCommandStyles.contains(packId);

  static bool isImplementedShareStyle(String packId) =>
      _implementedShareStyles.contains(packId);

  static Future<void> equip(String packId) async {
    if (!isOwned(packId) || !isImplemented(packId)) return;

    if (isImplementedVisualPack(packId)) {
      final theme = ReactVisualTheme.fromPackId(packId);
      if (theme != null) await ReactCosmetics.equipTheme(theme);
      return;
    }

    if (packId == arcadeSfxPackId) {
      await ReactCosmetics.equipSoundPack(ReactSoundPack.arcade);
      return;
    }

    if (packId == glitchCommandsPackId) {
      await ReactCosmetics.equipCommandStyle(ReactCommandStyle.glitch);
      return;
    }

    if (packId == proShareCardsPackId) {
      await ReactCosmetics.equipShareStyle(ReactShareStyle.pro);
    }
  }

  static Future<void> equipCoreAudio() =>
      ReactCosmetics.equipSoundPack(ReactSoundPack.core);

  static Future<void> equipCoreCommandStyle() =>
      ReactCosmetics.equipCommandStyle(ReactCommandStyle.core);

  static Future<void> equipCoreShareStyle() =>
      ReactCosmetics.equipShareStyle(ReactShareStyle.core);
}
