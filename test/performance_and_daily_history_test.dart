import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/domain/react_command_performance.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.dailyDevRunActive = false;
    ReactSettings.dailyDevOverrideEnabled = false;
  });

  test('aggregates per-command attempts successes misses and reaction time', () async {
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.classic,
        score: 2,
        successfulCommands: 2,
        averageTimeSeconds: .6,
        outcome: ReactRunOutcome.missedCommand,
        misses: 1,
        commandPerformance: {
          ReactCommand.tap: ReactCommandPerformance(
            command: ReactCommand.tap,
            attempts: 2,
            successes: 1,
            totalResponseMs: 500,
          ),
          ReactCommand.hold: ReactCommandPerformance(
            command: ReactCommand.hold,
            attempts: 1,
            successes: 1,
            totalResponseMs: 700,
          ),
        },
      ),
    );

    final stats = await LocalPlayerStats.commandPerformance();
    final tap = stats.singleWhere((item) => item.command == ReactCommand.tap);
    final hold = stats.singleWhere((item) => item.command == ReactCommand.hold);

    expect(tap.attempts, 2);
    expect(tap.successes, 1);
    expect(tap.misses, 1);
    expect(tap.accuracy, .5);
    expect(tap.averageReactionSeconds, .5);
    expect(hold.attempts, 1);
    expect(hold.accuracy, 1);
    expect(hold.averageReactionSeconds, .7);
  });

  test('command performance accumulates across runs and resets', () async {
    for (var i = 0; i < 2; i++) {
      await LocalPlayerStats.recordResult(
        const ReactRunResult(
          mode: ReactGameMode.blitz,
          score: 1,
          successfulCommands: 1,
          averageTimeSeconds: .4,
          outcome: ReactRunOutcome.timeUp,
          commandPerformance: {
            ReactCommand.swipeLeft: ReactCommandPerformance(
              command: ReactCommand.swipeLeft,
              attempts: 1,
              successes: 1,
              totalResponseMs: 400,
            ),
          },
        ),
      );
    }

    var stats = await LocalPlayerStats.commandPerformance();
    var swipe = stats.singleWhere(
      (item) => item.command == ReactCommand.swipeLeft,
    );
    expect(swipe.attempts, 2);
    expect(swipe.successes, 2);
    expect(swipe.averageReactionSeconds, .4);

    await LocalPlayerStats.resetProgress();
    stats = await LocalPlayerStats.commandPerformance();
    swipe = stats.singleWhere((item) => item.command == ReactCommand.swipeLeft);
    expect(swipe.attempts, 0);
    expect(swipe.successes, 0);
  });

  test('Daily attempt appears in seven-day history before a result', () async {
    await LocalPlayerStats.markDailyAttemptStarted();

    final history = await LocalPlayerStats.dailyHistoryLast7();
    final today = history.last;
    expect(history, hasLength(7));
    expect(today.attempted, isTrue);
    expect(today.score, isNull);
    expect(today.outcome, isNull);
  });

  test('Daily current week is always Monday through Sunday', () async {
    final history = await LocalPlayerStats.dailyHistoryThisWeek();

    expect(history, hasLength(7));
    expect(history.first.date.weekday, DateTime.monday);
    expect(history.last.date.weekday, DateTime.sunday);
    for (var index = 1; index < history.length; index++) {
      expect(history[index].date.difference(history[index - 1].date).inDays, 1);
    }
  });

  test('Daily result upgrades today history instead of adding a duplicate', () async {
    await LocalPlayerStats.markDailyAttemptStarted();
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.daily,
        score: 23,
        successfulCommands: 23,
        averageTimeSeconds: .82,
        outcome: ReactRunOutcome.missedCommand,
        misses: 1,
      ),
    );

    final history = await LocalPlayerStats.dailyHistoryLast7();
    final today = history.last;
    expect(history, hasLength(7));
    expect(today.attempted, isTrue);
    expect(today.score, 23);
    expect(today.outcome, ReactRunOutcome.missedCommand);
  });

  test('duplicate Daily attempt start never erases an existing result', () async {
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.daily,
        score: 31,
        successfulCommands: 31,
        averageTimeSeconds: .76,
        outcome: ReactRunOutcome.missedCommand,
        misses: 1,
      ),
    );

    await LocalPlayerStats.markDailyAttemptStarted();

    final history = await LocalPlayerStats.dailyHistoryLast7();
    final today = history.last;
    expect(today.attempted, isTrue);
    expect(today.score, 31);
    expect(today.outcome, ReactRunOutcome.missedCommand);
  });

  test('developer Daily result never changes real Daily history', () async {
    ReactSettings.dailyDevRunActive = true;
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.daily,
        score: 60,
        successfulCommands: 60,
        averageTimeSeconds: .6,
        outcome: ReactRunOutcome.completed,
      ),
    );

    final history = await LocalPlayerStats.dailyHistoryLast7();
    expect(history.last.attempted, isFalse);
    expect(history.last.score, isNull);
  });
}
