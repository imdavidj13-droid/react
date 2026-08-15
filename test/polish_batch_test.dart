import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/domain/react_command_performance.dart';
import 'package:react/features/gameplay/domain/react_run_history_entry.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';
import 'package:react/features/leaderboard/presentation/personal_records_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactSettings.load();
  });

  test(
    'rich run history stays backward compatible and stores streak metadata',
    () {
      final entry = ReactRunHistoryEntry.fromResult(
        ReactRunResult(
          mode: ReactGameMode.daily,
          score: 19,
          successfulCommands: 19,
          averageTimeSeconds: .61,
          outcome: ReactRunOutcome.missedCommand,
          misses: 1,
          maxStreak: 19,
          dailyDate: DateTime(2026, 8, 14),
          dailyModifierLabel: 'CHAIN',
        ),
      );
      final decoded = ReactRunHistoryEntry.tryDecode(entry.encode());
      expect(decoded?.maxStreak, 19);
      expect(decoded?.dailyModifierLabel, 'CHAIN');
    },
  );

  test('strongest command prioritises accuracy before raw speed', () {
    final entry = ReactRunHistoryEntry.fromResult(
      const ReactRunResult(
        mode: ReactGameMode.classic,
        score: 11,
        successfulCommands: 11,
        averageTimeSeconds: .48,
        outcome: ReactRunOutcome.missedCommand,
        misses: 9,
        commandPerformance: {
          ReactCommand.tap: ReactCommandPerformance(
            command: ReactCommand.tap,
            attempts: 10,
            successes: 1,
            totalResponseMs: 300,
          ),
          ReactCommand.swipeLeft: ReactCommandPerformance(
            command: ReactCommand.swipeLeft,
            attempts: 10,
            successes: 10,
            totalResponseMs: 5000,
          ),
        },
      ),
    );

    expect(entry.strongestCommand, 'SWIPE LEFT');
    expect(entry.weakestCommand, 'TAP IT');
  });

  test('recording results retains the best command streak', () async {
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.endless,
        score: 12,
        successfulCommands: 12,
        averageTimeSeconds: .7,
        outcome: ReactRunOutcome.missedCommand,
        maxStreak: 12,
      ),
    );
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.classic,
        score: 20,
        successfulCommands: 20,
        averageTimeSeconds: .8,
        outcome: ReactRunOutcome.missedCommand,
        maxStreak: 8,
      ),
    );
    expect(await LocalPlayerStats.bestCommandStreak(), 12);
  });

  testWidgets('backgrounding an active run freezes it behind pause UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReactRunScreen(mode: ReactGameMode.classic)),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('THE CURRENT COMMAND IS FROZEN'), findsOneWidget);
  });

  testWidgets('personal records remains usable on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: PersonalRecordsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('PERSONAL RECORDS'), findsOneWidget);
    expect(find.text('TODAY DAILY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
