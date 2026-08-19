import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home utility controls stay on the top row', () {
    final source = File('lib/app/react_app.dart').readAsStringSync();
    expect(source, contains('right: 62'));
    expect(source, contains('left: 62'));
    expect(source, contains('MediaQuery.paddingOf(context).top + 10'));
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
    expect(source, contains('_activateRandomTile'));
    expect(source, contains('if (_activeCount >= 9)'));
    expect(source, contains('Icons.grid_view_rounded'));
    expect(source, isNot(contains('_fill[')));
    expect(source, isNot(contains("'${(fill * 100).round()}'")));
  });
}
