import 'react_command.dart';
import 'react_command_performance.dart';

class RunCommandPerformanceTracker {
  RunCommandPerformanceTracker() : _stats = emptyCommandPerformance();

  final Map<ReactCommand, ReactCommandPerformance> _stats;

  void recordSuccess(ReactCommand command, int responseMs) {
    _stats[command] = _stats[command]!.recordSuccess(responseMs);
  }

  void recordMiss(ReactCommand command) {
    _stats[command] = _stats[command]!.recordMiss();
  }

  Map<ReactCommand, ReactCommandPerformance> snapshot() =>
      Map<ReactCommand, ReactCommandPerformance>.unmodifiable(_stats);
}
