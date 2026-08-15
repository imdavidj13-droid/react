import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/leaderboard/data/local_leaderboard_submission_store.dart';
import 'package:react/features/leaderboard/domain/leaderboard_submission_eligibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('competitive modes accept only valid completed run shapes', () {
    const classic = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 12,
      successfulCommands: 12,
      averageTimeSeconds: .76,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
      maxStreak: 7,
    );
    expect(LeaderboardSubmissionEligibility.isEligibleResult(classic), isTrue);

    const passIt = ReactRunResult(
      mode: ReactGameMode.passIt,
      score: 12,
      successfulCommands: 12,
      averageTimeSeconds: .76,
      outcome: ReactRunOutcome.winner,
      misses: 3,
      maxStreak: 7,
    );
    expect(LeaderboardSubmissionEligibility.isEligibleResult(passIt), isFalse);

    const quit = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 4,
      successfulCommands: 4,
      averageTimeSeconds: .82,
      outcome: ReactRunOutcome.quit,
    );
    expect(LeaderboardSubmissionEligibility.isEligibleResult(quit), isFalse);

    const mismatchedScore = ReactRunResult(
      mode: ReactGameMode.endless,
      score: 9,
      successfulCommands: 8,
      averageTimeSeconds: .71,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );
    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(mismatchedScore),
      isFalse,
    );
  });

  test('Daily requires frozen challenge identity', () {
    const missingMetadata = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 20,
      successfulCommands: 20,
      averageTimeSeconds: .69,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 10,
    );
    expect(
      LeaderboardSubmissionEligibility.isEligibleResult(missingMetadata),
      isFalse,
    );

    final valid = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 20,
      successfulCommands: 20,
      averageTimeSeconds: .69,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 10,
      dailyDate: DateTime(2026, 8, 14),
      dailyModifierLabel: 'SURGE',
    );
    expect(LeaderboardSubmissionEligibility.isEligibleResult(valid), isTrue);
  });

  test('local queue persists eligible submissions and removes uploaded ids', () async {
    const result = ReactRunResult(
      mode: ReactGameMode.blitz,
      score: 34,
      successfulCommands: 34,
      averageTimeSeconds: .64,
      outcome: ReactRunOutcome.timeUp,
      misses: 2,
      maxStreak: 15,
    );

    final submission = await LocalLeaderboardSubmissionStore.enqueueResult(
      result,
      completedAt: DateTime.utc(2026, 8, 14, 9),
    );
    expect(submission, isNotNull);

    final pending = await LocalLeaderboardSubmissionStore.pending();
    expect(pending, hasLength(1));
    expect(pending.single.mode, ReactGameMode.blitz);
    expect(pending.single.score, 34);
    expect(pending.single.clientSubmissionId, isNotEmpty);

    await LocalLeaderboardSubmissionStore.removeSubmitted(<String>[
      pending.single.clientSubmissionId,
    ]);
    expect(await LocalLeaderboardSubmissionStore.pending(), isEmpty);
  });

  test('Daily dev run identity is frozen on the result and never queued', () async {
    final result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 18,
      successfulCommands: 18,
      averageTimeSeconds: .72,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 8,
      dailyDate: DateTime(2026, 8, 14),
      dailyModifierLabel: 'SURGE',
      isDailyDevRun: true,
    );

    expect(
      await LocalLeaderboardSubmissionStore.enqueueResult(result),
      isNull,
    );
    expect(await LocalLeaderboardSubmissionStore.pending(), isEmpty);
    expect(await LocalPlayerStats.recordResult(result), isFalse);
    expect(await LocalPlayerStats.runsPlayed(), 0);
  });

  test('reset progress also clears pending leaderboard submissions', () async {
    const result = ReactRunResult(
      mode: ReactGameMode.endless,
      score: 21,
      successfulCommands: 21,
      averageTimeSeconds: .67,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 12,
    );

    await LocalLeaderboardSubmissionStore.enqueueResult(result);
    expect(await LocalLeaderboardSubmissionStore.pending(), hasLength(1));

    await LocalPlayerStats.resetProgress();

    expect(await LocalLeaderboardSubmissionStore.pending(), isEmpty);
  });
}
