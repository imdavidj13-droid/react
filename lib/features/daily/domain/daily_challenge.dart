enum DailyModifier {
  lightsOut,
  surge,
  noClock,
}

extension DailyModifierUi on DailyModifier {
  String get label => switch (this) {
        DailyModifier.lightsOut => 'LIGHTS OUT',
        DailyModifier.surge => 'SURGE',
        DailyModifier.noClock => 'NO CLOCK',
      };

  String get shortRule => switch (this) {
        DailyModifier.lightsOut => 'COMMAND VANISHES AFTER 650MS',
        DailyModifier.surge => 'RAPID-FIRE BURSTS EVERY 5 CLEARS',
        DailyModifier.noClock => 'NO COUNTDOWN OR TIMER RING',
      };

  String get description => switch (this) {
        DailyModifier.lightsOut =>
          'Read fast. The command text and icon disappear after 650ms, but the reaction window keeps running.',
        DailyModifier.surge =>
          'Every fifth clear triggers a three-command rapid-fire burst with much tighter timing and almost no transition gap.',
        DailyModifier.noClock =>
          'The command stays visible, but the countdown number and progress ring are hidden. React by feel, not by watching the clock.',
      };
}

class DailyChallenge {
  const DailyChallenge._({
    required this.date,
    required this.seed,
    required this.id,
    required this.modifier,
  });

  final DateTime date;
  final int seed;
  final String id;
  final DailyModifier modifier;

  factory DailyChallenge.forDate(DateTime input) {
    final date = DateTime(input.year, input.month, input.day);
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final id = '${date.year}-${dayOfYear.toString().padLeft(3, '0')}';
    final modifier = DailyModifier.values[(dayOfYear - 1) % DailyModifier.values.length];

    return DailyChallenge._(
      date: date,
      seed: seed,
      id: id,
      modifier: modifier,
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
