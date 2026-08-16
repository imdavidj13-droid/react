import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/daily/presentation/daily_run_screen.dart';
import 'package:react/features/dot_sequence/presentation/dot_sequence_screen.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/presentation/react_gesture_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactSettings.load();
    ReactSettings.dailyDevOverrideEnabled = true;
    ReactSettings.dailyDevRunActive = true;
  });

  tearDown(() {
    ReactSettings.dailyDevRunActive = false;
  });

  testWidgets('Daily miss still ends the run after background and resume',
      (tester) async {
    ReactSettings.dailyDevModifier = DailyModifier.redline.name;
    await tester.pumpWidget(const MaterialApp(home: DailyRunScreen()));
    await tester.pump();

    final surface = tester.widget<ReactGestureSurface>(
      find.byType(ReactGestureSurface),
    );
    final wrong = surface.expectedCommand == ReactCommand.tap
        ? ReactCommand.swipeRight
        : ReactCommand.tap;
    surface.onCommand(wrong);
    await tester.pump();
    expect(find.text('MISS'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('DAILY PAUSED'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('RESUME'));
    await tester.pumpAndSettle();

    expect(find.text('DAILY SCORE'), findsOneWidget);
    expect(find.text('MISSED COMMAND'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily Echo forced repeat survives background transition',
      (tester) async {
    ReactSettings.dailyDevModifier = DailyModifier.echo.name;
    await tester.pumpWidget(const MaterialApp(home: DailyRunScreen()));
    await tester.pump();

    ReactCommand? sixthCommand;
    for (var clear = 1; clear <= 6; clear++) {
      final surface = tester.widget<ReactGestureSurface>(
        find.byType(ReactGestureSurface),
      );
      if (clear == 6) sixthCommand = surface.expectedCommand;
      surface.onCommand(surface.expectedCommand);
      await tester.pump();
      if (clear < 6) {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('DAILY PAUSED'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('RESUME'));
    await tester.pump();

    final repeatedSurface = tester.widget<ReactGestureSurface>(
      find.byType(ReactGestureSurface),
    );
    expect(repeatedSurface.expectedCommand, sixthCommand);
    expect(find.text('ECHO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sequence system back pauses instead of discarding active run',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DotSequenceScreen(),
                  ),
                ),
                child: const Text('OPEN SEQUENCE'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN SEQUENCE'));
    await tester.pumpAndSettle();
    expect(find.text('DOT SEQUENCE'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('SEQUENCE PAUSED'), findsOneWidget);
    expect(find.text('DOT SEQUENCE'), findsOneWidget);
    expect(find.text('OPEN SEQUENCE'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
