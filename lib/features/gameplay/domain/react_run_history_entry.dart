import 'dart:convert';

import 'react_command.dart';
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
    this.maxStreak = 0,
    this.failedCommand,
    this.winnerPlayer,
    this.playerLives,
    this.playerClears,
    this.dailyDate,
    this.dailyModifierLabel,
    this.strongestCommand,
    this.weakestCommand,
  });

  final ReactGameMode mode;
  final int score;
  final int successfulCommands;
  final int misses;
  final double averageTimeSeconds;
  final ReactRunOutcome outcome;
  final DateTime playedAt;
  final int maxStreak;
  final String? failedCommand;
  final int? winnerPlayer;
  final List<int>? playerLives;
  final List<int>? playerClears;
  final DateTime? dailyDate;
  final String? dailyModifierLabel;
  final String? strongestCommand;
  final String? weakestCommand;

  factory ReactRunHistoryEntry.fromResult(
    ReactRunResult result, {
    DateTime? playedAt,
  }) {
    final attempted = result.commandPerformance.values
        .where((item) => item.attempts > 0)
        .toList(growable: false);
    final successful = attempted
        .where((item) => item.successes > 0)
        .toList(growable: false);

    successful.sort(
      (a, b) => a.averageReactionSeconds.compareTo(b.averageReactionSeconds),
    );
    attempted.sort((a, b) {
      final accuracy = a.accuracy.compareTo(b.accuracy);
      if (accuracy != 0) return accuracy;
      return b.averageReactionSeconds.compareTo(a.averageReactionSeconds);
    });

    return ReactRunHistoryEntry(
      mode: result.mode,
      score: result.score,
      successfulCommands: result.successfulCommands,
      misses: result.misses,
      averageTimeSeconds: result.averageTimeSeconds,
      outcome: result.outcome,
      playedAt: playedAt ?? DateTime.now(),
      maxStreak: result.maxStreak,
      failedCommand: result.failedCommand?.title,
      winnerPlayer: result.winnerPlayer,
      playerLives: result.playerLives,
      playerClears: result.playerClears,
      dailyDate: result.dailyDate,
      dailyModifierLabel: result.dailyModifierLabel,
      strongestCommand: successful.isEmpty
          ? null
          : successful.first.command.title,
      weakestCommand: attempted.isEmpty ? null : attempted.first.command.title,
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
    'maxStreak': maxStreak,
    'failedCommand': failedCommand,
    'winnerPlayer': winnerPlayer,
    'playerLives': playerLives,
    'playerClears': playerClears,
    'dailyDate': dailyDate?.toIso8601String(),
    'dailyModifierLabel': dailyModifierLabel,
    'strongestCommand': strongestCommand,
    'weakestCommand': weakestCommand,
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
        maxStreak: map['maxStreak'] as int? ?? 0,
        failedCommand: map['failedCommand'] as String?,
        winnerPlayer: map['winnerPlayer'] as int?,
        playerLives: (map['playerLives'] as List<dynamic>?)
            ?.map((value) => value as int)
            .toList(growable: false),
        playerClears: (map['playerClears'] as List<dynamic>?)
            ?.map((value) => value as int)
            .toList(growable: false),
        dailyDate: map['dailyDate'] == null
            ? null
            : DateTime.parse(map['dailyDate'] as String),
        dailyModifierLabel: map['dailyModifierLabel'] as String?,
        strongestCommand: map['strongestCommand'] as String?,
        weakestCommand: map['weakestCommand'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
