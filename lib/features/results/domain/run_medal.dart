import '../../gameplay/domain/react_run_result.dart';

enum RunMedal {
  perfectRun,
  lightning,
  survivor,
  dailyMaster,
  clutch,
}

List<RunMedal> earnedRunMedals(ReactRunResult result) {
  final medals = <RunMedal>[];

  if (result.successfulCommands > 0 && result.misses == 0) {
    medals.add(RunMedal.perfectRun);
  }
  if (result.averageTimeSeconds > 0 && result.averageTimeSeconds <= .65) {
    medals.add(RunMedal.lightning);
  }
  if (result.mode == ReactGameMode.endless && result.score >= 25) {
    medals.add(RunMedal.survivor);
  }
  if (result.mode == ReactGameMode.daily && result.score >= 60) {
    medals.add(RunMedal.dailyMaster);
  }
  if (result.mode == ReactGameMode.passIt &&
      result.outcome == ReactRunOutcome.winner &&
      result.winnerPlayer != null &&
      result.playerLives != null) {
    final winnerIndex = result.winnerPlayer! - 1;
    if (winnerIndex >= 0 &&
        winnerIndex < result.playerLives!.length &&
        result.playerLives![winnerIndex] == 1) {
      medals.add(RunMedal.clutch);
    }
  }

  return List<RunMedal>.unmodifiable(medals);
}
