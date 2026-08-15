import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/daily/domain/daily_challenge.dart';
import 'package:react/features/daily/presentation/daily_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Daily presents a 60-command challenge with clear player rules',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyScreen()));
    await tester.pumpAndSettle();

    final today = DailyChallenge.today();
    expect(find.text("TODAY'S RULE"), findsOneWidget);
    expect(find.text(today.modifier.label), findsWidgets);
    expect(find.text('SAME RUN ALL DAY'), findsOneWidget);
    expect(
      find.text('60 COMMANDS • ONE MISS ENDS THE ATTEMPT'),
      findsOneWidget,
    );
    expect(find.text('MISS LIMIT'), findsOneWidget);
    expect(find.text('FIXED SEED'), findsNothing);
    expect(find.text('MISSES'), findsNothing);
    expect(find.text('PLAY DAILY'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
  });
}
