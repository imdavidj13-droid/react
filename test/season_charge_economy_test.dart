import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Season 01 CHARGE economy prevents unlimited run farming', () {
    final migration = File(
      'supabase/migrations/20260821032521_rebalance_season_charge_economy.sql',
    ).readAsStringSync();

    expect(migration, contains('if v_runs_today < 10 then'));
    expect(migration, contains('v_base_charge := 10;'));
    expect(migration, contains("elsif v_runs_today < 20 then"));
    expect(migration, contains('v_base_charge := 5;'));
    expect(migration, contains('v_base_charge := 0;'));

    // A PB bonus is limited to one award for the same PB scope and UTC date.
    expect(migration, contains('e.personal_best_credit_awarded'));
    expect(migration, contains("v_base_charge := v_base_charge + 25;"));

    // Daily and first-play bonuses are also once-per-day server decisions.
    expect(migration, contains("if v_daily_credit then"));
    expect(migration, contains("v_base_charge := v_base_charge + 40;"));
    expect(migration, contains("if v_first_play then"));
  });

  test('Season 01 mission rewards use the rebalanced values', () {
    final migration = File(
      'supabase/migrations/20260821032521_rebalance_season_charge_economy.sql',
    ).readAsStringSync();

    for (final contract in <String, int>{
      'WARM UP': 20,
      'FAST HANDS': 30,
      'DAILY SIGNAL': 40,
      'KEEP MOVING': 125,
      'HIGH OUTPUT': 150,
      'BREAK YOUR LIMIT': 175,
      'OVERDRIVE REGULAR': 300,
      'FULL CURRENT': 400,
      'DAILY DISCIPLINE': 350,
      'TOTAL OUTPUT': 300,
    }.entries) {
      expect(
        migration,
        contains("when '${contract.key}' then ${contract.value}"),
        reason: contract.key,
      );
    }
  });

  test('older installed builds retain a compatible season run RPC', () {
    final migration = File(
      'supabase/migrations/20260821032521_rebalance_season_charge_economy.sql',
    ).readAsStringSync();

    expect(migration, contains('p_is_daily boolean'));
    expect(migration, contains("'^season-(classic|blitz|endless|passIt|sequence)-'"));
    expect(migration, contains('to authenticated, service_role'));
  });
}
