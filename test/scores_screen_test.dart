import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Scores renders persisted recent run history', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.blitz,
        score: 17,
        successfulCommands: 17,
        averageTimeSeconds: .74,
        outcome: ReactRunOutcome.timeUp,
        misses: 2,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: LeaderboardScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('BLITZ'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('RECENT ACTIVITY'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    expect(find.text('SCORE 17'), findsOneWidget);
    expect(find.textContaining('17 CLEARED'), findsOneWidget);
    expect(find.textContaining('2 MISSES'), findsOneWidget);
    expect(find.text('0.74s'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
