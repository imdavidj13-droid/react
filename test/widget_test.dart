import 'package:flutter_test/flutter_test.dart';
import 'package:react/app/react_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the React home shell', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ReactApp());
    await tester.pumpAndSettle();

    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('MODES'), findsOneWidget);
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('SCORES'), findsOneWidget);
  });
}
