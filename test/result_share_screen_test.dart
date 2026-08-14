import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/results/presentation/result_share_screen.dart';

void main() {
  testWidgets('Share result preview fits a 320x640 screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const result = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 42,
      successfulCommands: 42,
      averageTimeSeconds: .68,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ResultShareScreen(result: result, newBest: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHARE RESULT'), findsOneWidget);
    expect(find.text('SHARE IMAGE'), findsOneWidget);
    expect(find.text('NEW PERSONAL BEST'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily share card identifies today modifier', (tester) async {
    final challenge = DailyChallenge.today();
    const result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 31,
      successfulCommands: 31,
      averageTimeSeconds: .74,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ResultShareScreen(result: result, newBest: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW MODIFIER BEST'), findsOneWidget);
    expect(find.text(challenge.modifier.label), findsOneWidget);
    expect(find.textContaining(challenge.dateLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pass It share card shows winner and remaining lives',
      (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.passIt,
      score: 23,
      successfulCommands: 23,
      averageTimeSeconds: .81,
      outcome: ReactRunOutcome.winner,
      misses: 7,
      winnerPlayer: 2,
      playerLives: [0, 1, 0],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ResultShareScreen(result: result, newBest: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PLAYER 2 WINS'), findsWidgets);
    expect(find.text('P1 0♥  •  P2 1♥  •  P3 0♥'), findsOneWidget);
    expect(find.text('NEW PERSONAL BEST'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
