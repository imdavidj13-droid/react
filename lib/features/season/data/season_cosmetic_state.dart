import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cosmetics/react_cosmetics.dart';
import '../domain/season_models.dart';

/// Single ownership/catalog/equipment state for RE△CT cosmetics.
///
/// Season Pass is the acquisition path and Locker is the equipment UI.
/// ReactCosmetics remains the low-level renderer/persistence implementation for
/// built-in gameplay packs, but there is no separate Shop ownership model.
abstract final class SeasonCosmeticState {
  static const _ownedKey = 'season_cosmetics_owned';
  static const _catalogKey = 'season_cosmetics_catalog';
  static const _equippedPrefix = 'season_cosmetics_equipped_';

  static final Set<String> _ownedKeys = <String>{};
  static final Map<String, SeasonReward> _catalog = <String, SeasonReward>{};
  static final Map<String, String> _equippedByKind = <String, String>{};

  /// Only season-native families with a real connected renderer belong here.
  /// Future categories such as arena themes, HUD skins, particles and true
  /// in-run Reaction Packs remain unlockable in backend configuration but are
  /// intentionally NOT equippable until every intended destination consumes
  /// them.
  static const Set<String> _seasonNativeKinds = <String>{
    'profile_frame',
    'profile_badge',
    'player_code_style',
    'home_theme',
    'home_background',
    'score_effect',
    'result_score_style',
    'success_effect',
    'result_success_style',
    'failure_effect',
    'result_failure_style',
    'mode_card_skin',
    'title',
    'emblem',
  };

  static Future<void> load() async {
    await ReactCosmetics.load();
    final prefs = await SharedPreferences.getInstance();
    _ownedKeys
      ..clear()
      ..addAll(prefs.getStringList(_ownedKey) ?? const <String>[]);

    _catalog.clear();
    final rawCatalog = prefs.getStringList(_catalogKey) ?? const <String>[];
    final validCatalog = <String>[];
    for (final raw in rawCatalog) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final reward = _fromJson(json);
        _catalog[reward.rewardKey] = reward;
        validCatalog.add(raw);
      } catch (_) {
        // Drop corrupt cached cosmetic rows individually.
      }
    }
    if (validCatalog.length != rawCatalog.length) {
      await prefs.setStringList(_catalogKey, validCatalog);
    }

    _equippedByKind.clear();
    for (final kind in _seasonNativeKinds) {
      final prefKey = '$_equippedPrefix$kind';
      final value = prefs.getString(prefKey);
      if (value == null) continue;
      if (_ownedKeys.contains(value)) {
        _equippedByKind[kind] = value;
      } else {
        await prefs.remove(prefKey);
      }
    }

    // Remove abandoned season-native equipment keys for unsupported kinds.
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_equippedPrefix)) continue;
      final kind = key.substring(_equippedPrefix.length);
      if (!_seasonNativeKinds.contains(kind)) {
        await prefs.remove(key);
      }
    }

    // If a Shop-era gameplay pack is equipped but no longer owned, safely
    // fall back to CORE. Existing ReactCosmetics preference keys are retained
    // only as low-level renderer state, not as a second entitlement system.
    if (ReactCosmetics.currentReactionPack != ReactReactionPack.core &&
        !_ownedKeys.contains(ReactCosmetics.currentReactionPack.packId)) {
      await ReactCosmetics.equipReactionPack(ReactReactionPack.core);
    }
    if (ReactCosmetics.currentCountdownStyle != ReactCountdownStyle.core &&
        !_ownedKeys.contains(ReactCosmetics.currentCountdownStyle.packId)) {
      await ReactCosmetics.equipCountdownStyle(ReactCountdownStyle.core);
    }
    if (ReactCosmetics.currentSoundPack != ReactSoundPack.core &&
        !_ownedKeys.contains(ReactCosmetics.currentSoundPack.packId)) {
      await ReactCosmetics.equipSoundPack(ReactSoundPack.core);
    }
    if (ReactCosmetics.currentCommandStyle != ReactCommandStyle.core &&
        !_ownedKeys.contains(ReactCosmetics.currentCommandStyle.packId)) {
      await ReactCosmetics.equipCommandStyle(ReactCommandStyle.core);
    }
    if (ReactCosmetics.currentShareStyle != ReactShareStyle.core &&
        !_ownedKeys.contains(ReactCosmetics.currentShareStyle.packId)) {
      await ReactCosmetics.equipShareStyle(ReactShareStyle.core);
    }
  }

  static Future<void> syncSnapshot(SeasonSnapshot snapshot) async {
    _ownedKeys.addAll(snapshot.unlockedRewardKeys);
    for (final tier in snapshot.tiers) {
      for (final reward in tier.rewards) {
        _catalog[reward.rewardKey] = reward;
      }
    }
    await _persist();
  }

  /// Rehydrates permanent ownership and metadata across every historical
  /// season. This makes Locker a lifetime collection on a new device.
  static Future<void> syncOwnedRewards(Iterable<SeasonReward> rewards) async {
    for (final reward in rewards) {
      _ownedKeys.add(reward.rewardKey);
      _catalog[reward.rewardKey] = reward;
    }
    await _persist();
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ownedKey, _ownedKeys.toList()..sort());
    await prefs.setStringList(
      _catalogKey,
      _catalog.values.map(_encode).toList(growable: false),
    );
  }

  static bool isOwned(String rewardKey) => _ownedKeys.contains(rewardKey);

  static List<SeasonReward> get ownedRewards {
    final rewards = <SeasonReward>[
      for (final key in _ownedKeys)
        if (_catalog[key] case final reward?) reward,
    ];
    rewards.sort((a, b) {
      final tierOrder = a.tier.compareTo(b.tier);
      if (tierOrder != 0) return tierOrder;
      return a.name.compareTo(b.name);
    });
    return List<SeasonReward>.unmodifiable(rewards);
  }

  static bool isEquippable(SeasonReward reward) {
    if (_seasonNativeKinds.contains(reward.kind)) return true;
    return switch (reward.kind) {
      'reaction_pack' || 'gameplay_theme' =>
        ReactReactionPack.fromPackId(reward.rewardKey) != null,
      'countdown_style' =>
        ReactCountdownStyle.fromPackId(reward.rewardKey) != null,
      'sound_pack' => ReactSoundPack.fromPackId(reward.rewardKey) != null,
      'command_style' || 'command_pack' =>
        ReactCommandStyle.fromPackId(reward.rewardKey) != null,
      'share_style' || 'share_card' =>
        ReactShareStyle.fromPackId(reward.rewardKey) != null,
      _ => false,
    };
  }

  static bool isEquipped(SeasonReward reward) => switch (reward.kind) {
        'reaction_pack' || 'gameplay_theme' =>
          ReactCosmetics.currentReactionPack.packId == reward.rewardKey,
        'countdown_style' =>
          ReactCosmetics.currentCountdownStyle.packId == reward.rewardKey,
        'sound_pack' => ReactCosmetics.currentSoundPack.packId == reward.rewardKey,
        'command_style' || 'command_pack' =>
          ReactCosmetics.currentCommandStyle.packId == reward.rewardKey,
        'share_style' || 'share_card' =>
          ReactCosmetics.currentShareStyle.packId == reward.rewardKey,
        _ => equippedKey(reward.kind) == reward.rewardKey,
      };

  static String? equippedKey(String kind) => switch (kind) {
        'reaction_pack' || 'gameplay_theme' =>
          ReactCosmetics.currentReactionPack == ReactReactionPack.core
              ? null
              : ReactCosmetics.currentReactionPack.packId,
        'countdown_style' =>
          ReactCosmetics.currentCountdownStyle == ReactCountdownStyle.core
              ? null
              : ReactCosmetics.currentCountdownStyle.packId,
        'sound_pack' => ReactCosmetics.currentSoundPack == ReactSoundPack.core
            ? null
            : ReactCosmetics.currentSoundPack.packId,
        'command_style' || 'command_pack' =>
          ReactCosmetics.currentCommandStyle == ReactCommandStyle.core
              ? null
              : ReactCosmetics.currentCommandStyle.packId,
        'share_style' || 'share_card' =>
          ReactCosmetics.currentShareStyle == ReactShareStyle.core
              ? null
              : ReactCosmetics.currentShareStyle.packId,
        'home_theme' || 'home_background' =>
          _equippedByKind['home_background'] ?? _equippedByKind['home_theme'],
        'score_effect' || 'result_score_style' =>
          _equippedByKind['result_score_style'] ?? _equippedByKind['score_effect'],
        'success_effect' || 'result_success_style' =>
          _equippedByKind['result_success_style'] ?? _equippedByKind['success_effect'],
        'failure_effect' || 'result_failure_style' =>
          _equippedByKind['result_failure_style'] ?? _equippedByKind['failure_effect'],
        _ => _equippedByKind[kind],
      };

  static SeasonReward? equippedReward(String kind) {
    final key = equippedKey(kind);
    return key == null ? null : _catalog[key];
  }

  static Future<bool> equip(SeasonReward reward) async {
    if (!isOwned(reward.rewardKey) || !isEquippable(reward)) return false;

    switch (reward.kind) {
      case 'reaction_pack' || 'gameplay_theme':
        final value = ReactReactionPack.fromPackId(reward.rewardKey);
        if (value == null) return false;
        await ReactCosmetics.equipReactionPack(value);
        return true;
      case 'countdown_style':
        final value = ReactCountdownStyle.fromPackId(reward.rewardKey);
        if (value == null) return false;
        await ReactCosmetics.equipCountdownStyle(value);
        return true;
      case 'sound_pack':
        final value = ReactSoundPack.fromPackId(reward.rewardKey);
        if (value == null) return false;
        await ReactCosmetics.equipSoundPack(value);
        return true;
      case 'command_style' || 'command_pack':
        final value = ReactCommandStyle.fromPackId(reward.rewardKey);
        if (value == null) return false;
        await ReactCosmetics.equipCommandStyle(value);
        return true;
      case 'share_style' || 'share_card':
        final value = ReactShareStyle.fromPackId(reward.rewardKey);
        if (value == null) return false;
        await ReactCosmetics.equipShareStyle(value);
        return true;
      default:
        final prefs = await SharedPreferences.getInstance();
        for (final familyKind in _nativeFamilyKinds(reward.kind)) {
          _equippedByKind.remove(familyKind);
          await prefs.remove('$_equippedPrefix$familyKind');
        }
        _catalog[reward.rewardKey] = reward;
        _equippedByKind[reward.kind] = reward.rewardKey;
        await prefs.setString('$_equippedPrefix${reward.kind}', reward.rewardKey);
        return true;
    }
  }

  static Future<void> clearKind(String kind) async {
    switch (kind) {
      case 'reaction_pack' || 'gameplay_theme':
        await ReactCosmetics.equipReactionPack(ReactReactionPack.core);
        return;
      case 'countdown_style':
        await ReactCosmetics.equipCountdownStyle(ReactCountdownStyle.core);
        return;
      case 'sound_pack':
        await ReactCosmetics.equipSoundPack(ReactSoundPack.core);
        return;
      case 'command_style' || 'command_pack':
        await ReactCosmetics.equipCommandStyle(ReactCommandStyle.core);
        return;
      case 'share_style' || 'share_card':
        await ReactCosmetics.equipShareStyle(ReactShareStyle.core);
        return;
      default:
        final prefs = await SharedPreferences.getInstance();
        for (final familyKind in _nativeFamilyKinds(kind)) {
          _equippedByKind.remove(familyKind);
          await prefs.remove('$_equippedPrefix$familyKind');
        }
    }
  }

  static Set<String> _nativeFamilyKinds(String kind) => switch (kind) {
        'home_theme' || 'home_background' =>
          const <String>{'home_theme', 'home_background'},
        'score_effect' || 'result_score_style' =>
          const <String>{'score_effect', 'result_score_style'},
        'success_effect' || 'result_success_style' =>
          const <String>{'success_effect', 'result_success_style'},
        'failure_effect' || 'result_failure_style' =>
          const <String>{'failure_effect', 'result_failure_style'},
        _ => <String>{kind},
      };

  static String _encode(SeasonReward reward) => jsonEncode(<String, dynamic>{
        'id': reward.id,
        'tier': reward.tier,
        'track': reward.track.name,
        'kind': reward.kind,
        'reward_key': reward.rewardKey,
        'name': reward.name,
        'description': reward.description,
        'milestone': reward.milestone,
        'payload': reward.payload,
      });

  static SeasonReward _fromJson(Map<String, dynamic> json) => SeasonReward(
        id: '${json['id']}',
        tier: (json['tier'] as num?)?.round() ?? 0,
        track: '${json['track']}' == 'premium'
            ? SeasonRewardTrack.premium
            : SeasonRewardTrack.free,
        kind: '${json['kind']}',
        rewardKey: '${json['reward_key']}',
        name: '${json['name']}',
        description: '${json['description'] ?? ''}',
        milestone: json['milestone'] == true,
        payload: json['payload'] is Map
            ? (json['payload'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{},
      );
}
