import '../../gameplay/domain/react_run_result.dart';

enum LeaderboardScope { global, daily }

class LeaderboardQuery {
  const LeaderboardQuery({
    required this.scope,
    required this.mode,
    this.dailyDate,
  });

  final LeaderboardScope scope;
  final ReactGameMode mode;
  final DateTime? dailyDate;

  LeaderboardQuery copyWith({
    LeaderboardScope? scope,
    ReactGameMode? mode,
    DateTime? dailyDate,
  }) {
    return LeaderboardQuery(
      scope: scope ?? this.scope,
      mode: mode ?? this.mode,
      dailyDate: dailyDate ?? this.dailyDate,
    );
  }
}
