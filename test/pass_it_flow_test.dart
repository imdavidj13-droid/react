import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';

void main() {
  setUp(() {
    ReactSettings.soundEnabled = false;
    ReactSettings.visualEffectsEnabled = false;
    ReactSettings.passItPlayerCount = 2;
  });

  Future<void> pumpPassIt(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReactRunScreen(mode: ReactGameMode.passIt),
      ),
    );
    expect(find.text('PASS TO PLAYER 1'), findsOneWidget);
    await tester.tap(find.text('I’M READY'));
    await tester.pump();
  }

  Future<void> performVisibleCommand(WidgetTester tester) async {
    final command = ReactCommand.values.singleWhere(
      (candidate) => find.text(candidate.title).evaluate().isNotEmpty,
    );
    final target = find.text(command.title);
    final center = tester.getCenter(target);

    switch (command) {
      case ReactCommand.tap:
        await tester.tap(target);
      case ReactCommand.doubleTap:
        await tester.tap(target);
        await tester.pump(const Duration(milliseconds: 120));
        await tester.tap(target);
      case ReactCommand.hold:
        final gesture = await tester.startGesture(center);
        await tester.pump(const Duration(milliseconds: 380));
        await gesture.up();
      case ReactCommand.swipeLeft:
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(-90, 0));
        await gesture.up();
      case ReactCommand.swipeRight:
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(90, 0));
        await gesture.up();
      case ReactCommand.swipeUp:
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(0, -90));
        await gesture.up();
      case ReactCommand.swipeDown:
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(0, 90));
        await gesture.up();
      case ReactCommand.pinch:
        final left = await tester.createGesture(pointer: 1);
        final right = await tester.createGesture(pointer: 2);
        await left.down(center + const Offset(-60, 0));
        await right.down(center + const Offset(60, 0));
        await left.moveTo(center + const Offset(-48, 0));
        await right.moveTo(center + const Offset(48, 0));
        await left.up();
        await right.up();
      case ReactCommand.spread:
        final left = await tester.createGesture(pointer: 1);
        final right = await tester.createGesture(pointer: 2);
        await left.down(center + const Offset(-48, 0));
        await right.down(center + const Offset(48, 0));
        await left.moveTo(center + const Offset(-60, 0));
        await right.moveTo(center + const Offset(60, 0));
        await left.up();
        await right.up();
    }

    await tester.pump();
  }

  testWidgets('Pass It keeps the same player after a successful command',
      (tester) async {
    await pumpPassIt(tester);

    await performVisibleCommand(tester);
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('PASS TO PLAYER 2'), findsNothing);
    expect(find.text('P1  3♥'), findsOneWidget);
  });

  testWidgets('Pass It removes one life before handing to the next player',
      (tester) async {
    await pumpPassIt(tester);

    // The slowest starting Pass It command is under 2.4 seconds. Advance past
    // that window, then give the periodic deadline check and handoff transition
    // their own deterministic pumps.
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('PLAYER 1 LOST A LIFE'), findsOneWidget);
    expect(find.text('PASS TO PLAYER 2'), findsOneWidget);
    expect(find.text('PLAYER 2  •  3 LIVES  •  TAP WHEN READY'), findsOneWidget);
    expect(find.textContaining('3  ♥ ♥ ♥'), findsOneWidget);
    expect(find.textContaining('2  ♥ ♥'), findsOneWidget);
  });
}
