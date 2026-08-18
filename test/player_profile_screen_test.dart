import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/player/data/local_player_profile.dart';
import 'package:react/features/player/presentation/player_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('guest player profile renders real identity and stats sections',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'react_player_local_id': '5173822187cd482aa873ae95',
      'react_player_display_name': 'PLAYER-517382',
      'react_player_created_at': '2026-08-18T03:22:38.000Z',
      'best_classic': 12,
      'best_blitz': 20,
      'runs_played': 7,
    });
    await LocalPlayerProfile.load();

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: PlayerProfileScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('PLAYER PROFILE'), findsOneWidget);
    expect(find.text('PLAYER-517382'), findsOneWidget);
    expect(find.text('RX-5173822187'), findsWidgets);
    expect(find.text('GUEST PLAYER'), findsOneWidget);
    expect(find.text('PLAYER STATS'), findsOneWidget);
    expect(find.text('PERSONAL BESTS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('public player code remains stable for a local guest id', () {
    expect(
      LocalPlayerProfile.playerCodeFor('5173822187cd482aa873ae95'),
      'RX-5173822187',
    );
  });
}
