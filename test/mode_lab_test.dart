import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/modes/data/local_variant_mode_stats.dart';
import 'package:react/features/modes/domain/react_variant_mode.dart';
import 'package:react/features/modes/presentation/modes_screen.dart';
import 'package:react/features/modes/presentation/variant_mode_screen.dart';
import 'package:react/features/modes/presentation/wave_two_variant_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Mode Lab exposes the enabled experimental library', () {
    expect(ModesScreen.retainedLabModes.length, 46);

    final titles = ModesScreen.retainedLabModes.map((mode) => mode.title).toSet();
    for (final title in <String>{
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
      'HARPOON',
      'DUALCAST',
      'SENTRY',
      'RAILRUN',
      'PARALLAX',
      'ANCHOR',
      'SHOCKWAVE',
      'HUSH',
      'GATELINE',
      'TIDEBREAK',
      'SCATTER',
      'SPARKGRID',
      'PHASESHIFT',
      'BARRAGE',
      'MONOLINE',
      'REWIND',
      'CRUCIBLE',
      'VANTAGE',
      'CATALYST',
      'OFFSET',
      'BARRICADE',
      'SKYHOOK',
      'PENDULUM',
      'SHADOWLINK',
      'BREAKER',
      'WAVELINE',
      'SPLICE',
      'THRUSTER',
      'FROSTLINE',
      'PINPOINT',
      'RIFTSTEP',
      'CORRIDOR',
      'SIDEWINDER',
      'HINGE',
      'RAMPART',
      'FADEOUT',
    }) {
      expect(titles, contains(title));
    }

    for (final mode in ModesScreen.retainedLabModes) {
      expect(mode.enabled, isTrue);
      expect(mode.badge, isNotEmpty);
      expect(mode.subtitle, isNotEmpty);
      expect(mode.detail, isNotEmpty);
      expect(mode.rules.length, greaterThan(40));
    }
  });

  test('culled modes stay archived instead of being deleted', () {
    for (final mode in <ReactVariantMode>[
      ReactVariantMode.overload,
      ReactVariantMode.tether,
      ReactVariantMode.lockstep,
      ReactVariantMode.zenith,
      ReactVariantMode.pulse,
      ReactVariantMode.shuffle,
      ReactVariantMode.fuse,
      ReactVariantMode.orbit,
      ReactVariantMode.echo,
      ReactVariantMode.stealth,
      ReactVariantMode.snap,
      ReactVariantMode.decoder,
      ReactVariantMode.survivor,
      ReactVariantMode.chain,
      ReactVariantMode.fracture,
      ReactVariantMode.ascent,
      ReactVariantMode.hunter,
      ReactVariantMode.prism,
      ReactVariantMode.nexus,
      ReactVariantMode.reactor,
      ReactVariantMode.checkpoint,
      ReactVariantMode.magnet,
      ReactVariantMode.collapse,
      ReactVariantMode.beacon,
      ReactVariantMode.titan,
      ReactVariantMode.accel,
    ]) {
      expect(mode.enabled, isFalse);
      expect(ModesScreen.retainedLabModes, isNot(contains(mode)));
    }
  });

  test('specialized mechanics keep their expected foundations', () {
    expect(ReactVariantMode.mosaic.mechanic, ReactVariantMechanic.grid);
    expect(ReactVariantMode.memory.mechanic, ReactVariantMechanic.memory);
    expect(ReactVariantMode.vortex.mechanic, ReactVariantMechanic.target);
    expect(ReactVariantMode.ricochet.mechanic, ReactVariantMechanic.target);
    expect(ReactVariantMode.anchor.mechanic, ReactVariantMechanic.tether);
    expect(ReactVariantMode.sparkgrid.mechanic, ReactVariantMechanic.grid);
    expect(ReactVariantMode.rewind.mechanic, ReactVariantMechanic.memory);
    expect(ReactVariantMode.pinpoint.mechanic, ReactVariantMechanic.target);
  });

  test('Mode Lab best scores and play counts persist independently', () async {
    expect(await LocalVariantModeStats.best(ReactVariantMode.phantom), 0);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.phantom), 0);

    expect(await LocalVariantModeStats.record(ReactVariantMode.phantom, 7), isTrue);
    expect(await LocalVariantModeStats.record(ReactVariantMode.phantom, 4), isFalse);
    expect(await LocalVariantModeStats.record(ReactVariantMode.harpoon, 11), isTrue);

    expect(await LocalVariantModeStats.best(ReactVariantMode.phantom), 7);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.phantom), 2);
    expect(await LocalVariantModeStats.best(ReactVariantMode.harpoon), 11);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.harpoon), 1);
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

  testWidgets('wave two intro launches its dedicated gameplay engine', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: VariantModeScreen(mode: ReactVariantMode.harpoon)),
    );
    await tester.pumpAndSettle();

    expect(find.text('HARPOON'), findsOneWidget);
    expect(find.text('PULL LINE'), findsOneWidget);
    expect(find.textContaining('drag it into the glowing capture ring'), findsOneWidget);

    final startButton = find.widgetWithText(FilledButton, 'START MODE');
    await tester.ensureVisible(startButton);
    await tester.pump();
    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(WaveTwoVariantRunScreen), findsOneWidget);
  });
}
