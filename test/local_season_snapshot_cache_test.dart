import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/season/data/local_season_snapshot_cache.dart';
import 'package:react/features/season/domain/season_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SeasonSnapshot snapshot({required DateTime endsAt, int charge = 1450}) =>
      SeasonSnapshot(
        id: 'season-cache',
        code: 'S01_OVERDRIVE',
        name: 'SEASON 01 — OVERDRIVE',
        subtitle: 'PUSH THE LIMIT',
        themeKey: 'overdrive',
        startsAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        endsAt: endsAt.toUtc(),
        charge: charge,
        premiumOwned: false,
        tiers: const <SeasonTier>[],
        missions: const <SeasonMission>[],
        unlockedRewardKeys: const <String>{},
      );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('last-known CHARGE survives reload while the season is active', () async {
    await LocalSeasonSnapshotCache.save(
      snapshot(endsAt: DateTime.now().toUtc().add(const Duration(days: 5))),
    );

    expect(await LocalSeasonSnapshotCache.charge(), 1450);
    expect(await LocalSeasonSnapshotCache.seasonCode(), 'S01_OVERDRIVE');
  });

  test('expired season cache cannot masquerade as current CHARGE', () async {
    await LocalSeasonSnapshotCache.save(
      snapshot(endsAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1))),
    );

    expect(await LocalSeasonSnapshotCache.charge(), isNull);
    expect(await LocalSeasonSnapshotCache.seasonCode(), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('season_last_known_charge'), isNull);
    expect(prefs.getString('season_last_known_code'), isNull);
    expect(prefs.getString('season_last_known_ends_at'), isNull);
  });
}
