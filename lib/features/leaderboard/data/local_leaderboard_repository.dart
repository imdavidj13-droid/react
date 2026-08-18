import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/react_supabase.dart';
import '../../daily/domain/daily_challenge.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_history_entry.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../player/data/local_player_profile.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/leaderboard_query.dart';
import '../domain/leaderboard_snapshot.dart';
import 'leaderboard_repository.dart';

class LocalLeaderboardRepository implements LeaderboardRepository {
  const LocalLeaderboardRepository();

  @override
  Future<LeaderboardSnapshot> load(LeaderboardQuery query) async {
    final client = ReactSupabase.client;
    if (client != null) {
      try {
        return await _loadRemote(client, query);
      } catch (_) {
        // Competitive data should never make the game unusable. Fall back to
        // the local preview whenever the network/backend is unavailable.
      }
    }
    return _loadLocal(query);
  }

  Future<LeaderboardSnapshot> _loadRemote(
    SupabaseClient client,
    LeaderboardQuery query,
  ) async {
    final currentPlayerId = client.auth.currentUser?.id;
    final rows = query.scope == LeaderboardScope.daily
        ? await _loadDailyRows(client, query)
        : await _loadGlobalRows(client, query);
    final entries = <LeaderboardEntry>[];
    int? currentPlayerRank;

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final playerId = '${row['player_id']}';
      final avatarPath = _clean(row['avatar_path']);
      final isCurrentPlayer =
          currentPlayerId != null && playerId == currentPlayerId;
      final rank = index + 1;
      if (isCurrentPlayer) currentPlayerRank = rank;

      entries.add(
        LeaderboardEntry(
          playerId: playerId,
          displayName: _clean(row['display_name']) ?? 'PLAYER',
          playerCode: _clean(row['player_code']),
          avatarUrl: avatarPath == null
              ? null
              : client.storage.from('player-avatars').getPublicUrl(avatarPath),
          score: _asInt(row['score']),
          isCurrentPlayer: isCurrentPlayer,
          rank: rank,
          averageReactionSeconds: _asDouble(row['average_reaction_seconds']),
          recordedAt: DateTime.tryParse('${row['completed_at']}'),
          dailyDate: query.scope == LeaderboardScope.daily
              ? DateTime.tryParse('${row['daily_date']}')
              : null,
          dailyModifierLabel: query.scope == LeaderboardScope.daily
              ? _clean(row['daily_modifier_label'])
              : null,
        ),
      );
    }

    return LeaderboardSnapshot(
      query: query,
      entries: entries,
      source: LeaderboardDataSource.remote,
      currentPlayerRank: currentPlayerRank,
    );
  }

  Future<List<Map<String, dynamic>>> _loadGlobalRows(
    SupabaseClient client,
    LeaderboardQuery query,
  ) async {
    final response = await client
        .from('leaderboard_global_best')
        .select(
          'player_id, display_name, player_code, avatar_path, mode, score, average_reaction_seconds, completed_at',
        )
        .eq('mode', query.mode.name)
        .order('score', ascending: false)
        .order('average_reaction_seconds')
        .order('completed_at')
        .limit(100);
    return response.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _loadDailyRows(
    SupabaseClient client,
    LeaderboardQuery query,
  ) async {
    final date = query.dailyDate ?? DateTime.now();
    final response = await client
        .from('leaderboard_daily_best')
        .select(
          'player_id, display_name, player_code, avatar_path, daily_date, daily_modifier_label, score, average_reaction_seconds, completed_at',
        )
        .eq('daily_date', _dateOnly(date))
        .order('score', ascending: false)
        .order('average_reaction_seconds')
        .order('completed_at')
        .limit(100);
    return response.cast<Map<String, dynamic>>();
  }

  Future<LeaderboardSnapshot> _loadLocal(LeaderboardQuery query) async {
    final score = query.scope == LeaderboardScope.daily
        ? await LocalPlayerStats.dailyBestToday()
        : await LocalPlayerStats.bestFor(query.mode);
    final recent = await LocalPlayerStats.recentRuns();
    final entries = <LeaderboardEntry>[];

    if (score > 0) {
      DateTime? dailyDate;
      String? dailyModifierLabel;
      ReactRunHistoryEntry? matchingRun;

      if (query.scope == LeaderboardScope.daily) {
        final source = query.dailyDate ?? DateTime.now();
        dailyDate = DateTime(source.year, source.month, source.day);
        dailyModifierLabel = DailyChallenge.forDate(dailyDate).modifier.label;
        matchingRun = recent
            .where(
              (run) =>
                  run.mode == ReactGameMode.daily &&
                  run.score == score &&
                  run.dailyDate != null &&
                  _sameDay(run.dailyDate!, dailyDate!),
            )
            .firstOrNull;
      } else {
        matchingRun = recent
            .where((run) => run.mode == query.mode && run.score == score)
            .firstOrNull;
      }

      final localId = LocalPlayerProfile.localId.isEmpty
          ? 'local-player'
          : LocalPlayerProfile.localId;
      entries.add(
        LeaderboardEntry(
          playerId: localId,
          displayName: LocalPlayerProfile.displayName,
          playerCode: LocalPlayerProfile.playerCodeFor(localId),
          avatarUrl: LocalPlayerProfile.avatarUrl,
          score: score,
          isCurrentPlayer: true,
          rank: 1,
          averageReactionSeconds: matchingRun != null &&
                  matchingRun.averageTimeSeconds > 0
              ? matchingRun.averageTimeSeconds
              : null,
          recordedAt: matchingRun?.playedAt,
          dailyDate: dailyDate,
          dailyModifierLabel:
              matchingRun?.dailyModifierLabel ?? dailyModifierLabel,
        ),
      );
    }

    return LeaderboardSnapshot(
      query: query,
      entries: entries,
      source: LeaderboardDataSource.localPreview,
      currentPlayerRank: entries.isEmpty ? null : 1,
    );
  }

  static bool supportsMode(ReactGameMode mode) => mode != ReactGameMode.passIt;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String? _clean(dynamic value) {
    if (value == null) return null;
    final cleaned = '$value'.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static String _dateOnly(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
