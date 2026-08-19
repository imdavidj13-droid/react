import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/season/data/local_season_progress_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalSeasonProgressQueue.clear();
  });

  test('season progress events persist and decode', () async {
    const event = SeasonProgressEvent(
      eventId: 'season-classic-12345678-abcd',
      score: 42,
      successfulCommands: 42,
      isPersonalBest: true,
      isDaily: false,
    );

    await LocalSeasonProgressQueue.enqueue(event);
    final pending = await LocalSeasonProgressQueue.pending();

    expect(pending, hasLength(1));
    expect(pending.single.eventId, event.eventId);
    expect(pending.single.score, 42);
    expect(pending.single.isPersonalBest, isTrue);
  });

  test('duplicate event ids are not queued twice', () async {
    const event = SeasonProgressEvent(
      eventId: 'season-daily-12345678-abcd',
      score: 20,
      successfulCommands: 20,
      isPersonalBest: false,
      isDaily: true,
    );

    await LocalSeasonProgressQueue.enqueue(event);
    await LocalSeasonProgressQueue.enqueue(event);

    expect(await LocalSeasonProgressQueue.pending(), hasLength(1));
  });

  test('submitted ids are removed without dropping other events', () async {
    const first = SeasonProgressEvent(
      eventId: 'season-classic-11111111-abcd',
      score: 10,
      successfulCommands: 10,
      isPersonalBest: false,
      isDaily: false,
    );
    const second = SeasonProgressEvent(
      eventId: 'season-blitz-22222222-abcd',
      score: 25,
      successfulCommands: 25,
      isPersonalBest: false,
      isDaily: false,
    );

    await LocalSeasonProgressQueue.enqueue(first);
    await LocalSeasonProgressQueue.enqueue(second);
    await LocalSeasonProgressQueue.remove(<String>[first.eventId]);

    final pending = await LocalSeasonProgressQueue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.eventId, second.eventId);
  });
}
