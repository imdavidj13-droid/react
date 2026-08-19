import 'dart:math';

import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import 'season_repository.dart';

class SeasonProgressService {
  const SeasonProgressService._();

  static const _repository = SeasonRepository();

  static Future<void> recordResult(ReactRunResult result) async {
    if (result.isDailyDevRun || result.outcome == ReactRunOutcome.quit) return;

    final isPersonalBest = await _isNewPersonalBest(result);
    final completedAt = DateTime.now().toUtc();
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    final eventId =
        'season-${result.mode.name}-${completedAt.microsecondsSinceEpoch}-$random';

    await _repository.recordRun(
      eventId: eventId,
      score: result.score,
      successfulCommands: result.successfulCommands,
      isPersonalBest: isPersonalBest,
      isDaily: result.mode == ReactGameMode.daily,
    );
  }

  static Future<bool> _isNewPersonalBest(ReactRunResult result) async {
    if (result.mode == ReactGameMode.passIt) return false;
    final currentBest = await LocalPlayerStats.bestFor(result.mode);
    if (result.score != currentBest || result.score <= 0) return false;

    // Results persistence has already inserted the current run at the front of
    // recent history. If an earlier run in retained history already reached
    // this score, this is a tie rather than a new PB.
    final recent = await LocalPlayerStats.recentRuns();
    final priorModeRuns = recent
        .where((entry) => entry.mode == result.mode)
        .skip(1);
    return priorModeRuns.every((entry) => entry.score < result.score);
  }
}
