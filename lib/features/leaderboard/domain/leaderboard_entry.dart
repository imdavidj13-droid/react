class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.displayName,
    required this.score,
    required this.isCurrentPlayer,
    this.rank,
    this.averageReactionSeconds,
    this.recordedAt,
    this.dailyDate,
    this.dailyModifierLabel,
  });

  final String playerId;
  final String displayName;
  final int score;
  final bool isCurrentPlayer;
  final int? rank;
  final double? averageReactionSeconds;
  final DateTime? recordedAt;
  final DateTime? dailyDate;
  final String? dailyModifierLabel;

  LeaderboardEntry copyWith({
    int? rank,
    double? averageReactionSeconds,
    DateTime? recordedAt,
    DateTime? dailyDate,
    String? dailyModifierLabel,
  }) {
    return LeaderboardEntry(
      playerId: playerId,
      displayName: displayName,
      score: score,
      isCurrentPlayer: isCurrentPlayer,
      rank: rank ?? this.rank,
      averageReactionSeconds:
          averageReactionSeconds ?? this.averageReactionSeconds,
      recordedAt: recordedAt ?? this.recordedAt,
      dailyDate: dailyDate ?? this.dailyDate,
      dailyModifierLabel: dailyModifierLabel ?? this.dailyModifierLabel,
    );
  }
}
