import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_gesture_surface.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactSettings.load();
  });

  ReactCommand displayedCommand() {
    for (final command in ReactCommand.values) {
      if (find.text(command.title).evaluate().isNotEmpty) return command;
    }
    throw StateError('No gameplay command is currently displayed.');
  }

  Offset wrongSwipeFor(ReactCommand expected) => switch (expected) {
        ReactCommand.swipeLeft => const Offset(90, 0),
        ReactCommand.swipeRight => const Offset(-90, 0),
        ReactCommand.swipeUp => const Offset(0, 90),
        ReactCommand.swipeDown => const Offset(0, -90),
        _ => const Offset(-90, 0),
      };

  Future<void> performWrongCommand(WidgetTester tester) async {
    final target = find.byType(ReactGestureSurface);
    final gesture = await tester.startGesture(tester.getCenter(target));
    await gesture.moveBy(wrongSwipeFor(displayedCommand()));
    await gesture.up();
    await tester.pump();
  }

  Future<void> forceBlitzTimeUp(WidgetTester tester) async {
    // Flutter test fake time does not advance Dart Stopwatch, which drives the
    // real 60-second Blitz clock. Twenty deterministic misses apply the same
    // 3-second penalties and reach the terminal condition without wall time.
    for (var miss = 0; miss < 20; miss++) {
      await performWrongCommand(tester);
      if (miss < 19) {
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      }
    }
  }

  test('generic run screen rejects Daily because it has a dedicated engine', () {
    expect(
      () => ReactRunScreen(mode: ReactGameMode.daily),
      throwsAssertionError,
    );
  });

  testWidgets('Blitz shows a TIME UP beat before Results', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReactRunScreen(mode: ReactGameMode.blitz)),
    );
    await tester.pump();

    await forceBlitzTimeUp(tester);

    expect(find.text('TIME UP'), findsOneWidget);
    expect(find.text('60 SECOND SCORE'), findsNothing);

    await tester.pump(const Duration(milliseconds: 319));
    expect(find.text('TIME UP'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('60 SECOND SCORE'), findsOneWidget);
  });

  testWidgets('Blitz terminal beat freezes if the app backgrounds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReactRunScreen(mode: ReactGameMode.blitz)),
    );
    await tester.pump();

    await forceBlitzTimeUp(tester);
    expect(find.text('TIME UP'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('60 SECOND SCORE'), findsNothing);

    // Returning to the foreground intentionally stays paused until the player
    // explicitly resumes. That action must restore the frozen terminal timer.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    await tester.tap(find.text('RESUME'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 321));
    await tester.pumpAndSettle();
    expect(find.text('60 SECOND SCORE'), findsOneWidget);
  });
}
