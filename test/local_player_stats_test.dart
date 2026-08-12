import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  ReactRunResult result({
    required ReactGameMode mode,
    required int score,
    ReactRunOutcome outcome = ReactRunOutcome.missedCommand,
    double averageTimeSeconds = .8,
  }) {
    return ReactRunResult(
      mode: mode,
      score: score,
      successfulCommands: score,
      averageTimeSeconds: averageTimeSeconds,
      outcome: outcome,
    );
  }

  test('records and preserves the highest score for each scored mode', () async {
    expect(
      await LocalPlayerStats.recordResult(
        result(mode: ReactGameMode.classic, score: 12),
      ),
      isTrue,
    );
    expect(
      await LocalPlayerStats.recordResult(
        result(mode: ReactGameMode.classic, score: 7),
      ),
      isFalse,
    );
    expect(
      await LocalPlayerStats.recordResult(
        result(mode: ReactGameMode.blitz, score: 19),
      ),
      isTrue,
    );

    expect(await LocalPlayerStats.bestFor(ReactGameMode.classic), 12);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.blitz), 19);
  });

  test('Pass It counts as a run but never creates a personal best', () async {
    final newBest = await LocalPlayerStats.recordResult(
      result(
        mode: ReactGameMode.passIt,
        score: 30,
        outcome: ReactRunOutcome.winner,
      ),
    );

    expect(newBest, isFalse);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.passIt), 0);
    expect(await LocalPlayerStats.runsPlayed(), 1);
  });

  test('increments total runs and per-mode runs', () async {
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 3),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.endless, score: 8),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 5),
    );

    expect(await LocalPlayerStats.runsPlayed(), 3);
    expect(await LocalPlayerStats.runsFor(ReactGameMode.classic), 2);
    expect(await LocalPlayerStats.runsFor(ReactGameMode.endless), 1);
  });

  test('accumulates successful commands per mode', () async {
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 6),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 4),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.blitz, score: 7),
    );

    expect(await LocalPlayerStats.successfulCommandsFor(ReactGameMode.classic), 10);
    expect(await LocalPlayerStats.successfulCommandsFor(ReactGameMode.blitz), 7);
    expect(await LocalPlayerStats.totalSuccessfulCommands(), 17);
  });

  test('calculates weighted average reaction time per mode', () async {
    await LocalPlayerStats.recordResult(
      result(
        mode: ReactGameMode.classic,
        score: 2,
        averageTimeSeconds: .5,
      ),
    );
    await LocalPlayerStats.recordResult(
      result(
        mode: ReactGameMode.classic,
        score: 3,
        averageTimeSeconds: 1.0,
      ),
    );

    expect(
      await LocalPlayerStats.averageReactionSecondsFor(ReactGameMode.classic),
      closeTo(.8, .001),
    );
  });

  test('Daily attempt can be consumed before a result exists', () async {
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);

    await LocalPlayerStats.markDailyAttemptStarted();

    expect(await LocalPlayerStats.hasPlayedDailyToday(), isTrue);
    expect(await LocalPlayerStats.dailyStreak(), 1);
    expect(await LocalPlayerStats.runsPlayed(), 0);
  });

  test('marks the daily challenge as played after a result is recorded', () async {
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);

    await LocalPlayerStats.recordResult(
      result(
        mode: ReactGameMode.daily,
        score: 11,
        outcome: ReactRunOutcome.missedCommand,
      ),
    );

    expect(await LocalPlayerStats.hasPlayedDailyToday(), isTrue);
    expect(await LocalPlayerStats.dailyStreak(), 1);
  });

  test('re-recording Daily on the same day does not grow the streak', () async {
    await LocalPlayerStats.markDailyAttemptStarted();
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.daily, score: 5),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.daily, score: 10),
    );

    expect(await LocalPlayerStats.dailyStreak(), 1);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.daily), 10);
  });

  test('reset clears progress, detailed stats, and daily state', () async {
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 14),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.blitz, score: 22),
    );
    await LocalPlayerStats.markDailyAttemptStarted();

    await LocalPlayerStats.resetProgress();

    expect(await LocalPlayerStats.bestFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.blitz), 0);
    expect(await LocalPlayerStats.runsPlayed(), 0);
    expect(await LocalPlayerStats.runsFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.successfulCommandsFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.averageReactionSecondsFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.dailyStreak(), 0);
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);
  });
}
