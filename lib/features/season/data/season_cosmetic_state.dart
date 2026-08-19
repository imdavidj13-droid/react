import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/season_models.dart';

/// Local equipment state for season-only cosmetic families.
///
/// Ownership remains server-authoritative. This class only remembers which
/// already-unlocked cosmetic the player wants equipped and clears stale
/// selections when a server snapshot no longer contains the entitlement.
abstract final class SeasonCosmeticState {
  static const _ownedKey = 'season_cosmetics_owned';
  static const _catalogKey = 'season_cosmetics_catalog';
  static const _equippedPrefix = 'season_cosmetics_equipped_';

  static final Set<String> _ownedKeys = <String>{};
  static final Map<String, SeasonReward> _catalog = <String, SeasonReward>{};
  static final Map<String, String> _equippedByKind = <String, String>{};

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
    for (final raw in prefs.getStringList(_catalogKey) ?? const <String>[]) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final reward = _fromJson(json);
        _catalog[reward.rewardKey] = reward;
      } catch (_) {
        // Ignore corrupt cached cosmetic rows individually.
      }
    }

    _equippedByKind.clear();
    for (final kind in equippableKinds) {
      final value = prefs.getString('$_equippedPrefix$kind');
      if (value != null && _ownedKeys.contains(value)) {
        _equippedByKind[kind] = value;
      }
    }
  }

  static Future<void> syncSnapshot(SeasonSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    _ownedKeys
      ..clear()
      ..addAll(snapshot.unlockedRewardKeys);

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

    final staleKinds = <String>[];
    for (final entry in _equippedByKind.entries) {
      if (!_ownedKeys.contains(entry.value)) staleKinds.add(entry.key);
    }
    for (final kind in staleKinds) {
      _equippedByKind.remove(kind);
      await prefs.remove('$_equippedPrefix$kind');
    }
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
