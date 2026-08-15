import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactSettings.load();
  });

  test('generic run screen rejects Daily because it has a dedicated engine', () {
    expect(
      () => ReactRunScreen(mode: ReactGameMode.daily),
      throwsAssertionError,
    );
  });

  testWidgets('Blitz shows a TIME UP beat before Results', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReactRunScreen(mode: ReactGameMode.blitz)),
    );
    await tester.pump();

    // Advance beyond the 60 second boundary, then give the periodic game timer
    // one render frame to publish the terminal TIME UP state.
    await tester.pump(const Duration(seconds: 61));
    await tester.pump();

    expect(find.text('TIME UP'), findsOneWidget);
    expect(find.text('60 SECOND SCORE'), findsNothing);

    await tester.pump(const Duration(milliseconds: 319));
    expect(find.text('TIME UP'), findsOneWidget);

    // Cross the transition boundary and render the navigation scheduled by it.
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('60 SECOND SCORE'), findsOneWidget);
  });

  testWidgets('Blitz terminal beat freezes if the app backgrounds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReactRunScreen(mode: ReactGameMode.blitz)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 61));
    await tester.pump();
    expect(find.text('TIME UP'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('60 SECOND SCORE'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 321));
    await tester.pumpAndSettle();
    expect(find.text('60 SECOND SCORE'), findsOneWidget);
  });
}
