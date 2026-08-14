import '../../gameplay/domain/react_run_result.dart';
import 'leaderboard_submission.dart';

class LeaderboardSubmissionEligibility {
  const LeaderboardSubmissionEligibility._();

  static bool isEligibleResult(ReactRunResult result) {
    if (result.mode == ReactGameMode.passIt) return false;
    if (result.outcome == ReactRunOutcome.quit) return false;
    if (result.score < 0 || result.successfulCommands < 0 || result.misses < 0) {
      return false;
    }
    if (result.score != result.successfulCommands) return false;
    if (result.maxStreak < 0 || result.maxStreak > result.successfulCommands) {
      return false;
    }
    if (result.successfulCommands == 0) {
      if (result.averageTimeSeconds != 0) return false;
    } else {
      if (result.averageTimeSeconds <= 0 || result.averageTimeSeconds > 15) {
        return false;
      }
    }

    switch (result.mode) {
      case ReactGameMode.classic:
        return result.outcome == ReactRunOutcome.missedCommand;
      case ReactGameMode.blitz:
        return result.outcome == ReactRunOutcome.timeUp;
      case ReactGameMode.endless:
        return result.outcome == ReactRunOutcome.missedCommand;
      case ReactGameMode.daily:
        if (result.outcome != ReactRunOutcome.completed &&
            result.outcome != ReactRunOutcome.missedCommand) {
          return false;
        }
        return result.dailyDate != null &&
            (result.dailyModifierLabel?.trim().isNotEmpty ?? false);
      case ReactGameMode.passIt:
        return false;
    }
  }

  static bool isValidSubmission(LeaderboardSubmission submission) {
    if (submission.clientSubmissionId.trim().isEmpty) return false;
    final result = ReactRunResult(
      mode: submission.mode,
      score: submission.score,
      successfulCommands: submission.successfulCommands,
      averageTimeSeconds: submission.averageReactionSeconds,
      outcome: submission.outcome,
      misses: submission.misses,
      maxStreak: submission.maxStreak,
      dailyDate: submission.dailyDate,
      dailyModifierLabel: submission.dailyModifierLabel,
    );
    return isEligibleResult(result);
  }
}
