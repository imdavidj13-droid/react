import 'package:flutter/foundation.dart';

import '../../../core/backend/react_supabase.dart';
import '../../shop/data/local_shop_state.dart';
import '../domain/season_models.dart';
import 'season_cosmetic_state.dart';

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
      final snapshot = _parseSnapshot(data);
      await _syncCosmetics(snapshot);
      return snapshot;
    } catch (error) {
      debugPrint('RE△CT season load failed: $error');
      return null;
    }
  }

  Future<SeasonSnapshot?> recordRun({
    required String eventId,
    required int score,
    required int successfulCommands,
    required bool isPersonalBest,
    required bool isDaily,
  }) async {
    final client = ReactSupabase.client;
    if (client == null || client.auth.currentSession == null) return null;

    try {
      final response = await client.rpc(
        'record_react_season_run',
        params: <String, dynamic>{
          'p_event_id': eventId,
          'p_score': score,
          'p_successful_commands': successfulCommands,
          'p_is_personal_best': isPersonalBest,
          'p_is_daily': isDaily,
        },
      );
      final data = _asMap(response);
      if (data == null) return null;
      final snapshot = _parseSnapshot(data);
      await _syncCosmetics(snapshot);
      return snapshot;
    } catch (error) {
      debugPrint('RE△CT season run progress failed: $error');
      return null;
    }
  }

  static Future<void> _syncCosmetics(SeasonSnapshot snapshot) async {
    await LocalShopState.setSeasonOwnedPackIds(snapshot.unlockedRewardKeys);
    await SeasonCosmeticState.syncSnapshot(snapshot);
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
