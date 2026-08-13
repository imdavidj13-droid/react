import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/daily/presentation/daily_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Daily presents a 30-command challenge with a gameplay rule',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyScreen()));
    await tester.pumpAndSettle();

    final today = DailyChallenge.today();
    expect(find.text("TODAY'S RULE"), findsOneWidget);
    expect(find.text(today.modifier.label), findsWidgets);
    expect(find.text(today.modifier.shortRule), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('PLAY DAILY'), findsOneWidget);
  });
}
