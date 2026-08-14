import 'react_command.dart';
import 'react_command_performance.dart';

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
    this.maxStreak = 0,
    this.failedCommand,
    this.winnerPlayer,
    this.playerLives,
    this.playerClears,
    this.dailyDate,
    this.dailyModifierLabel,
    this.dailyModifierRule,
    this.commandPerformance = const <ReactCommand, ReactCommandPerformance>{},
  });

  final ReactGameMode mode;
  final int score;
  final int successfulCommands;
  final double averageTimeSeconds;
  final ReactRunOutcome outcome;
  final int misses;

  /// Longest uninterrupted sequence of successful commands in this run.
  /// Older/tests results can safely omit it and receive 0.
  final int maxStreak;

  final ReactCommand? failedCommand;
  final int? winnerPlayer;
  final List<int>? playerLives;

  /// Per-player clears for Pass It, in player order.
  final List<int>? playerClears;

  /// Snapshot of the Daily challenge identity used for this run. Keeping this
  /// on the result prevents Results/Share changing if midnight passes while
  /// the result screen is still open.
  final DateTime? dailyDate;
  final String? dailyModifierLabel;
  final String? dailyModifierRule;

  final Map<ReactCommand, ReactCommandPerformance> commandPerformance;

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
