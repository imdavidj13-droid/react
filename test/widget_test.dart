import 'package:flutter_test/flutter_test.dart';
import 'package:react/app/react_app.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  String todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  setUp(() {
    ReactSettings.howToPlayCompleted = true;
  });

  testWidgets('shows the React home shell and local records', (tester) async {
    SharedPreferences.setMockInitialValues({
      'best_classic': 12,
      'best_blitz': 18,
      'best_endless': 9,
      'daily_streak': 3,
      'runs_played': 27,
    });

    await tester.pumpWidget(const ReactApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('MODES'), findsOneWidget);
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('PASS'), findsOneWidget);
    expect(find.text('LOCKER'), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);

    expect(find.text('CLASSIC BEST'), findsOneWidget);
    expect(find.text('BLITZ'), findsOneWidget);
    expect(find.text('ENDLESS'), findsOneWidget);
    expect(find.text('RUNS'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
  });

  testWidgets('Home offers Daily replay after today has been attempted',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'daily_last_played': todayKey(),
    });

    await tester.pumpWidget(const ReactApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // The compact four-column tile uses AGAIN rather than the old PLAY AGAIN.
    expect(find.text('AGAIN'), findsOneWidget);
    expect(find.text('READY'), findsNothing);
  });
}
