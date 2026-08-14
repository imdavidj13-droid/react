import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/results/presentation/result_share_screen.dart';

void main() {
  testWidgets('Share result preview fits a 320x640 screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const result = ReactRunResult(
      mode: ReactGameMode.classic,
      score: 42,
      successfulCommands: 42,
      averageTimeSeconds: .68,
      outcome: ReactRunOutcome.missedCommand,
      misses: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ResultShareScreen(result: result, newBest: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHARE RESULT'), findsOneWidget);
    expect(find.text('SHARE IMAGE'), findsOneWidget);
    expect(find.text('NEW PERSONAL BEST'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
