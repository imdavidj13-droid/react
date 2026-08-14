import '../domain/leaderboard_query.dart';
import '../domain/leaderboard_snapshot.dart';

abstract interface class LeaderboardRepository {
  Future<LeaderboardSnapshot> load(LeaderboardQuery query);
}
