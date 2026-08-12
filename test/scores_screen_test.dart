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

    expect(find.text('RECENT RUNS'), findsOneWidget);
    expect(find.text('17 cleared  •  2 misses  •  0.74s avg'), findsOneWidget);
    expect(find.text('17'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
