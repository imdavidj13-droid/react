import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';

void main() {
  test('builds a stable seed from the calendar date', () {
    final challenge = DailyChallenge.forDate(DateTime(2026, 8, 12, 18, 45));

    expect(challenge.seed, 20260812);
    expect(challenge.date, DateTime(2026, 8, 12));
    expect(challenge.id, '2026-224');
    expect(challenge.dateLabel, '12 AUG 2026');
  });

  test('day-of-year identity handles leap years correctly', () {
    final leapDay = DailyChallenge.forDate(DateTime(2028, 2, 29));
    final dayAfter = DailyChallenge.forDate(DateTime(2028, 3, 1));

    expect(leapDay.id, '2028-060');
    expect(dayAfter.id, '2028-061');
  });

  test('each Monday to Sunday week uses every modifier exactly once', () {
    final monday = DateTime(2026, 8, 10);
    final modifiers = <DailyModifier>{};

    for (var offset = 0; offset < 7; offset++) {
      modifiers.add(
        DailyChallenge.forDate(monday.add(Duration(days: offset))).modifier,
      );
    }

    expect(modifiers.length, DailyModifier.values.length);
    expect(modifiers, containsAll(DailyModifier.values));
  });

  test('weekly modifier order is deterministic', () {
    final date = DateTime(2026, 8, 13);
    final first = DailyChallenge.forDate(date);
    final second = DailyChallenge.forDate(date);

    expect(first.modifier, second.modifier);
    expect(first.seed, second.seed);
  });

  test('explicit developer modifier override wins over the weekly deck', () {
    final challenge = DailyChallenge.forDate(
      DateTime(2026, 8, 13),
      modifierOverride: DailyModifier.redline,
    );

    expect(challenge.modifier, DailyModifier.redline);
  });

  test('each modifier has player-facing rule copy', () {
    expect(DailyModifier.values.length, 7);
    for (final modifier in DailyModifier.values) {
      expect(modifier.label, isNotEmpty);
      expect(modifier.shortRule, isNotEmpty);
      expect(modifier.description, isNotEmpty);
    }
  });

  test('Daily target is sixty commands', () {
    expect(dailyTarget, 60);
  });

  test('next reset is local midnight on the following day', () {
    final challenge = DailyChallenge.forDate(DateTime(2026, 12, 31, 23, 59));

    expect(challenge.nextReset, DateTime(2027, 1, 1));
  });
}
