import 'leaderboard_entry.dart';
import 'leaderboard_query.dart';

enum LeaderboardDataSource { localPreview, remote }

class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.query,
    required this.entries,
    required this.source,
    this.currentPlayerRank,
  });

  final LeaderboardQuery query;
  final List<LeaderboardEntry> entries;
  final LeaderboardDataSource source;
  final int? currentPlayerRank;

  bool get isLocalPreview => source == LeaderboardDataSource.localPreview;
}
