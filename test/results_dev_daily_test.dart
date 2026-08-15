import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/results/presentation/results_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Daily developer Results stays repeatable and does not consume Daily',
      (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 18,
      successfulCommands: 18,
      averageTimeSeconds: .72,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      isDailyDevRun: true,
    );

    await tester.pumpWidget(
      const MaterialApp(home: ResultsScreen(result: result)),
    );
    await tester.pumpAndSettle();

    expect(find.text('TEST AGAIN'), findsOneWidget);
    expect(find.text('BACK TO DEV TESTER'), findsOneWidget);
    expect(find.text('SHARE RESULT'), findsNothing);
    expect(find.text('DAILY ATTEMPT COMPLETE'), findsNothing);
    expect(await LocalPlayerStats.hasPlayedDailyToday(), isFalse);
    expect(await LocalPlayerStats.runsPlayed(), 0);
  });
}
