import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/results/domain/run_medal.dart';

void main() {
  test('Daily Master remains attainable in uncapped Daily', () {
    const result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 60,
      successfulCommands: 60,
      averageTimeSeconds: .78,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 60,
    );

    expect(earnedRunMedals(result), contains(RunMedal.dailyMaster));
  });

  test('Daily Master is not awarded below sixty clears', () {
    const result = ReactRunResult(
      mode: ReactGameMode.daily,
      score: 59,
      successfulCommands: 59,
      averageTimeSeconds: .78,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
      maxStreak: 59,
    );

    expect(earnedRunMedals(result), isNot(contains(RunMedal.dailyMaster)));
  });

  test('Sequence final life losses do not masquerade as a perfect run', () {
    const result = ReactRunResult(
      mode: ReactGameMode.sequence,
      score: 20,
      successfulCommands: 20,
      averageTimeSeconds: 1.3,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
      maxStreak: 12,
    );

    expect(earnedRunMedals(result), isNot(contains(RunMedal.perfectRun)));
  });
}
