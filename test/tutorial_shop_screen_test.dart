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
    ReactCosmetics.currentCountdownStyle = ReactCountdownStyle.core;
    ReactCosmetics.currentSoundPack = ReactSoundPack.core;
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;
    ReactCosmetics.currentShareStyle = ReactShareStyle.core;
    await LocalShopState.load();
  });

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      280,
      scrollable: find.byType(CustomScrollView),
    );
    await tester.pumpAndSettle();
  }

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

  testWidgets('shop exposes implemented cosmetics in clear sections', (tester) async {
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

    for (final section in <String>[
      'REACTION PACKS',
      'COUNTDOWN STYLES',
      'AUDIO PACKS',
      'COMMAND TEXT STYLES',
      'SHARE CARDS',
    ]) {
      expect(find.text(section), findsOneWidget);
    }

    await scrollTo(tester, find.text('ARCADE SFX'));
    expect(find.text('ARCADE SFX'), findsOneWidget);
    await scrollTo(tester, find.text('FAIR PLAY PROMISE'));
    expect(find.textContaining('NO EXTRA LIVES'), findsOneWidget);
    expect(find.textContaining('PAID GAMEPLAY ADVANTAGES'), findsOneWidget);
  });

  testWidgets('shop category filters show matching groups', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const ValueKey('shop_filter_audio')));
    await tester.tap(find.byKey(const ValueKey('shop_filter_audio')));
    await tester.pumpAndSettle();
    expect(find.text('ARCADE SFX'), findsOneWidget);
    expect(find.text('PULSE SFX'), findsOneWidget);
    expect(find.text('SYNTHWAVE'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shop_filter_styles')));
    await tester.pumpAndSettle();
    expect(find.text('GLITCH COMMANDS'), findsOneWidget);
    expect(find.text('TERMINAL COMMANDS'), findsOneWidget);
    expect(find.text('PRO SHARE CARDS'), findsOneWidget);
    expect(find.text('ARCADE SFX'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shop_filter_countdown')));
    await tester.pumpAndSettle();
    expect(find.text('RINGS COUNTDOWN'), findsOneWidget);
    expect(find.text('PULSE COUNTDOWN'), findsOneWidget);
    expect(find.text('GLITCH COMMANDS'), findsNothing);
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

  testWidgets('new Greenline reaction pack can be equipped in debug',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('GREENLINE'));
    await tester.tap(find.text('GREENLINE'));
    await tester.pumpAndSettle();
    expect(find.text('Electric green arena accents'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentReactionPack, ReactReactionPack.greenline);
  });

  testWidgets('Arcade SFX can be equipped independently in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('ARCADE SFX'));
    await tester.tap(find.text('ARCADE SFX'));
    await tester.pumpAndSettle();
    expect(find.text('Alternate countdown cues'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.arcade);
  });

  testWidgets('Bass SFX can be equipped independently in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('BASS SFX'));
    await tester.tap(find.text('BASS SFX'));
    await tester.pumpAndSettle();
    expect(find.text('Low command thumps'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentSoundPack, ReactSoundPack.bass);
  });

  testWidgets('Glitch Commands can be equipped independently in debug',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('GLITCH COMMANDS'));
    await tester.tap(find.text('GLITCH COMMANDS'));
    await tester.pumpAndSettle();
    expect(find.text('System-coded command hints'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentCommandStyle, ReactCommandStyle.glitch);
  });

  testWidgets('Terminal countdown can be equipped independently in debug',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('TERMINAL COUNTDOWN'));
    await tester.tap(find.text('TERMINAL COUNTDOWN'));
    await tester.pumpAndSettle();
    expect(find.text('Command-line countdown labels'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'EQUIP'));
    await tester.pumpAndSettle();
    expect(ReactCosmetics.currentCountdownStyle, ReactCountdownStyle.terminal);
  });

  testWidgets('Pro Share Cards can be equipped independently in debug',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('PRO SHARE CARDS'));
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
