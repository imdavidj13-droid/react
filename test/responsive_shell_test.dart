import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/home/presentation/home_screen.dart';
import 'package:react/features/modes/presentation/modes_screen.dart';
import 'package:react/features/pass_it/presentation/pass_it_screen.dart';
import 'package:react/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpSmallScreen(
    WidgetTester tester,
    Widget screen,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: screen,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }

  testWidgets('Home fits a 320x640 screen', (tester) async {
    await pumpSmallScreen(tester, const HomeScreen());
  });

  testWidgets('Modes fits a 320x640 screen', (tester) async {
    await pumpSmallScreen(tester, const ModesScreen());
  });

  testWidgets('Pass It setup fits a 320x640 screen', (tester) async {
    await pumpSmallScreen(tester, const PassItScreen());
  });

  testWidgets('Profile settings fits a 320x640 screen', (tester) async {
    await pumpSmallScreen(tester, const SettingsScreen());
  });
}
