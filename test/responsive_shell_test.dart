import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/presentation/daily_screen.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/home/presentation/home_screen.dart';
import 'package:react/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:react/features/modes/presentation/modes_screen.dart';
import 'package:react/features/pass_it/presentation/pass_it_screen.dart';
import 'package:react/features/results/presentation/results_screen.dart';
import 'package:react/features/settings/presentation/command_performance_screen.dart';
import 'package:react/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpAtSize(
    WidgetTester tester,
    Widget screen,
    Size logicalSize,
  ) async {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }

  testWidgets('Home fits a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const HomeScreen(), const Size(320, 640));
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('RUNS'), findsOneWidget);
  });

  testWidgets('Home fits a 412x915 screen', (tester) async {
    await pumpAtSize(tester, const HomeScreen(), const Size(412, 915));
    expect(find.text('CLASSIC BEST'), findsOneWidget);
    expect(find.text('ENDLESS'), findsOneWidget);
  });

  testWidgets('Modes catalogue fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const ModesScreen(), const Size(320, 640));

    expect(find.byKey(const ValueKey('modes_catalogue_scroll')), findsOneWidget);
    expect(find.text('CLASSIC'), findsOneWidget);
    expect(find.text('CORE & UTILITIES'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('MODE LAB'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('MODE LAB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pass It setup fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const PassItScreen(), const Size(320, 640));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('START GAME'), findsOneWidget);
  });

  testWidgets('Profile settings fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const SettingsScreen(), const Size(320, 640));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('RESET LOCAL PROGRESS'), findsOneWidget);
  });

  testWidgets('Command performance fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(
      tester,
      const CommandPerformanceScreen(),
      const Size(320, 640),
    );

    expect(find.text('COMMAND PERFORMANCE'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SPREAD IT'), findsOneWidget);
  });

  testWidgets('Daily fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const DailyScreen(), const Size(320, 640));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('THIS WEEK'), findsOneWidget);
  });

  testWidgets('Scores fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const LeaderboardScreen(), const Size(320, 640));

    await tester.scrollUntilVisible(
      find.text('YOUR PERFORMANCE'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('YOUR PERFORMANCE'), findsOneWidget);
  });

  testWidgets('Results fits on a 320x640 screen without scrolling', (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 12,
      successfulCommands: 12,
      averageTimeSeconds: .74,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
    );

    await pumpAtSize(
      tester,
      const ResultsScreen(result: result),
      const Size(320, 640),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.text('BACK TO HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
