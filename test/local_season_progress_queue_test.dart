import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/season/data/local_season_progress_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalSeasonProgressQueue.clear();
  });

  test('season progress events persist and decode', () async {
    final completedAt = DateTime.now().toUtc();
    final event = SeasonProgressEvent(
      eventId: 'season-classic-12345678-abcd',
      mode: 'classic',
      score: 42,
      successfulCommands: 42,
      isPersonalBest: true,
      dailyModifier: null,
      completedAt: completedAt,
    );

    await LocalSeasonProgressQueue.enqueue(event);
    final pending = await LocalSeasonProgressQueue.pending();

    expect(pending, hasLength(1));
    expect(pending.single.eventId, event.eventId);
    expect(pending.single.mode, 'classic');
    expect(pending.single.score, 42);
    expect(pending.single.isPersonalBest, isTrue);
    expect(pending.single.completedAt, completedAt);
  });

  test('duplicate event ids are not queued twice', () async {
    final event = SeasonProgressEvent(
      eventId: 'season-daily-12345678-abcd',
      mode: 'daily',
      score: 20,
      successfulCommands: 20,
      isPersonalBest: false,
      dailyModifier: 'SURGE',
      completedAt: DateTime.now().toUtc(),
    );

    await LocalSeasonProgressQueue.enqueue(event);
    await LocalSeasonProgressQueue.enqueue(event);

    expect(await LocalSeasonProgressQueue.pending(), hasLength(1));
  });

  test('legacy queued rows recover mode from event id', () async {
    final completedAt = DateTime.now().toUtc().toIso8601String();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'season_pending_progress_events': <String>[
        '{"event_id":"season-passIt-12345678-abcd","score":12,"successful_commands":12,"is_personal_best":true,"is_daily":false,"completed_at":"$completedAt"}',
      ],
    });

    final pending = await LocalSeasonProgressQueue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.mode, 'passIt');
  });

  test('corrupt queued rows are pruned without hiding valid rows', () async {
    final now = DateTime.now().toUtc();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'season_pending_progress_events': <String>[
        'not-json',
        SeasonProgressEvent(
          eventId: 'season-sequence-33333333-abcd',
          mode: 'sequence',
          score: 9,
          successfulCommands: 9,
          isPersonalBest: false,
          dailyModifier: null,
          completedAt: now,
        ).encode(),
      ],
    });

    final pending = await LocalSeasonProgressQueue.pending();
    final prefs = await SharedPreferences.getInstance();

    expect(pending, hasLength(1));
    expect(prefs.getStringList('season_pending_progress_events'), hasLength(1));
  });

  test('events older than server retention are pruned', () async {
    final old = SeasonProgressEvent(
      eventId: 'season-classic-44444444-abcd',
      mode: 'classic',
      score: 10,
      successfulCommands: 10,
      isPersonalBest: false,
      dailyModifier: null,
      completedAt: DateTime.now().toUtc().subtract(const Duration(days: 31)),
    );
    await LocalSeasonProgressQueue.enqueue(old);

    expect(await LocalSeasonProgressQueue.pending(), isEmpty);
  });

  test('submitted ids are removed without dropping other events', () async {
    final now = DateTime.now().toUtc();
    final first = SeasonProgressEvent(
      eventId: 'season-classic-11111111-abcd',
      mode: 'classic',
      score: 10,
      successfulCommands: 10,
      isPersonalBest: false,
      dailyModifier: null,
      completedAt: now,
    );
    final second = SeasonProgressEvent(
      eventId: 'season-blitz-22222222-abcd',
      mode: 'blitz',
      score: 25,
      successfulCommands: 25,
      isPersonalBest: false,
      dailyModifier: null,
      completedAt: now.add(const Duration(seconds: 1)),
    );

    await LocalSeasonProgressQueue.enqueue(first);
    await LocalSeasonProgressQueue.enqueue(second);
    await LocalSeasonProgressQueue.remove(<String>[first.eventId]);

    final pending = await LocalSeasonProgressQueue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.eventId, second.eventId);
  });
}
