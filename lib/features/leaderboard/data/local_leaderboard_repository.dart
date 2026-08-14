import '../../daily/domain/daily_challenge.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/leaderboard_query.dart';
import '../domain/leaderboard_snapshot.dart';
import 'leaderboard_repository.dart';

class LocalLeaderboardRepository implements LeaderboardRepository {
  const LocalLeaderboardRepository();

  static const _localPlayerId = 'local-player';

  @override
  Future<LeaderboardSnapshot> load(LeaderboardQuery query) async {
    final score = query.scope == LeaderboardScope.daily
        ? await LocalPlayerStats.dailyBestToday()
        : await LocalPlayerStats.bestFor(query.mode);

    final average = await LocalPlayerStats.averageReactionSecondsFor(query.mode);
    final entries = <LeaderboardEntry>[];

    if (score > 0) {
      DateTime? dailyDate;
      String? dailyModifierLabel;
      if (query.scope == LeaderboardScope.daily) {
        final source = query.dailyDate ?? DateTime.now();
        dailyDate = DateTime(source.year, source.month, source.day);
        dailyModifierLabel = DailyChallenge.forDate(dailyDate).modifier.label;
      }

      entries.add(
        LeaderboardEntry(
          playerId: _localPlayerId,
          displayName: 'YOU',
          score: score,
          isCurrentPlayer: true,
          averageReactionSeconds: average > 0 ? average : null,
          dailyDate: dailyDate,
          dailyModifierLabel: dailyModifierLabel,
        ),
      );
    }

    return LeaderboardSnapshot(
      query: query,
      entries: entries,
      source: LeaderboardDataSource.localPreview,
    );
  }

  static bool supportsMode(ReactGameMode mode) => mode != ReactGameMode.passIt;
}
