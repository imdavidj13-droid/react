import 'package:flutter/foundation.dart';

import '../../../core/cosmetics/react_cosmetics.dart';

/// Local cosmetic ownership/equipment state.
///
/// Release builds only own CORE until future verified store entitlements grant
/// paid cosmetics. Debug builds deliberately unlock implemented cosmetics so
/// every pack can be tested end-to-end before billing exists.
abstract final class LocalShopState {
  static const corePackId = 'core';
  static const redlinePackId = 'redline';
  static const synthwavePackId = 'synthwave';
  static const monoPackId = 'mono';
  static const greenlinePackId = 'greenline';
  static const voltagePackId = 'voltage';
  static const emberPackId = 'ember';
  static const hotPinkPackId = 'hot_pink';

  static const ringsCountdownPackId = 'rings_countdown';
  static const cardsCountdownPackId = 'cards_countdown';
  static const terminalCountdownPackId = 'terminal_countdown';
  static const pulseCountdownPackId = 'pulse_countdown';

  static const arcadeSfxPackId = 'arcade_sfx';
  static const pulseSfxPackId = 'pulse_sfx';
  static const bassSfxPackId = 'bass_sfx';
  static const minimalSfxPackId = 'minimal_sfx';
  static const laserSfxPackId = 'laser_sfx';

  static const glitchCommandsPackId = 'glitch_commands';
  static const terminalCommandsPackId = 'terminal_commands';
  static const arcadeCommandsPackId = 'arcade_commands';
  static const minimalCommandsPackId = 'minimal_commands';
  static const impactCommandsPackId = 'impact_commands';

  static const proShareCardsPackId = 'pro_share_cards';

  static const Set<String> _builtInOwnedPacks = {corePackId};
  static const Set<String> _implementedVisualPacks = {
    corePackId,
    redlinePackId,
    synthwavePackId,
    monoPackId,
    greenlinePackId,
    voltagePackId,
    emberPackId,
    hotPinkPackId,
  };
  static const Set<String> _implementedCountdownPacks = {
    ringsCountdownPackId,
    cardsCountdownPackId,
    terminalCountdownPackId,
    pulseCountdownPackId,
  };
  static const Set<String> _implementedAudioPacks = {
    arcadeSfxPackId,
    pulseSfxPackId,
    bassSfxPackId,
    minimalSfxPackId,
    laserSfxPackId,
  };
  static const Set<String> _implementedCommandStyles = {
    glitchCommandsPackId,
    terminalCommandsPackId,
    arcadeCommandsPackId,
    minimalCommandsPackId,
    impactCommandsPackId,
  };
  static const Set<String> _implementedShareStyles = {
    proShareCardsPackId,
  };

  static bool get debugUnlocksEnabled => kDebugMode;
  static bool get debugVisualUnlocksEnabled => kDebugMode;

  static Future<void> load() async {
    await ReactCosmetics.load();

    if (!isOwned(ReactCosmetics.currentReactionPack.packId)) {
      await ReactCosmetics.equipReactionPack(ReactReactionPack.core);
    }
    if (ReactCosmetics.currentCountdownStyle != ReactCountdownStyle.core &&
        !isOwned(ReactCosmetics.currentCountdownStyle.packId)) {
      await ReactCosmetics.equipCountdownStyle(ReactCountdownStyle.core);
    }
    if (ReactCosmetics.currentSoundPack != ReactSoundPack.core &&
        !isOwned(ReactCosmetics.currentSoundPack.packId)) {
      await ReactCosmetics.equipSoundPack(ReactSoundPack.core);
    }
    if (ReactCosmetics.currentCommandStyle != ReactCommandStyle.core &&
        !isOwned(ReactCosmetics.currentCommandStyle.packId)) {
      await ReactCosmetics.equipCommandStyle(ReactCommandStyle.core);
    }
    if (ReactCosmetics.currentShareStyle != ReactShareStyle.core &&
        !isOwned(ReactCosmetics.currentShareStyle.packId)) {
      await ReactCosmetics.equipShareStyle(ReactShareStyle.core);
    }
  }

  static Future<String> equippedPack() async =>
      ReactCosmetics.currentReactionPack.packId;

  static Future<Set<String>> equippedPackIds() async {
    final equipped = <String>{ReactCosmetics.currentReactionPack.packId};

    if (ReactCosmetics.currentCountdownStyle != ReactCountdownStyle.core) {
      equipped.add(ReactCosmetics.currentCountdownStyle.packId);
    }
    if (ReactCosmetics.currentSoundPack != ReactSoundPack.core) {
      equipped.add(ReactCosmetics.currentSoundPack.packId);
    }
    if (ReactCosmetics.currentCommandStyle != ReactCommandStyle.core) {
      equipped.add(ReactCosmetics.currentCommandStyle.packId);
    }
    if (ReactCosmetics.currentShareStyle != ReactShareStyle.core) {
      equipped.add(ReactCosmetics.currentShareStyle.packId);
    }
    return equipped;
  }

  static bool isOwned(String packId) {
    if (_builtInOwnedPacks.contains(packId)) return true;
    return kDebugMode && isImplemented(packId);
  }

  static bool isImplemented(String packId) =>
      _implementedVisualPacks.contains(packId) ||
      _implementedCountdownPacks.contains(packId) ||
      _implementedAudioPacks.contains(packId) ||
      _implementedCommandStyles.contains(packId) ||
      _implementedShareStyles.contains(packId);

  static bool isImplementedVisualPack(String packId) =>
      _implementedVisualPacks.contains(packId);

  static bool isImplementedCountdownPack(String packId) =>
      _implementedCountdownPacks.contains(packId);

  static bool isImplementedAudioPack(String packId) =>
      _implementedAudioPacks.contains(packId);

  static bool isImplementedCommandStyle(String packId) =>
      _implementedCommandStyles.contains(packId);

  static bool isImplementedShareStyle(String packId) =>
      _implementedShareStyles.contains(packId);

  static Future<void> equip(String packId) async {
    if (!isOwned(packId) || !isImplemented(packId)) return;

    if (isImplementedVisualPack(packId)) {
      final pack = ReactReactionPack.fromPackId(packId);
      if (pack != null) await ReactCosmetics.equipReactionPack(pack);
      return;
    }

    if (isImplementedCountdownPack(packId)) {
      final style = ReactCountdownStyle.fromPackId(packId);
      if (style != null) await ReactCosmetics.equipCountdownStyle(style);
      return;
    }

    if (isImplementedAudioPack(packId)) {
      final pack = ReactSoundPack.fromPackId(packId);
      if (pack != null) await ReactCosmetics.equipSoundPack(pack);
      return;
    }

    if (isImplementedCommandStyle(packId)) {
      final style = ReactCommandStyle.fromPackId(packId);
      if (style != null) await ReactCosmetics.equipCommandStyle(style);
      return;
    }

    if (packId == proShareCardsPackId) {
      await ReactCosmetics.equipShareStyle(ReactShareStyle.pro);
    }
  }

  static Future<void> equipCoreReactionPack() =>
      ReactCosmetics.equipReactionPack(ReactReactionPack.core);

  static Future<void> equipCoreCountdown() =>
      ReactCosmetics.equipCountdownStyle(ReactCountdownStyle.core);

  static Future<void> equipCoreAudio() =>
      ReactCosmetics.equipSoundPack(ReactSoundPack.core);

  static Future<void> equipCoreCommandStyle() =>
      ReactCosmetics.equipCommandStyle(ReactCommandStyle.core);

  static Future<void> equipCoreShareStyle() =>
      ReactCosmetics.equipShareStyle(ReactShareStyle.core);
}
