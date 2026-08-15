import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.dailyDevOverrideEnabled = false;
    ReactSettings.dailyDevModifier = 'lightsOut';
    ReactSettings.dailyDevRunActive = false;
  });

  ReactRunResult result({
    required ReactGameMode mode,
    required int score,
    ReactRunOutcome outcome = ReactRunOutcome.missedCommand,
    double averageTimeSeconds = .8,
    bool isDailyDevRun = false,
  }) {
    return ReactRunResult(
      mode: mode,
      score: score,
      successfulCommands: score,
      averageTimeSeconds: averageTimeSeconds,
      outcome: outcome,
      isDailyDevRun: isDailyDevRun,
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

  test('recent run history is newest first', () async {
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 4),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.blitz, score: 9),
    );

    final history = await LocalPlayerStats.recentRuns();

    expect(history, hasLength(2));
    expect(history[0].mode, ReactGameMode.blitz);
    expect(history[0].score, 9);
    expect(history[1].mode, ReactGameMode.classic);
    expect(history[1].score, 4);
  });

  test('recent run history is capped at twelve entries', () async {
    for (var i = 0; i < 15; i++) {
      await LocalPlayerStats.recordResult(
        result(mode: ReactGameMode.classic, score: i),
      );
    }

    final history = await LocalPlayerStats.recentRuns();

    expect(history, hasLength(12));
    expect(history.first.score, 14);
    expect(history.last.score, 3);
  });

  test('recent run history ignores corrupt stored entries', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recent_run_history': <String>['not-json'],
    });

    expect(await LocalPlayerStats.recentRuns(), isEmpty);
  });

  test('Daily attempt can be marked before a result exists', () async {
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

  test('Daily result keeps the launch date when a run crosses midnight', () async {
    final now = DateTime.now();
    final challengeDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final challengeKey =
        '${challengeDate.year.toString().padLeft(4, '0')}-'
        '${challengeDate.month.toString().padLeft(2, '0')}-'
        '${challengeDate.day.toString().padLeft(2, '0')}';
    final modifier = DailyChallenge.forDate(challengeDate).modifier;

    SharedPreferences.setMockInitialValues(<String, Object>{
      'daily_active_challenge': challengeKey,
      'daily_last_played': challengeKey,
      'daily_streak': 1,
    });

    final newBest = await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.daily, score: 17),
    );
    final history = await LocalPlayerStats.dailyHistoryLast7();
    final entry = history.singleWhere((item) => item.dateKey == challengeKey);
    final prefs = await SharedPreferences.getInstance();

    expect(newBest, isTrue);
    expect(entry.attempted, isTrue);
    expect(entry.score, 17);
    expect(entry.modifier, modifier);
    expect(await LocalPlayerStats.dailyBestForModifier(modifier), 17);
    expect(await LocalPlayerStats.dailyStreak(), 1);
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);
    expect(prefs.getString('daily_active_challenge'), isNull);
  });

  test('Daily new-best state follows todays modifier record', () async {
    final modifier = DailyChallenge.today().modifier;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'best_daily': 60,
      'daily_best_${modifier.name}': 20,
    });

    final newRuleBest = await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.daily, score: 25),
    );
    final lowerRetry = await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.daily, score: 24),
    );

    expect(newRuleBest, isTrue);
    expect(lowerRetry, isFalse);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.daily), 60);
    expect(await LocalPlayerStats.dailyBestForModifier(modifier), 25);
  });

  test('persisted dev override does not suppress a normal Daily result', () async {
    ReactSettings.dailyDevOverrideEnabled = true;
    ReactSettings.dailyDevRunActive = false;

    final newBest = await LocalPlayerStats.recordResult(
      result(
        mode: ReactGameMode.daily,
        score: 12,
        outcome: ReactRunOutcome.missedCommand,
      ),
    );

    expect(newBest, isTrue);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.daily), 12);
    expect(await LocalPlayerStats.runsPlayed(), 1);
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isTrue);
  });

  test('Daily developer runs never alter real local records', () async {
    final newBest = await LocalPlayerStats.recordResult(
      result(
        mode: ReactGameMode.daily,
        score: 60,
        outcome: ReactRunOutcome.completed,
        isDailyDevRun: true,
      ),
    );

    expect(newBest, isFalse);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.daily), 0);
    expect(await LocalPlayerStats.runsPlayed(), 0);
    expect(await LocalPlayerStats.runsFor(ReactGameMode.daily), 0);
    expect(await LocalPlayerStats.recentRuns(), isEmpty);
    expect(await LocalPlayerStats.dailyStreak(), 0);
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);
  });

  test('reset clears progress, detailed stats, history, and daily state', () async {
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.classic, score: 14),
    );
    await LocalPlayerStats.recordResult(
      result(mode: ReactGameMode.blitz, score: 22),
    );
    await LocalPlayerStats.markDailyAttemptStarted();

    await LocalPlayerStats.resetProgress();
    final prefs = await SharedPreferences.getInstance();

    expect(await LocalPlayerStats.bestFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.bestFor(ReactGameMode.blitz), 0);
    expect(await LocalPlayerStats.runsPlayed(), 0);
    expect(await LocalPlayerStats.runsFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.successfulCommandsFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.averageReactionSecondsFor(ReactGameMode.classic), 0);
    expect(await LocalPlayerStats.recentRuns(), isEmpty);
    expect(await LocalPlayerStats.dailyStreak(), 0);
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);
    expect(prefs.getString('daily_active_challenge'), isNull);
  });
}
