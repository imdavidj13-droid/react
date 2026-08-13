import 'dart:math';

import '../../../core/settings/react_settings.dart';

const int target = 60;

enum DailyModifier {
  lightsOut,
  surge,
  noClock,
  echo,
  reverse,
  chain,
  redline,
}

extension DailyModifierUi on DailyModifier {
  String get label => switch (this) {
        DailyModifier.lightsOut => 'LIGHTS OUT',
        DailyModifier.surge => 'SURGE',
        DailyModifier.noClock => 'NO CLOCK',
        DailyModifier.echo => 'ECHO',
        DailyModifier.reverse => 'REVERSE',
        DailyModifier.chain => 'CHAIN',
        DailyModifier.redline => 'REDLINE',
      };

  String get shortRule => switch (this) {
        DailyModifier.lightsOut => 'COMMAND VANISHES AFTER 650MS',
        DailyModifier.surge => 'RAPID-FIRE BURSTS EVERY 5 CLEARS',
        DailyModifier.noClock => 'NO COUNTDOWN OR TIMER RING',
        DailyModifier.echo => 'EVERY 6TH CLEAR REPEATS THE COMMAND',
        DailyModifier.reverse => 'DIRECTIONAL SWIPES ARE REVERSED',
        DailyModifier.chain => 'ALMOST NO GAP BETWEEN COMMANDS',
        DailyModifier.redline => 'EVERY 10TH COMMAND HITS REDLINE',
      };

  String get description => switch (this) {
        DailyModifier.lightsOut =>
          'Read fast. The command text and icon disappear after 650ms, but the reaction window keeps running.',
        DailyModifier.surge =>
          'Every fifth clear triggers a three-command rapid-fire burst with much tighter timing and almost no transition gap.',
        DailyModifier.noClock =>
          'The command stays visible, but the countdown number and progress ring are hidden. React by feel, not by watching the clock.',
        DailyModifier.echo =>
          'Every sixth successful command immediately returns once more. Recognise the repeat and execute it again under pressure.',
        DailyModifier.reverse =>
          'Directional swipe commands must be performed in the opposite direction. Other commands behave normally.',
        DailyModifier.chain =>
          'The usual breathing room is almost gone. New commands arrive almost immediately after every success.',
        DailyModifier.redline =>
          'Every tenth command is clearly marked REDLINE and gets a sharply reduced reaction window.',
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

  factory DailyChallenge.forDate(
    DateTime input, {
    DailyModifier? modifierOverride,
  }) {
    final date = DateTime(input.year, input.month, input.day);
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final id = '${date.year}-${dayOfYear.toString().padLeft(3, '0')}';

    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekSeed =
        weekStart.year * 10000 + weekStart.month * 100 + weekStart.day;
    final weeklyDeck = List<DailyModifier>.of(DailyModifier.values)
      ..shuffle(Random(weekSeed));
    final modifier = modifierOverride ?? weeklyDeck[date.weekday - 1];

    return DailyChallenge._(
      date: date,
      seed: seed,
      id: id,
      modifier: modifier,
    );
  }

  static DailyChallenge today() {
    DailyModifier? override;
    if (ReactSettings.dailyDevOverrideEnabled) {
      for (final modifier in DailyModifier.values) {
        if (modifier.name == ReactSettings.dailyDevModifier) {
          override = modifier;
          break;
        }
      }
    }
    return DailyChallenge.forDate(DateTime.now(), modifierOverride: override);
  }

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
