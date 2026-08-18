import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/modes/data/local_variant_mode_stats.dart';
import 'package:react/features/modes/domain/react_variant_mode.dart';
import 'package:react/features/modes/presentation/modes_screen.dart';
import 'package:react/features/modes/presentation/variant_mode_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Mode Lab exposes only the retained playtest set', () {
    expect(ModesScreen.retainedLabModes.length, 10);
    expect(
      ModesScreen.retainedLabModes.map((mode) => mode.title).toList(),
      <String>[
        'PHANTOM',
        'MOSAIC',
        'ILLUSION',
        'MEMORY',
        'TEMPEST',
        'VORTEX',
        'TIMEDROP',
        'GLITCH',
        'BLACKOUT',
        'RICOCHET',
      ],
    );

    for (final mode in ModesScreen.retainedLabModes) {
      expect(mode.badge, isNotEmpty);
      expect(mode.subtitle, isNotEmpty);
      expect(mode.detail, isNotEmpty);
      expect(mode.rules.length, greaterThan(40));
    }
  });

  test('retained specialized mechanics keep their expected foundations', () {
    expect(ReactVariantMode.mosaic.mechanic, ReactVariantMechanic.grid);
    expect(ReactVariantMode.memory.mechanic, ReactVariantMechanic.memory);
    expect(ReactVariantMode.vortex.mechanic, ReactVariantMechanic.target);
    expect(ReactVariantMode.ricochet.mechanic, ReactVariantMechanic.target);
    expect(ReactVariantMode.phantom.mechanic, ReactVariantMechanic.command);
  });

  test('Mode Lab best scores and play counts persist independently', () async {
    expect(await LocalVariantModeStats.best(ReactVariantMode.phantom), 0);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.phantom), 0);

    expect(
      await LocalVariantModeStats.record(ReactVariantMode.phantom, 7),
      isTrue,
    );
    expect(
      await LocalVariantModeStats.record(ReactVariantMode.phantom, 4),
      isFalse,
    );
    expect(
      await LocalVariantModeStats.record(ReactVariantMode.ricochet, 11),
      isTrue,
    );

    expect(await LocalVariantModeStats.best(ReactVariantMode.phantom), 7);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.phantom), 2);
    expect(await LocalVariantModeStats.best(ReactVariantMode.ricochet), 11);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.ricochet), 1);
  });

  testWidgets('Mosaic intro offers both playable variants', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: VariantModeScreen(mode: ReactVariantMode.mosaic)),
    );
    await tester.pumpAndSettle();

    expect(find.text('MOSAIC'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.text('ORIGINAL MOSAIC'), findsOneWidget);
    expect(find.text('PRESSURE GRID'), findsOneWidget);
  });

  testWidgets('Ricochet intro still explains the retained target mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VariantModeScreen(mode: ReactVariantMode.ricochet),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RICOCHET'), findsOneWidget);
    expect(find.text('BOUNCE'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.textContaining('target bounces'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'START MODE'), findsOneWidget);
  });
}
