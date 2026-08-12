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

  test('next reset is local midnight on the following day', () {
    final challenge = DailyChallenge.forDate(DateTime(2026, 12, 31, 23, 59));

    expect(challenge.nextReset, DateTime(2027, 1, 1));
  });
}
