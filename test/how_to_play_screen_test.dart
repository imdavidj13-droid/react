import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/tutorial/presentation/how_to_play_screen.dart';

void main() {
  testWidgets('how to play exposes the complete command tutorial', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HowToPlayScreen()));

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('9 COMMANDS. ONE SIMPLE RULE.'), findsOneWidget);
    expect(find.text('TAP'), findsWidgets);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
    }

    expect(find.text('SEQUENCE MODE'), findsOneWidget);
    expect(find.text('1 → 2 → 3'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    expect(find.text('REACT FAST'), findsOneWidget);
    expect(find.text("LET'S PLAY"), findsOneWidget);
  });
}
