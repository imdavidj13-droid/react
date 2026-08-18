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
}
