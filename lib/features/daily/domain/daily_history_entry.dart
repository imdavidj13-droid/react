import '../../gameplay/domain/react_run_result.dart';
import 'daily_challenge.dart';

class DailyHistoryEntry {
  const DailyHistoryEntry({
    required this.date,
    required this.modifier,
    required this.attempted,
    this.score,
    this.outcome,
  });

  final DateTime date;
  final DailyModifier modifier;
  final bool attempted;
  final int? score;
  final ReactRunOutcome? outcome;

  bool get completed => outcome == ReactRunOutcome.completed;
  bool get failed => outcome == ReactRunOutcome.missedCommand;

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
        'date': dateKey,
        'modifier': modifier.name,
        'attempted': attempted,
        'score': score,
        'outcome': outcome?.name,
      };

  static DailyHistoryEntry? tryFromJson(Map<String, dynamic> json) {
    try {
      final date = DateTime.parse(json['date'] as String);
      final modifier = DailyModifier.values.byName(json['modifier'] as String);
      final outcomeName = json['outcome'] as String?;
      return DailyHistoryEntry(
        date: DateTime(date.year, date.month, date.day),
        modifier: modifier,
        attempted: json['attempted'] as bool? ?? false,
        score: json['score'] as int?,
        outcome: outcomeName == null
            ? null
            : ReactRunOutcome.values.byName(outcomeName),
      );
    } catch (_) {
      return null;
    }
  }
}
