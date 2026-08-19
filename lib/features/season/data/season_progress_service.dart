import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import 'season_repository.dart';

class SeasonProgressService {
  const SeasonProgressService._();

  static const _repository = SeasonRepository();

  static Future<void> recordResult(ReactRunResult result) async {
    if (result.isDailyDevRun || result.outcome == ReactRunOutcome.quit) return;

    try {
      final isPersonalBest = await _isNewPersonalBest(result);
      final completedAt = DateTime.now().toUtc();
      final random = Random.secure().nextInt(1 << 32).toRadixString(16);
      final eventId =
          'season-${result.mode.name}-${completedAt.microsecondsSinceEpoch}-$random';

      await _repository.recordRun(
        eventId: eventId,
        score: result.score,
        successfulCommands: result.successfulCommands,
        isPersonalBest: isPersonalBest,
        isDaily: result.mode == ReactGameMode.daily,
      );
    } catch (error) {
      // Season progression is additive. A backend failure must never block or
      // alter the completed run, Results, local stats, or leaderboard queue.
      debugPrint('RE△CT season progression unavailable: $error');
    }
  }

  static Future<bool> _isNewPersonalBest(ReactRunResult result) async {
    if (result.mode == ReactGameMode.passIt) return false;
    final currentBest = await LocalPlayerStats.bestFor(result.mode);
    if (result.score != currentBest || result.score <= 0) return false;

    // Results persistence has already inserted the current run at the front of
    // recent history. If an earlier retained run already reached this score,
    // this is a tie rather than a new PB.
    final recent = await LocalPlayerStats.recentRuns();
    final priorModeRuns = recent
        .where((entry) => entry.mode == result.mode)
        .skip(1);
    return priorModeRuns.every((entry) => entry.score < result.score);
  }
}
