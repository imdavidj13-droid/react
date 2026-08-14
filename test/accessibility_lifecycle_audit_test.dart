import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/daily/presentation/daily_run_screen.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactSettings.load();
  });

  testWidgets('visual effects off keeps the command UI readable and playable',
      (tester) async {
    await ReactSettings.setVisualEffectsEnabled(false);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReactRunScreen(mode: ReactGameMode.classic),
      ),
    );
    await tester.pump();

    expect(ReactSettings.visualEffectsEnabled, isFalse);
    expect(find.text('CLASSIC'), findsWidgets);
    expect(
      ReactCommand.values.any((command) => find.text(command.title).evaluate().isNotEmpty),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily freezes safely when app backgrounds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyRunScreen()));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(find.text('DAILY PAUSED'), findsOneWidget);
    expect(find.text('THE CURRENT COMMAND IS FROZEN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Blitz freezes safely when app backgrounds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReactRunScreen(mode: ReactGameMode.blitz),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('THE CURRENT COMMAND IS FROZEN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pass It handoff can background without starting hidden input',
      (tester) async {
    await ReactSettings.setPassItPlayerCount(3);
    await tester.pumpWidget(
      const MaterialApp(
        home: ReactRunScreen(mode: ReactGameMode.passIt),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(find.text('PAUSED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
