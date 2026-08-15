import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/daily/presentation/daily_run_screen.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/presentation/react_gesture_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.dailyDevOverrideEnabled = true;
    ReactSettings.dailyDevModifier = DailyModifier.chain.name;
    ReactSettings.dailyDevRunActive = true;
  });

  tearDown(() {
    ReactSettings.dailyDevRunActive = false;
  });

  ReactCommand displayedCommand(WidgetTester tester) {
    for (final command in ReactCommand.values) {
      if (find.text(command.title).evaluate().isNotEmpty) return command;
    }
    throw StateError('No Daily command is currently displayed.');
  }

  Offset swipeDelta(ReactCommand command) => switch (command) {
        ReactCommand.swipeLeft => const Offset(-90, 0),
        ReactCommand.swipeRight => const Offset(90, 0),
        ReactCommand.swipeUp => const Offset(0, -90),
        ReactCommand.swipeDown => const Offset(0, 90),
        _ => throw ArgumentError('Command is not a swipe: $command'),
      };

  Future<void> performCommand(
    WidgetTester tester,
    ReactCommand command,
  ) async {
    final target = find.byType(ReactGestureSurface);
    final center = tester.getCenter(target);

    switch (command) {
      case ReactCommand.tap:
        await tester.tap(target);
      case ReactCommand.doubleTap:
        final first = await tester.startGesture(center, pointer: 1);
        await first.up();
        await tester.pump(const Duration(milliseconds: 120));
        final second = await tester.startGesture(center, pointer: 2);
        await second.up();
      case ReactCommand.hold:
        final gesture = await tester.startGesture(center);
        await tester.pump(const Duration(milliseconds: 380));
        await gesture.up();
      case ReactCommand.swipeLeft ||
            ReactCommand.swipeRight ||
            ReactCommand.swipeUp ||
            ReactCommand.swipeDown:
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(swipeDelta(command));
        await gesture.up();
      case ReactCommand.pinch:
        final left = await tester.createGesture(pointer: 11);
        final right = await tester.createGesture(pointer: 12);
        await left.down(center + const Offset(-60, 0));
        await right.down(center + const Offset(60, 0));
        await left.moveTo(center + const Offset(-45, 0));
        await right.moveTo(center + const Offset(45, 0));
        await left.up();
        await right.up();
      case ReactCommand.spread:
        final left = await tester.createGesture(pointer: 21);
        final right = await tester.createGesture(pointer: 22);
        await left.down(center + const Offset(-45, 0));
        await right.down(center + const Offset(45, 0));
        await left.moveTo(center + const Offset(-60, 0));
        await right.moveTo(center + const Offset(60, 0));
        await left.up();
        await right.up();
    }
    await tester.pump();
  }

  testWidgets('Daily 60/60 completion has a pause-safe completion beat',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyRunScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    for (var score = 1; score <= 60; score++) {
      await performCommand(tester, displayedCommand(tester));
      expect(find.text('$score/60'), findsOneWidget);
      if (score < 60) {
        await tester.pump(const Duration(milliseconds: 90));
      }
    }

    expect(find.text('DAILY COMPLETE'), findsOneWidget);
    expect(find.text('DAILY SCORE'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('DAILY PAUSED'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('DAILY SCORE'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pumpAndSettle();

    expect(find.text('DAILY SCORE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
