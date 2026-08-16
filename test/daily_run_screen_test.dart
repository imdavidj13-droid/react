import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/daily/presentation/daily_run_screen.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/presentation/react_gesture_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.dailyDevOverrideEnabled = true;
    ReactSettings.dailyDevModifier = DailyModifier.redline.name;
    ReactSettings.dailyDevRunActive = true;
  });

  tearDown(() {
    ReactSettings.dailyDevRunActive = false;
  });

  Future<void> pumpDaily(
    WidgetTester tester,
    DailyModifier modifier,
  ) async {
    ReactSettings.dailyDevModifier = modifier.name;
    await tester.pumpWidget(
      MaterialApp(
        home: DailyRunScreen(key: ValueKey<String>(modifier.name)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  ReactCommand displayedCommand(WidgetTester tester) {
    for (final command in ReactCommand.values) {
      if (find.byIcon(command.icon).evaluate().isNotEmpty) return command;
    }
    throw StateError('No Daily command is currently displayed.');
  }

  bool isSwipe(ReactCommand command) =>
      command == ReactCommand.swipeLeft ||
      command == ReactCommand.swipeRight ||
      command == ReactCommand.swipeUp ||
      command == ReactCommand.swipeDown;

  Offset swipeDelta(ReactCommand command) => switch (command) {
        ReactCommand.swipeLeft => const Offset(-90, 0),
        ReactCommand.swipeRight => const Offset(90, 0),
        ReactCommand.swipeUp => const Offset(0, -90),
        ReactCommand.swipeDown => const Offset(0, 90),
        _ => throw ArgumentError('Command is not a swipe: $command'),
      };

  ReactCommand oppositeSwipe(ReactCommand command) => switch (command) {
        ReactCommand.swipeLeft => ReactCommand.swipeRight,
        ReactCommand.swipeRight => ReactCommand.swipeLeft,
        ReactCommand.swipeUp => ReactCommand.swipeDown,
        ReactCommand.swipeDown => ReactCommand.swipeUp,
        _ => command,
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

  Future<void> clearCurrent(
    WidgetTester tester, {
    required int expectedScore,
    Duration nextCommandDelay = const Duration(milliseconds: 420),
  }) async {
    final surface =
        tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface));
    await performCommand(tester, surface.expectedCommand);
    expect(find.text('$expectedScore CLEARS'), findsOneWidget);
    await tester.pump(nextCommandDelay);
  }

  testWidgets('Daily gameplay shell renders uncapped modifier run',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDaily(tester, DailyModifier.redline);

    expect(find.text('REDLINE'), findsWidgets);
    expect(find.text('0 CLEARS'), findsOneWidget);
    expect(find.text('MISS LIMIT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all seven Daily modifiers accept their first valid input',
      (tester) async {
    for (final modifier in DailyModifier.values) {
      await pumpDaily(tester, modifier);
      final command = displayedCommand(tester);
      final surface =
          tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface));
      final expected = surface.expectedCommand;

      if (modifier == DailyModifier.reverse && isSwipe(command)) {
        expect(expected, oppositeSwipe(command));
      } else {
        expect(expected, command);
      }

      await performCommand(tester, expected);
      expect(
        find.text('1 CLEARS'),
        findsOneWidget,
        reason: '${modifier.label} did not accept its valid input',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('NO CLOCK removes both countdown text and timer-ring painter',
      (tester) async {
    await pumpDaily(tester, DailyModifier.noClock);

    expect(find.text('NO CLOCK'), findsWidgets);
    expect(find.text('SEC'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ReactGestureSurface),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('LIGHTS OUT hides command content but keeps input active',
      (tester) async {
    await pumpDaily(tester, DailyModifier.lightsOut);
    final command = displayedCommand(tester);

    await tester.pump(const Duration(milliseconds: 700));

    final opacityFinder = find.ancestor(
      of: find.text(command.title),
      matching: find.byType(AnimatedOpacity),
    );
    expect(opacityFinder, findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(opacityFinder).opacity, 0);
    expect(
      tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface)).enabled,
      isTrue,
    );

    final surface =
        tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface));
    await performCommand(tester, surface.expectedCommand);
    expect(find.text('1 CLEARS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SURGE enters a three-command rapid-fire phase after five clears',
      (tester) async {
    await pumpDaily(tester, DailyModifier.surge);

    for (var score = 1; score <= 4; score++) {
      await clearCurrent(tester, expectedScore: score);
    }
    await clearCurrent(
      tester,
      expectedScore: 5,
      nextCommandDelay: const Duration(milliseconds: 240),
    );

    expect(find.text('SURGE'), findsWidgets);
    expect(
      tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface)).enabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ECHO repeats the sixth cleared command', (tester) async {
    await pumpDaily(tester, DailyModifier.echo);

    for (var score = 1; score <= 5; score++) {
      await clearCurrent(tester, expectedScore: score);
    }

    final sixth = displayedCommand(tester);
    final surface =
        tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface));
    await performCommand(tester, surface.expectedCommand);
    expect(find.text('6 CLEARS'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.text('ECHO'), findsWidgets);
    expect(displayedCommand(tester), sixth);
    expect(
      tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface)).enabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('REVERSE accepts the opposite direction for directional swipes',
      (tester) async {
    await pumpDaily(tester, DailyModifier.reverse);

    final random = Random(DailyChallenge.today().seed);
    var firstSwipeIndex = -1;
    for (var index = 0; index < 100; index++) {
      final command = ReactCommand.values[random.nextInt(ReactCommand.values.length)];
      if (isSwipe(command)) {
        firstSwipeIndex = index;
        break;
      }
    }
    expect(firstSwipeIndex, greaterThanOrEqualTo(0));

    for (var index = 0; index <= firstSwipeIndex; index++) {
      final command = displayedCommand(tester);
      final surface =
          tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface));
      final expected = surface.expectedCommand;

      if (isSwipe(command)) {
        expect(find.text('DO THE OPPOSITE'), findsOneWidget);
        expect(expected, oppositeSwipe(command));
        await performCommand(tester, expected);
        expect(find.text('${index + 1} CLEARS'), findsOneWidget);
        break;
      }

      expect(expected, command);
      await performCommand(tester, expected);
      expect(find.text('${index + 1} CLEARS'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 420));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('CHAIN arms the next command after its near-zero gap',
      (tester) async {
    await pumpDaily(tester, DailyModifier.chain);
    final surface =
        tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface));

    await performCommand(tester, surface.expectedCommand);
    expect(find.text('1 CLEARS'), findsOneWidget);
    expect(
      tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface)).enabled,
      isFalse,
    );

    await tester.pump(const Duration(milliseconds: 90));
    expect(
      tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface)).enabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('REDLINE marks every tenth command and keeps input live',
      (tester) async {
    await pumpDaily(tester, DailyModifier.redline);

    for (var score = 1; score <= 9; score++) {
      await clearCurrent(tester, expectedScore: score);
    }

    expect(find.text('REDLINE'), findsWidgets);
    expect(
      tester.widget<ReactGestureSurface>(find.byType(ReactGestureSurface)).enabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
