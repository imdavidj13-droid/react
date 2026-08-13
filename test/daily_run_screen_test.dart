import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/daily/presentation/daily_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.dailyDevOverrideEnabled = true;
    ReactSettings.dailyDevModifier = 'redline';
  });

  testWidgets('Daily gameplay shell renders sixty-step modifier run',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DailyRunScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('REDLINE'), findsWidgets);
    expect(find.text('0/60'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
