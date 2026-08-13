import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/presentation/daily_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Daily advertises the 40-command escalating challenge', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('40 COMMANDS • SPEED RISES • SAME ORDER ALL DAY'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('PLAY DAILY'), findsOneWidget);
  });
}
