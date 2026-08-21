import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/season_models.dart';

/// Local ownership/catalog/equipment state for season cosmetics.
///
/// Server-awarded unlock rows are permanent. The local catalog accumulates
/// every reward metadata row seen from season snapshots and the lifetime
/// cosmetic RPC so old cosmetics stay browsable/equippable after season
/// rollover and on a clean reinstall.
abstract final class SeasonCosmeticState {
  static const _ownedKey = 'season_cosmetics_owned';
  static const _catalogKey = 'season_cosmetics_catalog';
  static const _equippedPrefix = 'season_cosmetics_equipped_';

  static final Set<String> _ownedKeys = <String>{};
  static final Map<String, SeasonReward> _catalog = <String, SeasonReward>{};
  static final Map<String, String> _equippedByKind = <String, String>{};

  /// Season-native families with real connected renderers. Legacy gameplay
  /// packs are still equipped through LocalShopState during migration, but are
  /// presented in the same Locker.
  static const Set<String> equippableKinds = <String>{
    'profile_frame',
    'profile_badge',
    'player_code_style',
    'home_theme',
    'home_background',
    'score_effect',
    'success_effect',
    'success_reaction',
    'failure_effect',
    'failure_reaction',
    'mode_card_skin',
    'title',
    'emblem',
    'arena_theme',
    'hud_style',
    'particle_pack',
    'result_card_style',
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
        // Drop corrupt cached cosmetic rows individually.
      }
    }
    if (validCatalog.length != rawCatalog.length) {
      await prefs.setStringList(_catalogKey, validCatalog);
    }

    _equippedByKind.clear();
    for (final kind in equippableKinds) {
      final prefKey = '$_equippedPrefix$kind';
      final value = prefs.getString(prefKey);
      if (value == null) continue;
      if (_ownedKeys.contains(value)) {
        _equippedByKind[kind] = value;
      } else {
        await prefs.remove(prefKey);
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
    _ownedKeys.addAll(snapshot.unlockedRewardKeys);

    // Cache ALL reward metadata, including locked rows. Once one later appears
    // in the unlock set its metadata is already available offline.
    for (final tier in snapshot.tiers) {
      for (final reward in tier.rewards) {
        _catalog[reward.rewardKey] = reward;
      }
    }

    await _persist();
  }

  /// Rehydrates permanent ownership and metadata across every historical
  /// season. This is what makes Locker a lifetime collection on a new device.
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
