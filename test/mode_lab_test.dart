import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/modes/data/local_variant_mode_stats.dart';
import 'package:react/features/modes/domain/react_variant_mode.dart';
import 'package:react/features/modes/presentation/variant_mode_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Mode Lab contains every retained variant with complete metadata', () {
    final retainedModes = ReactVariantMode.values
        .where(
          (mode) =>
              mode != ReactVariantMode.tether &&
              mode != ReactVariantMode.overload &&
              mode != ReactVariantMode.lockstep &&
              mode != ReactVariantMode.zenith,
        )
        .toList(growable: false);

    expect(retainedModes.length, 32);

    final expected = <String>{
      'PHANTOM',
      'MOSAIC',
      'ACCEL',
      'TITAN',
      'BEACON',
      'COLLAPSE',
      'MAGNET',
      'ILLUSION',
      'CHECKPOINT',
      'REACTOR',
      'NEXUS',
      'PRISM',
      'MEMORY',
      'HUNTER',
      'ASCENT',
      'FRACTURE',
      'TEMPEST',
      'CHAIN',
      'SURVIVOR',
      'DECODER',
      'STEALTH',
      'SNAP',
      'VORTEX',
      'TIMEDROP',
      'ECHO',
      'ORBIT',
      'FUSE',
      'SHUFFLE',
      'PULSE',
      'GLITCH',
      'BLACKOUT',
      'RICOCHET',
    };

    expect(retainedModes.map((mode) => mode.title).toSet(), expected);
    for (final mode in retainedModes) {
      expect(mode.badge, isNotEmpty);
      expect(mode.subtitle, isNotEmpty);
      expect(mode.detail, isNotEmpty);
      expect(mode.rules.length, greaterThan(40));
    }
  });

  test('specialized mechanics are assigned to their intended retained modes', () {
    expect(ReactVariantMode.mosaic.mechanic, ReactVariantMechanic.grid);
    expect(ReactVariantMode.fracture.mechanic, ReactVariantMechanic.grid);
    expect(ReactVariantMode.memory.mechanic, ReactVariantMechanic.memory);
    expect(ReactVariantMode.orbit.mechanic, ReactVariantMechanic.target);
    expect(ReactVariantMode.vortex.mechanic, ReactVariantMechanic.target);
    expect(ReactVariantMode.ricochet.mechanic, ReactVariantMechanic.target);
    expect(ReactVariantMode.phantom.mechanic, ReactVariantMechanic.command);
  });

  test('Mode Lab best scores and play counts persist independently', () async {
    expect(await LocalVariantModeStats.best(ReactVariantMode.phantom), 0);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.phantom), 0);

    expect(await LocalVariantModeStats.record(ReactVariantMode.phantom, 7), isTrue);
    expect(await LocalVariantModeStats.record(ReactVariantMode.phantom, 4), isFalse);
    expect(await LocalVariantModeStats.record(ReactVariantMode.orbit, 11), isTrue);

    expect(await LocalVariantModeStats.best(ReactVariantMode.phantom), 7);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.phantom), 2);
    expect(await LocalVariantModeStats.best(ReactVariantMode.orbit), 11);
    expect(await LocalVariantModeStats.plays(ReactVariantMode.orbit), 1);
  });

  testWidgets('variant intro explains its real rule before starting', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: VariantModeScreen(mode: ReactVariantMode.ricochet)),
    );
    await tester.pumpAndSettle();

    expect(find.text('RICOCHET'), findsOneWidget);
    expect(find.text('BOUNCE'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.textContaining('target bounces'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'START MODE'), findsOneWidget);
  });
}
