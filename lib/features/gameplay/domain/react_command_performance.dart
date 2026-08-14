import 'react_command.dart';

class ReactCommandPerformance {
  const ReactCommandPerformance({
    required this.command,
    this.attempts = 0,
    this.successes = 0,
    this.totalResponseMs = 0,
  });

  final ReactCommand command;
  final int attempts;
  final int successes;
  final int totalResponseMs;

  int get misses => attempts - successes;
  double get accuracy => attempts == 0 ? 0 : successes / attempts;
  double get averageReactionSeconds =>
      successes == 0 ? 0 : (totalResponseMs / successes) / 1000;

  ReactCommandPerformance recordSuccess(int responseMs) =>
      ReactCommandPerformance(
        command: command,
        attempts: attempts + 1,
        successes: successes + 1,
        totalResponseMs: totalResponseMs + responseMs,
      );

  ReactCommandPerformance recordMiss() => ReactCommandPerformance(
        command: command,
        attempts: attempts + 1,
        successes: successes,
        totalResponseMs: totalResponseMs,
      );

  ReactCommandPerformance add(ReactCommandPerformance other) {
    assert(other.command == command);
    return ReactCommandPerformance(
      command: command,
      attempts: attempts + other.attempts,
      successes: successes + other.successes,
      totalResponseMs: totalResponseMs + other.totalResponseMs,
    );
  }
}

Map<ReactCommand, ReactCommandPerformance> emptyCommandPerformance() => {
      for (final command in ReactCommand.values)
        command: ReactCommandPerformance(command: command),
    };
