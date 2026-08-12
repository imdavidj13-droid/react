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

  Future<void> pumpAtSize(
    WidgetTester tester,
    Widget screen,
    Size logicalSize,
  ) async {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }

  testWidgets('Home fits a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const HomeScreen(), const Size(320, 640));
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('RUNS'), findsOneWidget);
  });

  testWidgets('Home fits a 412x915 screen', (tester) async {
    await pumpAtSize(tester, const HomeScreen(), const Size(412, 915));
    expect(find.text('CLASSIC BEST'), findsOneWidget);
    expect(find.text('ENDLESS'), findsOneWidget);
  });

  testWidgets('Modes fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const ModesScreen(), const Size(320, 640));
    expect(find.text('CLASSIC'), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PROFILE'), findsOneWidget);
  });

  testWidgets('Pass It setup fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const PassItScreen(), const Size(320, 640));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('START GAME'), findsOneWidget);
  });

  testWidgets('Profile settings fits and scrolls on a 320x640 screen', (tester) async {
    await pumpAtSize(tester, const SettingsScreen(), const Size(320, 640));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('RESET LOCAL PROGRESS'), findsOneWidget);
  });
}
