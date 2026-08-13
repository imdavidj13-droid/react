import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactSettings.load();
  });

  testWidgets('Classic pause restart returns through 3-2-1 launch', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReactRunScreen(mode: ReactGameMode.classic),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.text('RESTART RUN'), findsOneWidget);

    await tester.tap(find.text('RESTART RUN'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('CLASSIC'), findsOneWidget);
    expect(find.text('GET READY'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Pass It restart keeps the player-ready handoff flow', (tester) async {
    ReactSettings.passItPlayerCount = 2;

    await tester.pumpWidget(
      const MaterialApp(
        home: ReactRunScreen(mode: ReactGameMode.passIt),
      ),
    );
    await tester.pump();

    expect(find.text('PLAYER 1 STARTS'), findsOneWidget);
    await tester.tap(find.text('I’M READY'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.tap(find.text('RESTART RUN'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('PLAYER 1 STARTS'), findsOneWidget);
    expect(find.text('GET READY'), findsNothing);
  });
}
