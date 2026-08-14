import 'dart:convert';

import '../../gameplay/domain/react_run_result.dart';

class LeaderboardSubmission {
  const LeaderboardSubmission({
    required this.clientSubmissionId,
    required this.mode,
    required this.score,
    required this.successfulCommands,
    required this.averageReactionSeconds,
    required this.misses,
    required this.maxStreak,
    required this.outcome,
    required this.completedAt,
    this.dailyDate,
    this.dailyModifierLabel,
  });

  static const schemaVersion = 1;

  final String clientSubmissionId;
  final ReactGameMode mode;
  final int score;
  final int successfulCommands;
  final double averageReactionSeconds;
  final int misses;
  final int maxStreak;
  final ReactRunOutcome outcome;
  final DateTime completedAt;
  final DateTime? dailyDate;
  final String? dailyModifierLabel;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'clientSubmissionId': clientSubmissionId,
        'mode': mode.name,
        'score': score,
        'successfulCommands': successfulCommands,
        'averageReactionSeconds': averageReactionSeconds,
        'misses': misses,
        'maxStreak': maxStreak,
        'outcome': outcome.name,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'dailyDate': dailyDate?.toIso8601String(),
        'dailyModifierLabel': dailyModifierLabel,
      };

  String encode() => jsonEncode(toJson());

  static LeaderboardSubmission? tryDecode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if ((map['schemaVersion'] as int? ?? 0) != schemaVersion) return null;
      return LeaderboardSubmission(
        clientSubmissionId: map['clientSubmissionId'] as String,
        mode: ReactGameMode.values.byName(map['mode'] as String),
        score: map['score'] as int,
        successfulCommands: map['successfulCommands'] as int,
        averageReactionSeconds:
            (map['averageReactionSeconds'] as num).toDouble(),
        misses: map['misses'] as int,
        maxStreak: map['maxStreak'] as int,
        outcome: ReactRunOutcome.values.byName(map['outcome'] as String),
        completedAt: DateTime.parse(map['completedAt'] as String),
        dailyDate: map['dailyDate'] == null
            ? null
            : DateTime.parse(map['dailyDate'] as String),
        dailyModifierLabel: map['dailyModifierLabel'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
