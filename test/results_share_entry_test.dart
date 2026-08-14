import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/results/presentation/results_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.dailyDevRunActive = false;
  });

  testWidgets('Normal Results exposes the share result action', (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 23,
      successfulCommands: 23,
      averageTimeSeconds: .74,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(home: ResultsScreen(result: result)),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHARE RESULT'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.text('BACK TO HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
