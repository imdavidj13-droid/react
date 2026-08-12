import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';

void main() {
  test('mode labels remain stable for results and navigation', () {
    expect(ReactGameMode.classic.label, 'CLASSIC');
    expect(ReactGameMode.blitz.label, 'BLITZ');
    expect(ReactGameMode.endless.label, 'ENDLESS');
    expect(ReactGameMode.daily.label, 'DAILY');
    expect(ReactGameMode.passIt.label, 'PASS IT');
  });

  test('winner result includes the winning player in its label', () {
    const result = ReactRunResult(
      mode: ReactGameMode.passIt,
      score: 14,
      successfulCommands: 14,
      averageTimeSeconds: .91,
      outcome: ReactRunOutcome.winner,
      winnerPlayer: 2,
      playerLives: [0, 1, 0],
    );

    expect(result.outcomeLabel, 'PLAYER 2 WINS');
  });

  test('blitz time-up result uses the correct outcome label', () {
    const result = ReactRunResult(
      mode: ReactGameMode.blitz,
      score: 22,
      successfulCommands: 22,
      averageTimeSeconds: .74,
      outcome: ReactRunOutcome.timeUp,
      misses: 2,
    );

    expect(result.outcomeLabel, 'TIME UP');
  });

  test('daily completion is not described as a miss', () {
    const result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 20,
      successfulCommands: 20,
      averageTimeSeconds: .88,
      outcome: ReactRunOutcome.completed,
    );

    expect(result.outcomeLabel, 'COMPLETE');
  });
}
