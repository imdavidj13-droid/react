import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../gameplay/domain/react_run_result.dart';
import '../../season/data/season_progress_service.dart';
import '../domain/leaderboard_submission.dart';
import '../domain/leaderboard_submission_eligibility.dart';

class LocalLeaderboardSubmissionStore {
  const LocalLeaderboardSubmissionStore._();

  static const _pendingKey = 'leaderboard_pending_submissions';
  static const _pendingLimit = 100;

  static Future<LeaderboardSubmission?> enqueueResult(
    ReactRunResult result, {
    DateTime? completedAt,
    void Function(int chargeEarned)? onSeasonChargeEarned,
  }) async {
    if (result.isDailyDevRun) {
      return null;
    }

    // Seasonal progression is deliberately independent from leaderboard
    // eligibility so Pass It and other valid completed runs still count toward
    // CHARGE. Awaiting this here also lets Results show the exact award while
    // the queue still preserves progression safely when offline.
    final chargeEarned = await SeasonProgressService.recordResult(result);
    if (chargeEarned != null) onSeasonChargeEarned?.call(chargeEarned);

    if (!LeaderboardSubmissionEligibility.isEligibleResult(result)) {
      return null;
    }

    final finishedAt = completedAt ?? DateTime.now();
    final submission = LeaderboardSubmission(
      clientSubmissionId: _newSubmissionId(result.mode, finishedAt),
      mode: result.mode,
      score: result.score,
      successfulCommands: result.successfulCommands,
      averageReactionSeconds: result.averageTimeSeconds,
      misses: result.misses,
      maxStreak: result.maxStreak,
      outcome: result.outcome,
      completedAt: finishedAt,
      dailyDate: result.mode == ReactGameMode.daily ? result.dailyDate : null,
      dailyModifierLabel:
          result.mode == ReactGameMode.daily ? result.dailyModifierLabel : null,
    );

    if (!LeaderboardSubmissionEligibility.isValidSubmission(submission)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_pendingKey) ?? const <String>[];
    final next = <String>[submission.encode(), ...current]
        .take(_pendingLimit)
        .toList(growable: false);
    await prefs.setStringList(_pendingKey, next);
    return submission;
  }

  static Future<List<LeaderboardSubmission>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_pendingKey) ?? const <String>[];
    return raw
        .map(LeaderboardSubmission.tryDecode)
        .whereType<LeaderboardSubmission>()
        .where(LeaderboardSubmissionEligibility.isValidSubmission)
        .toList(growable: false);
  }

  static Future<void> removeSubmitted(Iterable<String> submissionIds) async {
    final ids = submissionIds.toSet();
    if (ids.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final remaining = (prefs.getStringList(_pendingKey) ?? const <String>[])
        .where((raw) {
          final submission = LeaderboardSubmission.tryDecode(raw);
          return submission == null || !ids.contains(submission.clientSubmissionId);
        })
        .toList(growable: false);
    await prefs.setStringList(_pendingKey, remaining);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }

  static String _newSubmissionId(ReactGameMode mode, DateTime completedAt) {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${mode.name}-${completedAt.toUtc().microsecondsSinceEpoch}-$random';
  }
}
