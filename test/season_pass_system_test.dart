import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/season/domain/season_models.dart';
import 'package:react/features/shop/data/local_shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('season tier math uses shared cumulative CHARGE', () {
    final tiers = [
      for (var tier = 1; tier <= 30; tier++)
        SeasonTier(
          number: tier,
          chargeRequired: (tier - 1) * 200,
          milestone: tier % 5 == 0,
          rewards: const <SeasonReward>[],
        ),
    ];
    final season = SeasonSnapshot(
      id: 'season',
      code: 'S01',
      name: 'OVERDRIVE',
      subtitle: 'TEST',
      themeKey: 'overdrive',
      startsAt: DateTime.utc(2026, 8, 19),
      endsAt: DateTime.utc(2026, 9, 9),
      charge: 950,
      premiumOwned: false,
      tiers: tiers,
      missions: const <SeasonMission>[],
      unlockedRewardKeys: const <String>{},
    );

    expect(season.currentTier, 5);
    expect(season.nextTierCharge, 1000);
    expect(season.chargeIntoTier, 150);
    expect(season.chargeForNextTier, 200);
    expect(season.tierProgress, closeTo(.75, .001));
    expect(tiers.where((tier) => tier.milestone).map((tier) => tier.number), [
      5,
      10,
      15,
      20,
      25,
      30,
    ]);
  });

  test('season cosmetic entitlement cache keeps only implemented packs', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalShopState.setSeasonOwnedPackIds(<String>[
      LocalShopState.greenlinePackId,
      LocalShopState.ringsCountdownPackId,
      'profile_frame_overdrive',
    ]);

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('shop_season_owned_packs');
    expect(cached, contains(LocalShopState.greenlinePackId));
    expect(cached, contains(LocalShopState.ringsCountdownPackId));
    expect(cached, isNot(contains('profile_frame_overdrive')));
  });

  test('season migration is cosmetic only and config driven', () {
    final source = File(
      'supabase/migrations/20260819072621_create_season_pass_system.sql',
    ).readAsStringSync();

    for (final table in <String>[
      'react_seasons',
      'react_season_tiers',
      'react_season_rewards',
      'react_season_progress',
      'react_season_missions',
      'react_season_mission_progress',
      'react_player_unlocks',
    ]) {
      expect(source, contains('public.$table'), reason: table);
    }

    expect(source, contains("interval '21 days'"));
    expect(source, contains('generate_series(1, 30)'));
    expect(source, contains("track in ('free', 'premium')"));
    expect(source, contains('premium_owned'));
    expect(source, contains('claim_reached_rewards'));
    expect(source, contains("grant execute on function public.set_react_season_premium_entitlement"));
    expect(source, contains("to service_role"));
    expect(source, contains("'reaction_pack'"));
    expect(source, contains("'profile_frame'"));
    expect(source, contains("'home_theme'"));
    expect(source, contains("'mode_card_skin'"));
    expect(source, isNot(contains("'gameplay_boost'")));
    expect(source, isNot(contains("'extra_life'")));
  });

  test('season UI exposes pass missions and season info', () {
    final screen = File(
      'lib/features/season/presentation/season_screen.dart',
    ).readAsStringSync();
    final homeStrip = File(
      'lib/features/season/presentation/home_season_strip.dart',
    ).readAsStringSync();

    // Assert the stable feature contract rather than exact marketing copy so
    // harmless visual/copy iterations do not break this regression test.
    expect(screen, contains("Tab(text: 'PASS')"));
    expect(screen, contains("Tab(text: 'MISSIONS')"));
    expect(screen, contains("Tab(text: 'SEASON INFO')"));
    expect(screen, contains("title: 'FREE + PREMIUM'"));
    expect(screen, contains('unlock retroactively'));
    expect(screen, contains("title: 'NO PAY-TO-WIN'"));
    expect(screen, contains('SeasonRewardPreview'));
    expect(homeStrip, contains('CHARGE'));
    expect(homeStrip, contains('SeasonScreen'));
  });
}
