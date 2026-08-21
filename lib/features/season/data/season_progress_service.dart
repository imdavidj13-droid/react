import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../daily/domain/daily_challenge.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import 'local_season_progress_queue.dart';
import 'season_repository.dart';

class SeasonProgressService {
  const SeasonProgressService._();

  static const _repository = SeasonRepository();

  /// Records one completed run and returns the exact server-awarded CHARGE for
  /// that run when it can be synchronized immediately.
  ///
  /// A null award means progression remains safely queued/offline. The run is
  /// still preserved and will be retried later.
  static Future<int?> recordResult(
    ReactRunResult result, {
    bool? isPersonalBest,
  }) async {
    if (result.isDailyDevRun || result.outcome == ReactRunOutcome.quit) {
      return null;
    }

    try {
      final resolvedPersonalBest =
          isPersonalBest ?? await _isNewPersonalBest(result);
      final completedAt = DateTime.now().toUtc();
      final random = Random.secure().nextInt(1 << 32).toRadixString(16);
      final event = SeasonProgressEvent(
        eventId:
            'season-${result.mode.name}-${completedAt.microsecondsSinceEpoch}-$random',
        mode: result.mode.name,
        score: result.score,
        successfulCommands: result.successfulCommands,
        isPersonalBest: resolvedPersonalBest,
        dailyModifier: result.mode == ReactGameMode.daily
            ? result.dailyModifierLabel
            : null,
        completedAt: completedAt,
      );

      await LocalSeasonProgressQueue.enqueue(event);
      final flush = await _flushPending(targetEventId: event.eventId);
      return flush.targetChargeEarned;
    } catch (error) {
      // Season progression is additive. A backend failure must never block or
      // alter the completed run, Results, local stats, or leaderboard queue.
      debugPrint('RE△CT season progression unavailable: $error');
      return null;
    }
  }

  static Future<int> flushPending() async {
    final result = await _flushPending();
    return result.completedCount;
  }

  static Future<_SeasonFlushResult> _flushPending({String? targetEventId}) async {
    final pending = await LocalSeasonProgressQueue.pending();
    if (pending.isEmpty) return const _SeasonFlushResult(completedCount: 0);

    final completed = <String>[];
    int? targetChargeEarned;
    for (final event in pending.reversed) {
      final record = await _repository.recordRunWithAward(
        eventId: event.eventId,
        mode: event.mode,
        score: event.score,
        successfulCommands: event.successfulCommands,
        isPersonalBest: event.isPersonalBest,
        dailyModifier: event.dailyModifier,
        completedAt: event.completedAt,
      );
      if (record == null) {
        // A permanently invalid or gap-between-seasons event must not poison
        // every newer queued run. Leave it queued for retention cleanup and
        // continue so independent events can still synchronize.
        continue;
      }
      completed.add(event.eventId);
      if (event.eventId == targetEventId) {
        targetChargeEarned = record.chargeEarned;
      }
    }

    await LocalSeasonProgressQueue.remove(completed);
    return _SeasonFlushResult(
      completedCount: completed.length,
      targetChargeEarned: targetChargeEarned,
    );
  }

  static Future<bool> _isNewPersonalBest(ReactRunResult result) async {
    if (result.score <= 0) return false;

    if (result.mode == ReactGameMode.daily) {
      final challengeDate = result.dailyDate ?? DateTime.now();
      final modifier = DailyChallenge.forDate(challengeDate).modifier;
      final modifierBest = await LocalPlayerStats.dailyBestForModifier(modifier);
      return result.score == modifierBest;
    }

    final currentBest = await LocalPlayerStats.bestFor(result.mode);
    if (result.score != currentBest) return false;

    // Results persistence has already inserted the current run at the front of
    // recent history. The server independently rejects same-scope ties from
    // this season, while this retained-history check prevents ordinary local
    // ties from being submitted as PB claims in the first place.
    final recent = await LocalPlayerStats.recentRuns();
    final priorModeRuns = recent
        .where((entry) => entry.mode == result.mode)
        .skip(1);
    return priorModeRuns.every((entry) => entry.score < result.score);
  }
}

class _SeasonFlushResult {
  const _SeasonFlushResult({
    required this.completedCount,
    this.targetChargeEarned,
  });

  final int completedCount;
  final int? targetChargeEarned;
}
