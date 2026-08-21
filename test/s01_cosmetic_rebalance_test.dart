import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('S01 late tiers add completed cosmetic families without touching earned rows', () {
    final source = File(
      'supabase/migrations/20260821050000_rebalance_s01_cosmetic_mix.sql',
    ).readAsStringSync();

    for (final kind in <String>[
      'arena_theme',
      'hud_style',
      'input_reaction_pack',
      'particle_pack',
    ]) {
      expect(source, contains("'$kind'"), reason: kind);
    }

    // Existing unlocks are immutable. This is the compatibility boundary that
    // allows tiers 1–9 and any unexpectedly early later unlock to stay intact.
    expect(source, contains('not exists'));
    expect(source, contains('public.react_player_unlocks'));
    expect(source, contains('u.reward_id = r.id'));

    // Early already-earned rewards are deliberately absent from replacements.
    expect(source, isNot(contains("(1, 'free'")));
    expect(source, isNot(contains("(3, 'free'")));
    expect(source, isNot(contains("(9, 'free'")));

    // Milestone-quality surfaces now appear in the later road.
    expect(source, contains("(10, 'free', 'arena_theme'"));
    expect(source, contains("(20, 'free', 'hud_style'"));
  });
}
