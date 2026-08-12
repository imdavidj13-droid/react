import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/presentation/react_gesture_surface.dart';

void main() {
  Future<List<ReactCommand>> pumpSurface(
    WidgetTester tester,
    ReactCommand expected,
  ) async {
    final commands = <ReactCommand>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: ReactGestureSurface(
                enabled: true,
                expectedCommand: expected,
                onCommand: commands.add,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
    return commands;
  }

  testWidgets('Tap resolves immediately when Tap is expected', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.tap);

    await tester.tap(find.byType(ColoredBox));
    await tester.pump();

    expect(commands, [ReactCommand.tap]);
  });

  testWidgets('Double Tap resolves inside the custom tap window', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.doubleTap);
    final center = tester.getCenter(find.byType(ColoredBox));

    final first = await tester.startGesture(center, pointer: 1);
    await first.up();
    await tester.pump(const Duration(milliseconds: 80));
    final second = await tester.startGesture(center, pointer: 2);
    await second.up();
    await tester.pump();

    expect(commands, [ReactCommand.doubleTap]);
  });

  testWidgets('Single tap while Double Tap is expected reports Tap after window',
      (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.doubleTap);

    await tester.tap(find.byType(ColoredBox));
    await tester.pump(const Duration(milliseconds: 300));

    expect(commands, [ReactCommand.tap]);
  });

  testWidgets('Hold resolves after explicit hold threshold', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.hold);
    final center = tester.getCenter(find.byType(ColoredBox));

    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 380));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.hold]);
  });

  for (final entry in <(Offset, ReactCommand)>[
    (const Offset(-90, 0), ReactCommand.swipeLeft),
    (const Offset(90, 0), ReactCommand.swipeRight),
    (const Offset(0, -90), ReactCommand.swipeUp),
    (const Offset(0, 90), ReactCommand.swipeDown),
  ]) {
    testWidgets('${entry.$2.name} resolves from raw pointer movement', (tester) async {
      final commands = await pumpSurface(tester, entry.$2);
      final center = tester.getCenter(find.byType(ColoredBox));

      final gesture = await tester.startGesture(center);
      await gesture.moveBy(entry.$1);
      await gesture.up();
      await tester.pump();

      expect(commands, [entry.$2]);
    });
  }

  testWidgets('Pinch resolves from decreasing two-pointer distance', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.pinch);
    final center = tester.getCenter(find.byType(ColoredBox));

    final left = await tester.createGesture(pointer: 1);
    final right = await tester.createGesture(pointer: 2);
    await left.down(center + const Offset(-70, 0));
    await right.down(center + const Offset(70, 0));
    await left.moveTo(center + const Offset(-35, 0));
    await right.moveTo(center + const Offset(35, 0));
    await tester.pump();
    await left.up();
    await right.up();

    expect(commands, [ReactCommand.pinch]);
  });

  testWidgets('Spread resolves from increasing two-pointer distance', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.spread);
    final center = tester.getCenter(find.byType(ColoredBox));

    final left = await tester.createGesture(pointer: 1);
    final right = await tester.createGesture(pointer: 2);
    await left.down(center + const Offset(-35, 0));
    await right.down(center + const Offset(35, 0));
    await left.moveTo(center + const Offset(-75, 0));
    await right.moveTo(center + const Offset(75, 0));
    await tester.pump();
    await left.up();
    await right.up();

    expect(commands, [ReactCommand.spread]);
  });

  testWidgets('Wrong swipe is still emitted so gameplay can count a miss',
      (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.swipeLeft);
    final center = tester.getCenter(find.byType(ColoredBox));

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(90, 0));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.swipeRight]);
  });
}
