import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/presentation/react_gesture_surface.dart';

void main() {
  const surfaceKey = Key('gesture-test-surface');

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
                child: const ColoredBox(
                  key: surfaceKey,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return commands;
  }

  Finder target() => find.byKey(surfaceKey);

  testWidgets('Tap resolves on release when Tap is expected', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.tap);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    expect(commands, isEmpty);
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.tap]);
  });

  testWidgets('Double Tap resolves inside the custom tap window', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.doubleTap);
    final center = tester.getCenter(target());

    final first = await tester.startGesture(center, pointer: 1);
    await first.up();
    await tester.pump(const Duration(milliseconds: 240));
    final second = await tester.startGesture(center, pointer: 2);
    await second.up();
    await tester.pump();

    expect(commands, [ReactCommand.doubleTap]);
  });

  testWidgets('Double Tap does not require an ultra-fast second tap', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.doubleTap);
    final center = tester.getCenter(target());

    final first = await tester.startGesture(center, pointer: 1);
    await first.up();
    await tester.pump(const Duration(milliseconds: 380));
    final second = await tester.startGesture(center, pointer: 2);
    await second.up();
    await tester.pump();

    expect(commands, [ReactCommand.doubleTap]);
  });

  testWidgets('Single tap while Double Tap is expected reports Tap after window',
      (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.doubleTap);

    await tester.tap(target());
    await tester.pump(const Duration(milliseconds: 450));

    expect(commands, [ReactCommand.tap]);
  });

  testWidgets('Hold does not complete until finger is released', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.hold);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 380));
    expect(commands, isEmpty);
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.hold]);
  });

  testWidgets('Hold tolerates small natural finger drift', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.hold);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(10, 8));
    await tester.pump(const Duration(milliseconds: 380));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.hold]);
  });

  testWidgets('Hold cancels when movement becomes a real gesture', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.hold);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 380));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.swipeRight]);
  });

  for (final entry in <(Offset, ReactCommand)>[
    (const Offset(-90, 0), ReactCommand.swipeLeft),
    (const Offset(90, 0), ReactCommand.swipeRight),
    (const Offset(0, -90), ReactCommand.swipeUp),
    (const Offset(0, 90), ReactCommand.swipeDown),
  ]) {
    testWidgets('${entry.$2.name} resolves from raw pointer movement', (tester) async {
      final commands = await pumpSurface(tester, entry.$2);
      final center = tester.getCenter(target());

      final gesture = await tester.startGesture(center);
      await gesture.moveBy(entry.$1);
      await gesture.up();
      await tester.pump();

      expect(commands, [entry.$2]);
    });
  }

  testWidgets('Pinch resolves only after both pointers release', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.pinch);
    final center = tester.getCenter(target());

    final left = await tester.createGesture(pointer: 1);
    final right = await tester.createGesture(pointer: 2);
    await left.down(center + const Offset(-70, 0));
    await right.down(center + const Offset(70, 0));
    await left.moveTo(center + const Offset(-35, 0));
    await right.moveTo(center + const Offset(35, 0));
    await tester.pump();
    expect(commands, isEmpty);
    await left.up();
    expect(commands, isEmpty);
    await right.up();
    await tester.pump();

    expect(commands, [ReactCommand.pinch]);
  });

  testWidgets('Spread resolves only after both pointers release', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.spread);
    final center = tester.getCenter(target());

    final left = await tester.createGesture(pointer: 1);
    final right = await tester.createGesture(pointer: 2);
    await left.down(center + const Offset(-35, 0));
    await right.down(center + const Offset(35, 0));
    await left.moveTo(center + const Offset(-75, 0));
    await right.moveTo(center + const Offset(75, 0));
    await tester.pump();
    expect(commands, isEmpty);
    await left.up();
    expect(commands, isEmpty);
    await right.up();
    await tester.pump();

    expect(commands, [ReactCommand.spread]);
  });

  testWidgets('Wrong swipe is still emitted so gameplay can count a miss',
      (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.swipeLeft);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(90, 0));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.swipeRight]);
  });
}
