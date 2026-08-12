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
  }) {
    return ReactRunResult(
      mode: mode,
      score: score,
      successfulCommands: score,
      averageTimeSeconds: .8,
      outcome: outcome,
    );
  }

  test('records and preserves the highest score for each mode', () async {
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 12),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 7),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.blitz, score: 19),
    );

    expect(await LocalPlayerStats.bestFor(ReactGameMode.classic), 12);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.blitz), 19);
  });

  test('increments total runs for every recorded result', () async {
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 3),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.endless, score: 8),
    );

    expect(await LocalPlayerStats.runsPlayed(), 2);
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

  test('reset clears progress and daily state', () async {
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
    expect(await LocalPlayerStats.dailyStreak(), 0);
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);
  });
}
