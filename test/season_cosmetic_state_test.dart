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

  const title = SeasonReward(
    id: 'title-1',
    tier: 1,
    track: SeasonRewardTrack.free,
    kind: 'title',
    rewardKey: 'title_quick_start',
    name: 'QUICK START',
    description: 'Season title',
    milestone: false,
  );

  const codeStyle = SeasonReward(
    id: 'code-1',
    tier: 2,
    track: SeasonRewardTrack.premium,
    kind: 'player_code_style',
    rewardKey: 'code_style_voltage_trace',
    name: 'VOLTAGE TRACE',
    description: 'Player-code styling',
    milestone: false,
  );

  const emblem = SeasonReward(
    id: 'emblem-1',
    tier: 2,
    track: SeasonRewardTrack.free,
    kind: 'emblem',
    rewardKey: 'emblem_charge_cell',
    name: 'CHARGE CELL',
    description: 'Player emblem',
    milestone: false,
  );

  const modeSkin = SeasonReward(
    id: 'mode-skin-1',
    tier: 18,
    track: SeasonRewardTrack.free,
    kind: 'mode_card_skin',
    rewardKey: 'mode_skin_gridline',
    name: 'GRIDLINE CARDS',
    description: 'Mode-card skin',
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
        charge: 3400,
        premiumOwned: true,
        tiers: const <SeasonTier>[
          SeasonTier(
            number: 5,
            chargeRequired: 800,
            milestone: true,
            rewards: <SeasonReward>[frame, badge, title, codeStyle, emblem],
          ),
          SeasonTier(
            number: 18,
            chargeRequired: 3400,
            milestone: false,
            rewards: <SeasonReward>[modeSkin],
          ),
        ],
        missions: const <SeasonMission>[],
        unlockedRewardKeys: unlocked,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SeasonCosmeticState.load();
  });

  test('server snapshot adds verified season cosmetic ownership', () async {
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

  test('rendered profile identity cosmetics can be equipped', () async {
    await SeasonCosmeticState.syncSnapshot(
      snapshot(<String>{
        badge.rewardKey,
        title.rewardKey,
        codeStyle.rewardKey,
        emblem.rewardKey,
      }),
    );

    for (final reward in <SeasonReward>[badge, title, codeStyle, emblem]) {
      expect(SeasonCosmeticState.isEquippable(reward), isTrue);
      expect(await SeasonCosmeticState.equip(reward), isTrue);
      expect(SeasonCosmeticState.isEquipped(reward), isTrue);
    }

    expect(
      SeasonCosmeticState.equippedReward('profile_badge')?.rewardKey,
      badge.rewardKey,
    );
    expect(
      SeasonCosmeticState.equippedReward('player_code_style')?.rewardKey,
      codeStyle.rewardKey,
    );
  });

  test('rendered mode-card skins can be equipped', () async {
    await SeasonCosmeticState.syncSnapshot(
      snapshot(<String>{modeSkin.rewardKey}),
    );

    expect(SeasonCosmeticState.isEquippable(modeSkin), isTrue);
    expect(await SeasonCosmeticState.equip(modeSkin), isTrue);
    expect(SeasonCosmeticState.isEquipped(modeSkin), isTrue);
    expect(
      SeasonCosmeticState.equippedReward('mode_card_skin')?.rewardKey,
      modeSkin.rewardKey,
    );
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

  test('earned ownership survives a later season snapshot', () async {
    await SeasonCosmeticState.syncSnapshot(
      snapshot(<String>{frame.rewardKey}),
    );
    await SeasonCosmeticState.equip(frame);
    await SeasonCosmeticState.syncSnapshot(snapshot(<String>{badge.rewardKey}));

    expect(SeasonCosmeticState.isOwned(frame.rewardKey), isTrue);
    expect(SeasonCosmeticState.isOwned(badge.rewardKey), isTrue);
    expect(SeasonCosmeticState.isEquipped(frame), isTrue);
  });

  test('load removes stale equipped preferences that are not owned', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'season_cosmetics_equipped_profile_frame': frame.rewardKey,
    });

    await SeasonCosmeticState.load();
    final prefs = await SharedPreferences.getInstance();

    expect(SeasonCosmeticState.equippedKey('profile_frame'), isNull);
    expect(prefs.getString('season_cosmetics_equipped_profile_frame'), isNull);
  });
}
