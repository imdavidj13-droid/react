import 'dart:convert';

import 'react_run_result.dart';

class ReactRunHistoryEntry {
  const ReactRunHistoryEntry({
    required this.mode,
    required this.score,
    required this.successfulCommands,
    required this.misses,
    required this.averageTimeSeconds,
    required this.outcome,
    required this.playedAt,
  });

  final ReactGameMode mode;
  final int score;
  final int successfulCommands;
  final int misses;
  final double averageTimeSeconds;
  final ReactRunOutcome outcome;
  final DateTime playedAt;

  factory ReactRunHistoryEntry.fromResult(
    ReactRunResult result, {
    DateTime? playedAt,
  }) {
    return ReactRunHistoryEntry(
      mode: result.mode,
      score: result.score,
      successfulCommands: result.successfulCommands,
      misses: result.misses,
      averageTimeSeconds: result.averageTimeSeconds,
      outcome: result.outcome,
      playedAt: playedAt ?? DateTime.now(),
    );
  }

  String encode() => jsonEncode({
        'mode': mode.name,
        'score': score,
        'successfulCommands': successfulCommands,
        'misses': misses,
        'averageTimeSeconds': averageTimeSeconds,
        'outcome': outcome.name,
        'playedAt': playedAt.toIso8601String(),
      });

  static ReactRunHistoryEntry? tryDecode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ReactRunHistoryEntry(
        mode: ReactGameMode.values.byName(map['mode'] as String),
        score: map['score'] as int,
        successfulCommands: map['successfulCommands'] as int,
        misses: map['misses'] as int,
        averageTimeSeconds: (map['averageTimeSeconds'] as num).toDouble(),
        outcome: ReactRunOutcome.values.byName(map['outcome'] as String),
        playedAt: DateTime.parse(map['playedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
