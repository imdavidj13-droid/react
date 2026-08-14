import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/settings/presentation/milestones_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Milestones renders real local progress on a 320x640 screen',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mode_commands_classic': 120,
      'best_classic': 31,
      'best_blitz': 16,
      'best_endless': 12,
      'best_daily': 22,
      'daily_streak': 3,
      'mode_runs_passIt': 4,
    });

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: MilestonesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('MILESTONES'), findsOneWidget);
    expect(find.text('CENTURY'), findsOneWidget);
    expect(find.text('CLASSIC 25'), findsOneWidget);
    expect(find.text('PASS IT REGULAR'), findsOneWidget);
    expect(find.text('UNLOCKED'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
