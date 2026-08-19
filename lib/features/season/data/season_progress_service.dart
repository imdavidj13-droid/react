import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import 'local_season_progress_queue.dart';
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
      final event = SeasonProgressEvent(
        eventId:
            'season-${result.mode.name}-${completedAt.microsecondsSinceEpoch}-$random',
        score: result.score,
        successfulCommands: result.successfulCommands,
        isPersonalBest: isPersonalBest,
        isDaily: result.mode == ReactGameMode.daily,
        completedAt: completedAt,
      );

      await LocalSeasonProgressQueue.enqueue(event);
      await flushPending();
    } catch (error) {
      // Season progression is additive. A backend failure must never block or
      // alter the completed run, Results, local stats, or leaderboard queue.
      debugPrint('RE△CT season progression unavailable: $error');
    }
  }

  static Future<int> flushPending() async {
    final pending = await LocalSeasonProgressQueue.pending();
    if (pending.isEmpty) return 0;

    final completed = <String>[];
    for (final event in pending.reversed) {
      final snapshot = await _repository.recordRun(
        eventId: event.eventId,
        score: event.score,
        successfulCommands: event.successfulCommands,
        isPersonalBest: event.isPersonalBest,
        isDaily: event.isDaily,
        completedAt: event.completedAt,
      );
      if (snapshot == null) break;
      completed.add(event.eventId);
    }

    await LocalSeasonProgressQueue.remove(completed);
    return completed.length;
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
