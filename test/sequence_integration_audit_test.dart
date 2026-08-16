import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/home/presentation/home_screen.dart';
import 'package:react/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:react/features/leaderboard/presentation/personal_records_screen.dart';
import 'package:react/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'best_sequence': 27,
      'mode_runs_sequence': 4,
      'mode_commands_sequence': 63,
      'mode_response_ms_sequence': 81900,
    });
  });

  testWidgets('Home surfaces the Sequence personal best', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SEQUENCE'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile includes Sequence in personal bests', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

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

    expect(find.text('SEQUENCES'), findsOneWidget);
    expect(find.text('27'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
