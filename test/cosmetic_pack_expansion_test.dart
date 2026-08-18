import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_launch_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    ReactCosmetics.currentCountdownStyle = ReactCountdownStyle.core;
  });

  tearDown(() {
    ReactCosmetics.currentTheme = ReactVisualTheme.core;
    ReactCosmetics.currentCountdownStyle = ReactCountdownStyle.core;
  });

  testWidgets('all four countdown packs render distinct live presentations',
      (tester) async {
    for (final style in <ReactCountdownStyle>[
      ReactCountdownStyle.rings,
      ReactCountdownStyle.cards,
      ReactCountdownStyle.terminal,
      ReactCountdownStyle.pulse,
    ]) {
      ReactCosmetics.currentCountdownStyle = style;
      await tester.pumpWidget(
        const MaterialApp(
          home: ReactRunLaunchScreen(mode: ReactGameMode.classic),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey<String>('countdown-style-${style.name}')),
        findsOneWidget,
      );
      expect(find.text('CLASSIC'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('new reaction pack colours feed the countdown screen',
      (tester) async {
    await ReactCosmetics.equipReactionPack(ReactReactionPack.greenline);
    await tester.pumpWidget(
      const MaterialApp(
        home: ReactRunLaunchScreen(mode: ReactGameMode.classic),
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor,
      ReactCosmetics.paletteForReactionPack(ReactReactionPack.greenline).background,
    );
    expect(tester.takeException(), isNull);
  });

  test('four new reaction pack colours are registered', () {
    expect(
      <ReactReactionPack>[
        ReactReactionPack.greenline,
        ReactReactionPack.voltage,
        ReactReactionPack.ember,
        ReactReactionPack.hotPink,
      ].map((pack) => pack.packId).toSet().length,
      4,
    );
  });

  test('four new audio packs and four new text packs are registered', () {
    expect(
      <ReactSoundPack>[
        ReactSoundPack.pulse,
        ReactSoundPack.bass,
        ReactSoundPack.minimal,
        ReactSoundPack.laser,
      ].map((pack) => pack.packId).toSet().length,
      4,
    );
    expect(
      <ReactCommandStyle>[
        ReactCommandStyle.terminal,
        ReactCommandStyle.arcade,
        ReactCommandStyle.minimal,
        ReactCommandStyle.impact,
      ].map((style) => style.packId).toSet().length,
      4,
    );
  });
}
