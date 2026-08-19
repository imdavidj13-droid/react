import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/season/data/season_cosmetic_state.dart';
import 'package:react/features/season/domain/season_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const frame = SeasonReward(
    id: 'frame-1',
    tier: 5,
    track: SeasonRewardTrack.premium,
    kind: 'profile_frame',
    rewardKey: 'frame_overdrive_01',
    name: 'OVERDRIVE FRAME',
    description: 'Milestone profile frame',
    milestone: true,
  );

  const badge = SeasonReward(
    id: 'badge-1',
    tier: 1,
    track: SeasonRewardTrack.premium,
    kind: 'profile_badge',
    rewardKey: 'badge_overdrive_01',
    name: 'IGNITION BADGE',
    description: 'Overdrive profile badge',
    milestone: false,
  );

  SeasonSnapshot snapshot(Set<String> unlocked) => SeasonSnapshot(
        id: 'season-1',
        code: 'S01_OVERDRIVE',
        name: 'SEASON 01 — OVERDRIVE',
        subtitle: 'PUSH THE LIMIT',
        themeKey: 'overdrive',
        startsAt: DateTime.utc(2026, 8, 19),
        endsAt: DateTime.utc(2026, 9, 9),
        charge: 800,
        premiumOwned: true,
        tiers: const <SeasonTier>[
          SeasonTier(
            number: 5,
            chargeRequired: 800,
            milestone: true,
            rewards: <SeasonReward>[frame, badge],
          ),
        ],
        missions: const <SeasonMission>[],
        unlockedRewardKeys: unlocked,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SeasonCosmeticState.load();
  });

  test('server snapshot controls season cosmetic ownership', () async {
    await SeasonCosmeticState.syncSnapshot(
      snapshot(<String>{frame.rewardKey}),
    );

    expect(SeasonCosmeticState.isOwned(frame.rewardKey), isTrue);
    expect(SeasonCosmeticState.isOwned(badge.rewardKey), isFalse);
  });

  test('only unlocked season cosmetics can be equipped', () async {
    await SeasonCosmeticState.syncSnapshot(
      snapshot(<String>{frame.rewardKey}),
    );

    expect(await SeasonCosmeticState.equip(frame), isTrue);
    expect(await SeasonCosmeticState.equip(badge), isFalse);
    expect(SeasonCosmeticState.isEquipped(frame), isTrue);
    expect(SeasonCosmeticState.equippedKey('profile_frame'), frame.rewardKey);
  });

  test('equipped season cosmetics survive reload', () async {
    await SeasonCosmeticState.syncSnapshot(
      snapshot(<String>{frame.rewardKey}),
    );
    await SeasonCosmeticState.equip(frame);
    await SeasonCosmeticState.load();

    expect(SeasonCosmeticState.isEquipped(frame), isTrue);
    expect(
      SeasonCosmeticState.equippedReward('profile_frame')?.name,
      'OVERDRIVE FRAME',
    );
  });

  test('revoked server ownership clears stale equipment', () async {
    await SeasonCosmeticState.syncSnapshot(
      snapshot(<String>{frame.rewardKey}),
    );
    await SeasonCosmeticState.equip(frame);
    await SeasonCosmeticState.syncSnapshot(snapshot(<String>{}));

    expect(SeasonCosmeticState.equippedKey('profile_frame'), isNull);
  });
}
