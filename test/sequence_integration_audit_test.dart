import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/home/presentation/home_screen.dart';
import 'package:react/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:react/features/leaderboard/presentation/personal_records_screen.dart';
import 'package:react/features/player/data/local_player_profile.dart';
import 'package:react/features/player/presentation/player_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'react_player_local_id': '5173822187cd482aa873ae95',
      'react_player_display_name': 'PLAYER-517382',
      'react_player_created_at': '2026-08-18T03:22:38.000Z',
      'best_sequence': 27,
      'mode_runs_sequence': 4,
      'mode_commands_sequence': 63,
      'mode_response_ms_sequence': 81900,
    });
    await LocalPlayerProfile.load();
  });

  testWidgets('Home surfaces the Sequence personal best', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SEQUENCE'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Player Profile includes Sequence in personal bests',
      (tester) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PlayerProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('PERSONAL BESTS'), findsOneWidget);
    expect(find.text('SEQUENCE'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Personal Records includes Sequence best', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalRecordsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SEQUENCE'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Leaderboard exposes Sequence as a competitive mode',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LeaderboardScreen()));
    await tester.pumpAndSettle();

    final selector = find.text('SEQUENCE');
    expect(selector, findsOneWidget);
    await tester.tap(selector);
    await tester.pumpAndSettle();

    expect(find.text('GLOBAL • SEQUENCE'), findsOneWidget);
    expect(find.text('27'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
