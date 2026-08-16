import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/leaderboard/domain/leaderboard_submission_eligibility.dart';

void main() {
  test('Classic leaderboard requires all three lives to be lost', () {
    const impossible = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 10,
      successfulCommands: 10,
      averageTimeSeconds: .8,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 6,
    );
    const terminal = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 10,
      successfulCommands: 10,
      averageTimeSeconds: .8,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
      maxStreak: 6,
    );

    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(impossible),
      isFalse,
    );
    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(terminal),
      isTrue,
    );
  });

  test('Endless leaderboard requires its single terminal miss', () {
    const impossible = ReactRunResult(
      mode: ReactGameMode.endless,
      score: 20,
      successfulCommands: 20,
      averageTimeSeconds: .75,
      outcome: ReactRunOutcome.missedCommand,
      misses: 2,
      maxStreak: 20,
    );
    const terminal = ReactRunResult(
      mode: ReactGameMode.endless,
      score: 20,
      successfulCommands: 20,
      averageTimeSeconds: .75,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 20,
    );

    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(impossible),
      isFalse,
    );
    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(terminal),
      isTrue,
    );
  });

  test('Daily leaderboard requires one miss plus frozen challenge identity', () {
    final impossible = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 30,
      successfulCommands: 30,
      averageTimeSeconds: .7,
      outcome: ReactRunOutcome.missedCommand,
      misses: 2,
      maxStreak: 30,
      dailyDate: DateTime(2026, 8, 16),
      dailyModifierLabel: 'SURGE',
    );
    final terminal = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 30,
      successfulCommands: 30,
      averageTimeSeconds: .7,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 30,
      dailyDate: DateTime(2026, 8, 16),
      dailyModifierLabel: 'SURGE',
    );

    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(impossible),
      isFalse,
    );
    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(terminal),
      isTrue,
    );
  });
}
