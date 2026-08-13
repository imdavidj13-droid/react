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

  testWidgets('Dragged movement is not accepted as Tap', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.tap);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(28, 0));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.swipeRight]);
  });

  testWidgets('Long press is not accepted as Tap', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.tap);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.hold]);
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

  testWidgets('Second Double Tap press can finish after fallback deadline',
      (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.doubleTap);
    final center = tester.getCenter(target());

    final first = await tester.startGesture(center, pointer: 1);
    await first.up();
    await tester.pump(const Duration(milliseconds: 360));
    final second = await tester.startGesture(center, pointer: 2);
    await tester.pump(const Duration(milliseconds: 90));
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

  testWidgets('Disabling input clears a half-finished Double Tap', (tester) async {
    final commands = <ReactCommand>[];
    var enabled = true;
    late StateSetter setSurfaceState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setSurfaceState = setState;
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: ReactGestureSurface(
                    enabled: enabled,
                    expectedCommand: ReactCommand.doubleTap,
                    onCommand: commands.add,
                    child: const ColoredBox(
                      key: surfaceKey,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(target());
    await tester.pump(const Duration(milliseconds: 120));
    setSurfaceState(() => enabled = false);
    await tester.pump();
    setSurfaceState(() => enabled = true);
    await tester.pump();
    await tester.tap(target());
    await tester.pump(const Duration(milliseconds: 450));

    expect(commands, [ReactCommand.tap]);
  });

  testWidgets('Hold completes when the threshold is reached', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.hold);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 380));

    expect(commands, [ReactCommand.hold]);

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
    expect(commands, [ReactCommand.hold]);
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.hold]);
  });

  testWidgets('Hold with too much drift does not become Hold on release',
      (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.hold);
    final center = tester.getCenter(target());

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pump();

    expect(commands, [ReactCommand.tap]);
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
    await left.down(center + const Offset(-60, 0));
    await right.down(center + const Offset(60, 0));
    await left.moveTo(center + const Offset(-48, 0));
    await right.moveTo(center + const Offset(48, 0));
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
    await left.down(center + const Offset(-48, 0));
    await right.down(center + const Offset(48, 0));
    await left.moveTo(center + const Offset(-60, 0));
    await right.moveTo(center + const Offset(60, 0));
    await tester.pump();
    expect(commands, isEmpty);
    await left.up();
    expect(commands, isEmpty);
    await right.up();
    await tester.pump();

    expect(commands, [ReactCommand.spread]);
  });

  testWidgets('Cancelled two-finger gesture emits no command', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.pinch);
    final center = tester.getCenter(target());

    final left = await tester.createGesture(pointer: 1);
    final right = await tester.createGesture(pointer: 2);
    await left.down(center + const Offset(-60, 0));
    await right.down(center + const Offset(60, 0));
    await left.moveTo(center + const Offset(-45, 0));
    await right.moveTo(center + const Offset(45, 0));
    await left.cancel();
    await right.up();
    await tester.pump();

    expect(commands, isEmpty);
  });

  testWidgets('Three-finger input cannot resolve as Pinch or Spread', (tester) async {
    final commands = await pumpSurface(tester, ReactCommand.pinch);
    final center = tester.getCenter(target());

    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    final third = await tester.createGesture(pointer: 3);
    await first.down(center + const Offset(-60, 0));
    await second.down(center + const Offset(60, 0));
    await third.down(center + const Offset(0, 40));
    await first.moveTo(center + const Offset(-30, 0));
    await second.moveTo(center + const Offset(30, 0));
    await first.up();
    await second.up();
    await third.up();
    await tester.pump();

    expect(commands, isEmpty);
  });

  testWidgets('Old pointer release cannot satisfy the next command', (tester) async {
    final commands = <ReactCommand>[];
    var enabled = true;
    var expected = ReactCommand.hold;
    late StateSetter setSurfaceState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setSurfaceState = setState;
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: ReactGestureSurface(
                    enabled: enabled,
                    expectedCommand: expected,
                    onCommand: commands.add,
                    child: const ColoredBox(
                      key: surfaceKey,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final center = tester.getCenter(target());
    final oldGesture = await tester.startGesture(center, pointer: 1);
    await tester.pump(const Duration(milliseconds: 380));
    expect(commands, [ReactCommand.hold]);

    setSurfaceState(() => enabled = false);
    await tester.pump();
    setSurfaceState(() {
      expected = ReactCommand.tap;
      enabled = true;
    });
    await tester.pump();

    await oldGesture.up();
    await tester.pump();
    expect(commands, [ReactCommand.hold]);

    await tester.tap(target());
    await tester.pump();
    expect(commands, [ReactCommand.hold, ReactCommand.tap]);
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
