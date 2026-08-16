import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/shop/data/local_shop_state.dart';
import 'package:react/features/shop/presentation/shop_screen.dart';
import 'package:react/features/tutorial/presentation/how_to_play_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    ReactCosmetics.currentSoundPack = ReactSoundPack.core;
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;
    ReactCosmetics.currentShareStyle = ReactShareStyle.core;
    await LocalShopState.load();
  });

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

  testWidgets('shop exposes implemented cosmetics in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SHOP'), findsOneWidget);
    expect(find.text('MAKE RE△CT YOURS'), findsOneWidget);
    expect(find.text('DEV • IMPLEMENTED COSMETICS UNLOCKED'), findsOneWidget);
    expect(find.text('RE△CT CORE'), findsOneWidget);
    expect(find.text('EQUIPPED'), findsOneWidget);
    expect(find.text('FEATURED'), findsOneWidget);
    expect(find.text('FEATURED REACTION PACK'), findsOneWidget);
    expect(find.text('REDLINE'), findsOneWidget);
    expect(find.text('OWNED'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('ARCADE SFX'), findsOneWidget);
    expect(find.textContaining('NO EXTRA LIVES'), findsOneWidget);
    expect(find.textContaining('PAID GAMEPLAY ADVANTAGES'), findsOneWidget);
  });

  testWidgets('shop category filters show matching groups', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('shop_filter_audio')));
    await tester.pumpAndSettle();
    expect(find.text('ARCADE SFX'), findsOneWidget);
    expect(find.text('SYNTHWAVE'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shop_filter_styles')));
    await tester.pumpAndSettle();
    expect(find.text('GLITCH COMMANDS'), findsOneWidget);
    expect(find.text('PRO SHARE CARDS'), findsOneWidget);
    expect(find.text('ARCADE SFX'), findsNothing);
  });

  testWidgets('featured Redline can be equipped in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('featured_redline')));
    await tester.pumpAndSettle();
    expect(find.text('Redline arena palette'), findsOneWidget);
    expect(find.textContaining('DEV ENTITLEMENT'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(await LocalShopState.equippedPack(), LocalShopState.redlinePackId);
  });

  testWidgets('Arcade SFX can be equipped independently in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ARCADE SFX'));
    await tester.pumpAndSettle();
    expect(find.text('Alternate countdown cues'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
  });

  testWidgets('Glitch Commands can be equipped independently in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GLITCH COMMANDS'));
    await tester.pumpAndSettle();
    expect(find.text('System-coded command hints'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
  });

  testWidgets('Pro Share Cards can be equipped independently in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PRO SHARE CARDS'));
    await tester.pumpAndSettle();

    expect(find.text('Premium score-first result layout'), findsOneWidget);
    expect(find.textContaining('DEV ENTITLEMENT'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'EQUIP'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentShareStyle, ReactShareStyle.pro);
  });
}
