import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/season_models.dart';

/// Local equipment state for season-only cosmetic families.
///
/// Server-awarded unlock rows are permanent. This cache accumulates verified
/// unlocks so earned cosmetics remain usable offline and across later seasons,
/// while equipment choices remain local to the device.
abstract final class SeasonCosmeticState {
  static const _ownedKey = 'season_cosmetics_owned';
  static const _catalogKey = 'season_cosmetics_catalog';
  static const _equippedPrefix = 'season_cosmetics_equipped_';

  static final Set<String> _ownedKeys = <String>{};
  static final Map<String, SeasonReward> _catalog = <String, SeasonReward>{};
  static final Map<String, String> _equippedByKind = <String, String>{};

  /// Only cosmetic families with a real, visible renderer belong here.
  ///
  /// Do not add a kind simply because the backend can award it. A reward must
  /// have a connected presentation surface before the locker is allowed to
  /// report it as EQUIPPED.
  static const Set<String> equippableKinds = <String>{
    'profile_frame',
    'profile_badge',
    'player_code_style',
    'home_theme',
    'score_effect',
    'success_effect',
    'failure_effect',
    'mode_card_skin',
    'title',
    'emblem',
  };

  static Future<void> load() async {
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
        // Corrupt cached cosmetic rows are dropped individually.
      }
    }
    if (validCatalog.length != rawCatalog.length) {
      await prefs.setStringList(_catalogKey, validCatalog);
    }

    _equippedByKind.clear();
    for (final kind in equippableKinds) {
      final key = '$_equippedPrefix$kind';
      final value = prefs.getString(key);
      if (value == null) continue;
      if (_ownedKeys.contains(value)) {
        _equippedByKind[kind] = value;
      } else {
        await prefs.remove(key);
      }
    }

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_equippedPrefix)) continue;
      final kind = key.substring(_equippedPrefix.length);
      if (!equippableKinds.contains(kind)) {
        await prefs.remove(key);
      }
    }
  }

  static Future<void> syncSnapshot(SeasonSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    _ownedKeys.addAll(snapshot.unlockedRewardKeys);

    for (final tier in snapshot.tiers) {
      for (final reward in tier.rewards) {
        if (equippableKinds.contains(reward.kind)) {
          _catalog[reward.rewardKey] = reward;
        }
      }
    }

    await prefs.setStringList(_ownedKey, _ownedKeys.toList()..sort());
    await prefs.setStringList(
      _catalogKey,
      _catalog.values.map(_encode).toList(growable: false),
    );
  }

  static bool isOwned(String rewardKey) => _ownedKeys.contains(rewardKey);

  static bool isEquippable(SeasonReward reward) =>
      equippableKinds.contains(reward.kind);

  static bool isEquipped(SeasonReward reward) =>
      _equippedByKind[reward.kind] == reward.rewardKey;

  static String? equippedKey(String kind) => _equippedByKind[kind];

  static SeasonReward? equippedReward(String kind) {
    final key = equippedKey(kind);
    return key == null ? null : _catalog[key];
  }

  static Future<bool> equip(SeasonReward reward) async {
    if (!isEquippable(reward) || !isOwned(reward.rewardKey)) return false;
    _catalog[reward.rewardKey] = reward;
    _equippedByKind[reward.kind] = reward.rewardKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_equippedPrefix${reward.kind}', reward.rewardKey);
    return true;
  }

  static Future<void> clearKind(String kind) async {
    _equippedByKind.remove(kind);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_equippedPrefix$kind');
  }

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
