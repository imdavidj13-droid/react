import 'package:flutter_test/flutter_test.dart';
import 'package:react/app/react_app.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.howToPlayCompleted = false;
  });

  testWidgets('fresh install opens How to Play first', (tester) async {
    ReactSettings.howToPlayCompleted = false;

    await tester.pumpWidget(const ReactApp());
    await tester.pump();

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('9 COMMANDS. ONE SIMPLE RULE.'), findsOneWidget);
  });

  testWidgets('completed tutorial opens Home instead', (tester) async {
    ReactSettings.howToPlayCompleted = true;

    await tester.pumpWidget(const ReactApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // HOW TO PLAY is now an intentional Home navigation tile. The tutorial's
    // intro copy must be absent while the actual Home hero is present.
    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('9 COMMANDS. ONE SIMPLE RULE.'), findsNothing);
    expect(find.textContaining('FOLLOW THE COMMAND'), findsOneWidget);
  });
}
