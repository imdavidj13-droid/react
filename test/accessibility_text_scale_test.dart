import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/presentation/daily_screen.dart';
import 'package:react/features/dot_sequence/presentation/dot_sequence_screen.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/home/presentation/home_screen.dart';
import 'package:react/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:react/features/modes/presentation/modes_screen.dart';
import 'package:react/features/results/presentation/results_screen.dart';
import 'package:react/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpLargeText(
    WidgetTester tester,
    Widget screen,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Home tolerates 150 percent text on a compact phone', (tester) async {
    await pumpLargeText(tester, const HomeScreen());
    expect(find.text('PLAY'), findsOneWidget);
  });

  testWidgets('Modes keeps all eight options on one compact screen', (tester) async {
    await pumpLargeText(tester, const ModesScreen());

    for (final label in <String>[
      'CLASSIC',
      'BLITZ',
      'ENDLESS',
      'SEQUENCE',
      'PASS IT',
      'DAILY',
      'SCORES',
      'PROFILE',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily overview tolerates 150 percent text on a compact phone',
      (tester) async {
    await pumpLargeText(tester, const DailyScreen());
    expect(find.text('DAILY RUN'), findsOneWidget);
  });

  testWidgets('Sequence tolerates 150 percent text on a compact phone',
      (tester) async {
    await pumpLargeText(tester, const DotSequenceScreen());
    expect(find.text('DOT SEQUENCE'), findsOneWidget);
  });

  testWidgets('Leaderboard tolerates 150 percent text on a compact phone',
      (tester) async {
    await pumpLargeText(tester, const LeaderboardScreen());
    expect(find.text('LEADERBOARD'), findsOneWidget);
  });

  testWidgets('Settings tolerates 150 percent text on a compact phone',
      (tester) async {
    await pumpLargeText(tester, const SettingsScreen());
    expect(find.text('PROFILE'), findsWidgets);
  });

  testWidgets('Results tolerates 150 percent text on a compact phone',
      (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 12,
      successfulCommands: 12,
      averageTimeSeconds: .74,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
    );
    await pumpLargeText(tester, const ResultsScreen(result: result));
    expect(find.text('FINAL SCORE'), findsOneWidget);
  });
}
