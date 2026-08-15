import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/shop/presentation/shop_screen.dart';
import 'package:react/features/tutorial/presentation/how_to_play_screen.dart';

void main() {
  testWidgets('how to play exposes the complete command tutorial', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HowToPlayScreen()),
    );

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('9 COMMANDS. ONE SIMPLE RULE.'), findsOneWidget);
    expect(find.text('TAP'), findsWidgets);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
    }

    expect(find.text('REACT FAST'), findsOneWidget);
    expect(find.text("LET'S PLAY"), findsOneWidget);
  });

  testWidgets('shop is cosmetic-only placeholder content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ShopScreen()),
    );

    expect(find.text('SHOP'), findsOneWidget);
    expect(find.text('MAKE RE△CT YOURS'), findsOneWidget);
    expect(find.text('REDLINE'), findsOneWidget);
    expect(find.text('SYNTHWAVE'), findsOneWidget);

    final scrollable = find.byType(CustomScrollView);
    await tester.scrollUntilVisible(
      find.text('ARCADE SFX'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('ARCADE SFX'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('NO EXTRA LIVES'),
      250,
      scrollable: scrollable,
    );
    expect(find.textContaining('NO EXTRA LIVES'), findsOneWidget);
    expect(find.textContaining('PAID GAMEPLAY ADVANTAGES'), findsOneWidget);
  });

  testWidgets('shop pack opens a non-purchasable detail preview', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ShopScreen()),
    );

    await tester.tap(find.text('REDLINE'));
    await tester.pumpAndSettle();

    expect(find.text('INCLUDES'), findsOneWidget);
    expect(find.text('Redline arena palette'), findsOneWidget);
    expect(find.text('£1.99'), findsWidgets);
    expect(find.textContaining('STORE CHECKOUT IS NOT ENABLED YET'), findsOneWidget);

    final comingSoon = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'COMING SOON'),
    );
    expect(comingSoon.onPressed, isNull);
  });
}
