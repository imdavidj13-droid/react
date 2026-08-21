import 'package:flutter_test/flutter_test.dart';
import 'package:react/app/react_app.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_how_to_play_completed': true,
    });
    ReactSettings.howToPlayCompleted = true;
  });

  testWidgets('Home exposes primary navigation tiles and Locker opens', (tester) async {
    await tester.pumpWidget(const ReactApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('MODES'), findsOneWidget);
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('PASS'), findsOneWidget);
    expect(find.text('LOCKER'), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);

    // Locker and Friends now live in the Home navigation rather than floating
    // top-chrome buttons. Player Profile remains the single top utility.
    expect(find.byTooltip('Locker'), findsNothing);
    expect(find.byTooltip('Friends'), findsNothing);
    expect(find.byTooltip('Player profile'), findsOneWidget);

    await tester.tap(find.text('LOCKER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Home remains mounted behind the pushed route, so there are now two
    // LOCKER labels. The Locker-specific subtitle proves the destination won.
    expect(find.text('LOCKER'), findsNWidgets(2));
    expect(find.text('ALL EARNED COSMETICS • ONE PLACE TO EQUIP'), findsOneWidget);
  });
}
