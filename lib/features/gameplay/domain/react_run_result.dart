import 'react_command.dart';

enum ReactGameMode {
  classic,
  blitz,
  endless,
  daily,
  passIt,
}

extension ReactGameModeUi on ReactGameMode {
  String get label => switch (this) {
        ReactGameMode.classic => 'CLASSIC',
        ReactGameMode.blitz => 'BLITZ',
        ReactGameMode.endless => 'ENDLESS',
        ReactGameMode.daily => 'DAILY',
        ReactGameMode.passIt => 'PASS IT',
      };
}

enum ReactRunOutcome {
  missedCommand,
  timeUp,
  completed,
  winner,
  quit,
}

class ReactRunResult {
  const ReactRunResult({
    required this.mode,
    required this.score,
    required this.successfulCommands,
    required this.averageTimeSeconds,
    required this.outcome,
    this.misses = 0,
    this.failedCommand,
    this.winnerPlayer,
    this.playerLives,
  });

  final ReactGameMode mode;
  final int score;
  final int successfulCommands;
  final double averageTimeSeconds;
  final ReactRunOutcome outcome;
  final int misses;
  final ReactCommand? failedCommand;
  final int? winnerPlayer;
  final List<int>? playerLives;

  String get outcomeLabel => switch (outcome) {
        ReactRunOutcome.missedCommand => 'RUN OVER',
        ReactRunOutcome.timeUp => 'TIME UP',
        ReactRunOutcome.completed => 'COMPLETE',
        ReactRunOutcome.winner => winnerPlayer == null
            ? 'WINNER'
            : 'PLAYER $winnerPlayer WINS',
        ReactRunOutcome.quit => 'RUN ENDED',
      };
}
