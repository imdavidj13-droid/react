import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('Share card shows multiple earned performance medals',
      (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.endless,
      score: 28,
      successfulCommands: 28,
      averageTimeSeconds: .61,
      outcome: ReactRunOutcome.missedCommand,
      misses: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ResultShareScreen(result: result, newBest: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PERFECT RUN'), findsOneWidget);
    expect(find.text('LIGHTNING'), findsOneWidget);
    expect(find.text('SURVIVOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily share card uses the frozen run metadata', (tester) async {
    final result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 31,
      successfulCommands: 31,
      averageTimeSeconds: .74,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      dailyDate: DateTime(2026, 8, 14),
      dailyModifierLabel: 'ECHO',
      dailyModifierRule: 'EVERY 6TH CLEAR REPEATS THE COMMAND',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultShareScreen(result: result, newBest: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW MODIFIER BEST'), findsOneWidget);
    expect(find.text('ECHO'), findsOneWidget);
    expect(
      find.text('14 AUG 2026  •  EVERY 6TH CLEAR REPEATS THE COMMAND'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily share never substitutes the current challenge',
      (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 12,
      successfulCommands: 12,
      averageTimeSeconds: .88,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ResultShareScreen(result: result, newBest: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    expect(
      find.text('DATE UNAVAILABLE  •  ONE MISS ENDS THE ATTEMPT'),
      findsOneWidget,
    );
    expect(find.textContaining('60 COMMANDS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pass It share card shows winner, lives, and clutch medal',
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
    expect(find.text('CLUTCH'), findsOneWidget);
    expect(find.text('NEW PERSONAL BEST'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sequence share card uses sequence-specific metrics',
      (tester) async {
    const result = ReactRunResult(
      mode: ReactGameMode.sequence,
      score: 18,
      successfulCommands: 18,
      averageTimeSeconds: 1.42,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
      maxStreak: 9,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ResultShareScreen(result: result, newBest: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SEQUENCE'), findsOneWidget);
    expect(find.text('SEQUENCES CLEARED'), findsOneWidget);
    expect(find.text('SEQUENCES'), findsOneWidget);
    expect(find.text('MISTAKES'), findsOneWidget);
    expect(find.text('AVG CLEAR'), findsOneWidget);
    expect(find.text('OUT OF LIVES'), findsWidgets);
    expect(find.text('18 SEQUENCES • 3 MISTAKES'), findsOneWidget);
    expect(find.text('NEW PERSONAL BEST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
