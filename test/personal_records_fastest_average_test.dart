import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/leaderboard/presentation/personal_records_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Personal Records shows the fastest solo mode average', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mode_commands_classic': 10,
      'mode_response_ms_classic': 8200,
      'mode_commands_blitz': 10,
      'mode_response_ms_blitz': 6400,
      'mode_commands_endless': 10,
      'mode_response_ms_endless': 7100,
      'mode_commands_daily': 10,
      'mode_response_ms_daily': 7600,
      // Pass It is deliberately faster but must not count as a personal record.
      'mode_commands_passIt': 10,
      'mode_response_ms_passIt': 3000,
    });

    await tester.pumpWidget(
      const MaterialApp(home: PersonalRecordsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('FASTEST AVG'), findsOneWidget);
    expect(find.text('0.64s'), findsOneWidget);
    expect(find.text('0.30s'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
