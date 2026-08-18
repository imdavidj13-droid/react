import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('lifetime accuracy persists successful commands and misses', () async {
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.classic,
        score: 16,
        successfulCommands: 16,
        averageTimeSeconds: .74,
        outcome: ReactRunOutcome.missedCommand,
        misses: 3,
        maxStreak: 7,
      ),
    );

    expect(await LocalPlayerStats.lifetimeAccuracy(), closeTo(16 / 19, .0001));
    expect(await LocalPlayerStats.bestCommandStreak(), 7);
  });

  test('legacy run history can recover a missing best streak', () async {
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.classic,
        score: 10,
        successfulCommands: 10,
        averageTimeSeconds: .8,
        outcome: ReactRunOutcome.missedCommand,
        misses: 3,
        maxStreak: 6,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('best_command_streak');

    expect(await LocalPlayerStats.bestCommandStreak(), 6);
  });
}
