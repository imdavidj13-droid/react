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

  testWidgets('Home exposes Shop and opens the storefront', (tester) async {
    await tester.pumpWidget(const ReactApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Shop'), findsOneWidget);

    await tester.tap(find.byTooltip('Shop'));
    await tester.pumpAndSettle();

    expect(find.text('SHOP'), findsOneWidget);
    expect(find.text('MAKE RE△CT YOURS'), findsOneWidget);
  });
}
