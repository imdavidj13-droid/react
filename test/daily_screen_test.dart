import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/daily/presentation/daily_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Daily presents an uncapped endurance challenge with clear rules',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyScreen()));
    await tester.pumpAndSettle();

    final today = DailyChallenge.today();
    expect(find.text("TODAY'S RULE"), findsOneWidget);
    expect(find.text(today.modifier.label), findsWidgets);
    expect(find.text('SAME RUN ALL DAY'), findsOneWidget);
    expect(
      find.text('SURVIVE UNTIL YOU MISS • BEST SCORE COUNTS'),
      findsOneWidget,
    );
    expect(find.text('FORMAT'), findsOneWidget);
    expect(find.text('ENDLESS'), findsOneWidget);
    expect(find.text('MISS LIMIT'), findsOneWidget);
    expect(find.textContaining('60 COMMANDS'), findsNothing);
    expect(find.text('PLAY DAILY'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
  });
}
