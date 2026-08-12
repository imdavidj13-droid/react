import 'package:flutter_test/flutter_test.dart';
import 'package:react/app/react_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the React home shell and local records', (tester) async {
    SharedPreferences.setMockInitialValues({
      'best_classic': 12,
      'best_blitz': 18,
      'best_endless': 9,
      'daily_streak': 3,
      'runs_played': 27,
    });

    await tester.pumpWidget(const ReactApp());
    await tester.pumpAndSettle();

    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('MODES'), findsOneWidget);
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('SCORES'), findsOneWidget);

    expect(find.text('CLASSIC BEST'), findsOneWidget);
    expect(find.text('BLITZ'), findsOneWidget);
    expect(find.text('ENDLESS'), findsOneWidget);
    expect(find.text('RUNS'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
  });
}
