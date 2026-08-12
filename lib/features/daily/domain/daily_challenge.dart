class DailyChallenge {
  const DailyChallenge._({
    required this.date,
    required this.seed,
    required this.id,
  });

  final DateTime date;
  final int seed;
  final String id;

  factory DailyChallenge.forDate(DateTime input) {
    final date = DateTime(input.year, input.month, input.day);
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final id = '${date.year}-${dayOfYear.toString().padLeft(3, '0')}';

    return DailyChallenge._(
      date: date,
      seed: seed,
      id: id,
    );
  }

  static DailyChallenge today() => DailyChallenge.forDate(DateTime.now());

  String get dateLabel {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  DateTime get nextReset => date.add(const Duration(days: 1));
}
