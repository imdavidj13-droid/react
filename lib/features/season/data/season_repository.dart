import 'package:flutter/foundation.dart';

import '../../../core/backend/react_supabase.dart';
import '../../shop/data/local_shop_state.dart';
import '../domain/season_models.dart';
import 'season_cosmetic_state.dart';

class SeasonRunRecord {
  const SeasonRunRecord({
    required this.snapshot,
    required this.chargeEarned,
  });

  final SeasonSnapshot snapshot;
  final int chargeEarned;
}

class SeasonRepository {
  const SeasonRepository();

  Future<SeasonSnapshot?> loadActiveSeason() async {
    final client = ReactSupabase.client;
    if (client == null) return null;

    if (client.auth.currentSession == null) {
      final ready = await ReactSupabase.ensurePlayerSession();
      if (!ready) return null;
    }

    try {
      final response = await client.rpc('get_react_active_season');
      final data = _asMap(response);
      if (data == null) return null;
      final snapshot = _withDebugPremium(_parseSnapshot(data));
      await _syncCosmetics(snapshot);
      return snapshot;
    } catch (error) {
      debugPrint('RE△CT season load failed: $error');
      return null;
    }
  }

  Future<SeasonSnapshot?> recordRun({
    required String eventId,
    required String mode,
    required int score,
    required int successfulCommands,
    required bool isPersonalBest,
    String? dailyModifier,
    required DateTime completedAt,
  }) async {
    final record = await recordRunWithAward(
      eventId: eventId,
      mode: mode,
      score: score,
      successfulCommands: successfulCommands,
      isPersonalBest: isPersonalBest,
      dailyModifier: dailyModifier,
      completedAt: completedAt,
    );
    return record?.snapshot;
  }

  Future<SeasonRunRecord?> recordRunWithAward({
    required String eventId,
    required String mode,
    required int score,
    required int successfulCommands,
    required bool isPersonalBest,
    String? dailyModifier,
    required DateTime completedAt,
  }) async {
    final client = ReactSupabase.client;
    if (client == null || client.auth.currentSession == null) return null;

    try {
      final response = await client.rpc(
        'record_react_season_run',
        params: <String, dynamic>{
          'p_event_id': eventId,
          'p_mode': mode,
          'p_score': score,
          'p_successful_commands': successfulCommands,
          'p_is_personal_best': isPersonalBest,
          'p_daily_modifier': dailyModifier,
          'p_completed_at': completedAt.toUtc().toIso8601String(),
        },
      );
      final data = _asMap(response);
      if (data == null) return null;
      final snapshot = _withDebugPremium(_parseSnapshot(data));
      await _syncCosmetics(snapshot);
      return SeasonRunRecord(
        snapshot: snapshot,
        chargeEarned: _asInt(data['charge_earned']),
      );
    } catch (error) {
      debugPrint('RE△CT season run progress failed: $error');
      return null;
    }
  }

  static Future<void> _syncCosmetics(SeasonSnapshot snapshot) async {
    await LocalShopState.setSeasonOwnedPackIds(snapshot.unlockedRewardKeys);
    await SeasonCosmeticState.syncSnapshot(snapshot);
  }

  /// Debug builds treat Premium as active so the full pass can be tested
  /// without a store purchase. Only Premium rewards from tiers the player has
  /// actually reached are added to the local entitlement snapshot.
  ///
  /// Release/profile builds always use the server-owned premium entitlement.
  static SeasonSnapshot _withDebugPremium(SeasonSnapshot snapshot) {
    if (!kDebugMode) return snapshot;

    final unlocked = <String>{...snapshot.unlockedRewardKeys};
    for (final tier in snapshot.tiers) {
      if (snapshot.charge < tier.chargeRequired) continue;
      for (final reward in tier.rewards) {
        if (reward.isPremium) unlocked.add(reward.rewardKey);
      }
    }

    return SeasonSnapshot(
      id: snapshot.id,
      code: snapshot.code,
      name: snapshot.name,
      subtitle: snapshot.subtitle,
      themeKey: snapshot.themeKey,
      startsAt: snapshot.startsAt,
      endsAt: snapshot.endsAt,
      charge: snapshot.charge,
      premiumOwned: true,
      tiers: snapshot.tiers,
      missions: snapshot.missions,
      unlockedRewardKeys: unlocked,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    if (value is List && value.isNotEmpty) return _asMap(value.first);
    return null;
  }

  static SeasonSnapshot _parseSnapshot(Map<String, dynamic> json) {
    final tiers = <SeasonTier>[];
    for (final rawTier in _asList(json['tiers'])) {
      final tier = _asMap(rawTier);
      if (tier == null) continue;
      final rewards = <SeasonReward>[];
      for (final rawReward in _asList(tier['rewards'])) {
        final reward = _asMap(rawReward);
        if (reward == null) continue;
        rewards.add(
          SeasonReward(
            id: '${reward['id']}',
            tier: _asInt(reward['tier']),
            track: '${reward['track']}' == 'premium'
                ? SeasonRewardTrack.premium
                : SeasonRewardTrack.free,
            kind: '${reward['kind']}',
            rewardKey: '${reward['reward_key']}',
            name: '${reward['name']}',
            description: '${reward['description'] ?? ''}',
            milestone: reward['milestone'] == true,
            payload: _asMap(reward['payload']) ?? const <String, dynamic>{},
          ),
        );
      }
      tiers.add(
        SeasonTier(
          number: _asInt(tier['number']),
          chargeRequired: _asInt(tier['charge_required']),
          milestone: tier['milestone'] == true,
          rewards: rewards,
        ),
      );
    }
    tiers.sort((a, b) => a.number.compareTo(b.number));

    final missions = <SeasonMission>[];
    for (final rawMission in _asList(json['missions'])) {
      final mission = _asMap(rawMission);
      if (mission == null) continue;
      final cadence = switch ('${mission['cadence']}') {
        'weekly' => SeasonMissionCadence.weekly,
        'season' => SeasonMissionCadence.season,
        _ => SeasonMissionCadence.daily,
      };
      missions.add(
        SeasonMission(
          id: '${mission['id']}',
          cadence: cadence,
          metric: '${mission['metric']}',
          name: '${mission['name']}',
          description: '${mission['description'] ?? ''}',
          target: _asInt(mission['target']),
          progress: _asInt(mission['progress']),
          chargeReward: _asInt(mission['charge_reward']),
          periodKey: '${mission['period_key'] ?? ''}',
          completed: mission['completed'] == true,
        ),
      );
    }

    return SeasonSnapshot(
      id: '${json['id']}',
      code: '${json['code']}',
      name: '${json['name']}',
      subtitle: '${json['subtitle'] ?? ''}',
      themeKey: '${json['theme_key']}',
      startsAt: DateTime.parse('${json['starts_at']}').toUtc(),
      endsAt: DateTime.parse('${json['ends_at']}').toUtc(),
      charge: _asInt(json['charge']),
      premiumOwned: json['premium_owned'] == true,
      tiers: tiers,
      missions: missions,
      unlockedRewardKeys: {
        for (final value in _asList(json['unlocked_reward_keys'])) '$value',
      },
    );
  }

  static List<dynamic> _asList(dynamic value) =>
      value is List ? value : const <dynamic>[];

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }
}
