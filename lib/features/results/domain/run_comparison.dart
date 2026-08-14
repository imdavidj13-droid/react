import 'dart:async';

import '../../gameplay/domain/react_run_history_entry.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../leaderboard/data/local_leaderboard_submission_store.dart';

class RunComparison {
  const RunComparison({
    required this.scoreDelta,
    required this.reactionDeltaSeconds,
  });

  final int scoreDelta;
  final double? reactionDeltaSeconds;

  bool get improvedScore => scoreDelta > 0;
  bool get matchedScore => scoreDelta == 0;
  bool get fasterReaction =>
      reactionDeltaSeconds != null && reactionDeltaSeconds! < 0;

  static RunComparison? againstPrevious(
    ReactRunResult current,
    ReactRunHistoryEntry? previous, {
    DateTime? now,
  }) {
    // ResultsScreen invokes this once from its completion persistence path.
    // Keep leaderboard capture backend-agnostic and non-blocking here until a
    // remote submission service is introduced.
    unawaited(LocalLeaderboardSubmissionStore.enqueueResult(current));

    if (previous == null || previous.mode != current.mode) return null;

    if (current.mode == ReactGameMode.daily) {
      final currentDay = now ?? DateTime.now();
      final previousDay = previous.playedAt;
      final sameDay = currentDay.year == previousDay.year &&
          currentDay.month == previousDay.month &&
          currentDay.day == previousDay.day;
      if (!sameDay) return null;
    }

    final canCompareReaction = current.averageTimeSeconds > 0 &&
        previous.averageTimeSeconds > 0;

    return RunComparison(
      scoreDelta: current.score - previous.score,
      reactionDeltaSeconds: canCompareReaction
          ? current.averageTimeSeconds - previous.averageTimeSeconds
          : null,
    );
  }

  String get scoreLabel {
    if (scoreDelta > 0) return '+$scoreDelta VS LAST RUN';
    if (scoreDelta < 0) return '$scoreDelta VS LAST RUN';
    return 'MATCHED LAST RUN';
  }

  String? get reactionLabel {
    final delta = reactionDeltaSeconds;
    if (delta == null) return null;

    final absolute = delta.abs().toStringAsFixed(2);
    if (delta < 0) return '${absolute}s FASTER';
    if (delta > 0) return '${absolute}s SLOWER';
    return 'SAME AVG REACTION';
  }
}
