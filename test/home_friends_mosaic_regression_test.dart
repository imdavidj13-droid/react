import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home keeps profile in top chrome and moves utilities into tiles', () {
    final app = File('lib/app/react_app.dart').readAsStringSync();
    final home = File(
      'lib/features/home/presentation/home_screen.dart',
    ).readAsStringSync();

    expect(app, contains("tooltip: 'Player profile'"));
    expect(app, contains('right: 12'));
    expect(app, isNot(contains("tooltip: 'Friends'")));
    expect(app, isNot(contains("tooltip: 'Locker'")));
    expect(home, contains("label: 'FRIENDS'"));
    expect(home, contains("label: 'LOCKER'"));
    expect(home, contains("label: 'PASS'"));
    expect(home, contains("label: 'LEADERBOARD'"));
  });

  test('Friends exposes a copyable own player code', () {
    final source = File(
      'lib/features/friends/presentation/friends_screen.dart',
    ).readAsStringSync();
    expect(source, contains('YOUR PLAYER CODE'));
    expect(source, contains('Clipboard.setData'));
    expect(source, contains('PlayerProfileRepository'));
  });

  test('Mosaic pressure uses active tiles instead of fill percentages', () {
    final source = File(
      'lib/features/modes/presentation/mosaic_pressure_run_screen.dart',
    ).readAsStringSync();
    expect(source, contains('List<bool>.filled(9, false)'));
    expect(source, contains('_activateBurst'));
    expect(source, contains('if (_activeCount >= 9)'));
    expect(source, contains('Icons.grid_view_rounded'));
    expect(source, isNot(contains('_fill[')));
    expect(source, isNot(contains(r"'${(fill * 100).round()}'")));
  });
}
