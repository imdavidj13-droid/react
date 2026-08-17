import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/settings/presentation/milestones_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Milestones exposes 100 goals by category on a compact phone',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'runs_played': 32,
      'mode_commands_classic': 120,
      'mode_runs_classic': 12,
      'best_classic': 31,
      'best_blitz': 16,
      'best_endless': 12,
      'best_daily': 22,
      'daily_streak': 3,
      'mode_runs_passIt': 4,
      'mode_commands_passIt': 58,
    });

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: MilestonesScreen()),
    );
    await tester.pumpAndSettle();

    Future<void> revealVertical(Finder target) async {
      for (var i = 0; i < 8 && target.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -320));
        await tester.pumpAndSettle();
      }
      expect(target, findsOneWidget);
    }

    expect(find.text('MILESTONES'), findsOneWidget);
    expect(find.textContaining('/ 100 UNLOCKED'), findsOneWidget);
    expect(find.text('CENTURY'), findsOneWidget);
    expect(find.text('GENERAL'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('CLASSIC').first);
    await tester.pumpAndSettle();
    expect(find.text('CLASSIC 25'), findsOneWidget);

    await revealVertical(find.text('CLASSIC RUNS 5'));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('PASS IT').first);
    await tester.tap(find.text('PASS IT').first);
    await tester.pumpAndSettle();
    expect(find.text('PASS IT REGULAR'), findsOneWidget);

    await revealVertical(find.text('HANDOFF 50'));
    expect(find.text('UNLOCKED'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
