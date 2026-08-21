import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('player code style stays scoped to the RX code surface', () {
    final layers = File(
      'lib/features/season/presentation/season_cosmetic_layers.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/player/presentation/player_profile_screen.dart',
    ).readAsStringSync();

    expect(profile, contains("equippedReward('player_code_style')"));
    expect(profile, contains('profile.playerCode'));
    expect(layers, isNot(contains('_PlayerCodeTracePainter')));
    expect(layers, isNot(contains('_CodeStylePill')));
  });

  test('Season 01 cosmetic descriptions state their real destinations', () {
    final migration = File(
      'supabase/migrations/20260821033552_clarify_season_cosmetic_scope.sql',
    ).readAsStringSync();

    expect(migration, contains('Full gameplay colour theme'));
    expect(migration, contains('Pre-run 3-2-1 countdown presentation'));
    expect(migration, contains('Exported share-card style'));
    expect(migration, contains('Final-score treatment on the Results screen'));
    expect(migration, contains('Successful/completed outcome treatment'));
    expect(migration, contains('Miss/failure outcome treatment'));
  });

  test('Season 01 home themes use distinct renderer families', () {
    final layers = File(
      'lib/features/season/presentation/season_cosmetic_layers.dart',
    ).readAsStringSync();

    expect(layers, contains("rewardKey.contains('neon_rail')"));
    expect(layers, contains("rewardKey.endsWith('_grid')"));
    expect(layers, contains('_paintRails'));
    expect(layers, contains('_paintGrid'));
    expect(layers, contains('_paintOverdrive'));
  });
}
