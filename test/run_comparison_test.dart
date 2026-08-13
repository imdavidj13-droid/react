import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_run_history_entry.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/results/domain/run_comparison.dart';

void main() {
  final previous = ReactRunHistoryEntry(
    mode: ReactGameMode.classic,
    score: 18,
    successfulCommands: 18,
    misses: 3,
    averageTimeSeconds: .84,
    outcome: ReactRunOutcome.missedCommand,
    playedAt: DateTime(2026, 8, 12),
  );

  test('compares score and reaction time against previous same-mode run', () {
    const current = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 22,
      successfulCommands: 22,
      averageTimeSeconds: .76,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
    );

    final comparison = RunComparison.againstPrevious(current, previous);

    expect(comparison, isNotNull);
    expect(comparison!.scoreDelta, 4);
    expect(comparison.scoreLabel, '+4 VS LAST RUN');
    expect(comparison.fasterReaction, isTrue);
    expect(comparison.reactionLabel, '0.08s FASTER');
  });

  test('reports lower score and slower reaction time', () {
    const current = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 15,
      successfulCommands: 15,
      averageTimeSeconds: .91,
      outcome: ReactRunOutcome.missedCommand,
      misses: 3,
    );

    final comparison = RunComparison.againstPrevious(current, previous)!;

    expect(comparison.scoreLabel, '-3 VS LAST RUN');
    expect(comparison.reactionLabel, '0.07s SLOWER');
  });

  test('does not compare against a different mode', () {
    const current = ReactRunResult(
      mode: ReactGameMode.endless,
      score: 22,
      successfulCommands: 22,
      averageTimeSeconds: .76,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );

    expect(RunComparison.againstPrevious(current, previous), isNull);
  });

  test('omits reaction comparison when either run has no average', () {
    const current = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 0,
      successfulCommands: 0,
      averageTimeSeconds: 0,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );

    final comparison = RunComparison.againstPrevious(current, previous)!;

    expect(comparison.scoreLabel, '-18 VS LAST RUN');
    expect(comparison.reactionLabel, isNull);
  });
}
