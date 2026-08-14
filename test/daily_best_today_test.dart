import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.dailyDevOverrideEnabled = false;
    ReactSettings.dailyDevRunActive = false;
  });

  ReactRunResult dailyResult(int score) => ReactRunResult(
        mode: ReactGameMode.daily,
        score: score,
        successfulCommands: score,
        averageTimeSeconds: .8,
        outcome: ReactRunOutcome.missedCommand,
        misses: 1,
      );

  test('Daily best today keeps the strongest retry', () async {
    expect(await LocalPlayerStats.dailyBestToday(), 0);

    await LocalPlayerStats.recordResult(dailyResult(18));
    expect(await LocalPlayerStats.dailyBestToday(), 18);

    await LocalPlayerStats.recordResult(dailyResult(11));
    expect(await LocalPlayerStats.dailyBestToday(), 18);

    await LocalPlayerStats.recordResult(dailyResult(27));
    expect(await LocalPlayerStats.dailyBestToday(), 27);
  });
}
