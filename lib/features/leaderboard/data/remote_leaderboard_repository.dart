import '../../../core/backend/react_supabase.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/leaderboard_query.dart';
import '../domain/leaderboard_snapshot.dart';
import 'leaderboard_repository.dart';
import 'local_leaderboard_repository.dart';

class RemoteLeaderboardRepository implements LeaderboardRepository {
  const RemoteLeaderboardRepository({
    this.fallback = const LocalLeaderboardRepository(),
  });

  final LeaderboardRepository fallback;

  @override
  Future<LeaderboardSnapshot> load(LeaderboardQuery query) async {
    final client = ReactSupabase.client;
    if (client == null) return fallback.load(query);

    try {
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
    } catch (_) {
      return fallback.load(query);
    }
  }

  Future<List<Map<String, dynamic>>> _loadGlobalRows(
    dynamic client,
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
    return _rows(response);
  }

  Future<List<Map<String, dynamic>>> _loadDailyRows(
    dynamic client,
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
    return _rows(response);
  }

  static List<Map<String, dynamic>> _rows(dynamic response) =>
      (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

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
