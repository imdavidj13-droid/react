import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/daily/presentation/daily_run_screen.dart';
import 'package:react/features/dot_sequence/presentation/dot_sequence_screen.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_launch_screen.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';

void main() {
  setUp(() {
    ReactCosmetics.currentTheme = ReactVisualTheme.redline;
  });

  tearDown(() {
    ReactCosmetics.currentTheme = ReactVisualTheme.core;
  });

  Future<void> expectRedlineBackground(
    WidgetTester tester,
    Widget screen,
  ) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(
      scaffold.backgroundColor,
      ReactCosmetics.paletteFor(ReactVisualTheme.redline).background,
    );
    expect(tester.takeException(), isNull);
  }

  testWidgets('Redline applies to Classic gameplay', (tester) async {
    await expectRedlineBackground(
      tester,
      const ReactRunScreen(mode: ReactGameMode.classic),
    );
  });

  testWidgets('Redline applies to Blitz gameplay', (tester) async {
    await expectRedlineBackground(
      tester,
      const ReactRunScreen(mode: ReactGameMode.blitz),
    );
  });

  testWidgets('Redline applies to Endless gameplay', (tester) async {
    await expectRedlineBackground(
      tester,
      const ReactRunScreen(mode: ReactGameMode.endless),
    );
  });

  testWidgets('Redline applies to Pass It gameplay', (tester) async {
    await expectRedlineBackground(
      tester,
      const ReactRunScreen(mode: ReactGameMode.passIt),
    );
  });

  testWidgets('Redline applies to Daily gameplay', (tester) async {
    await expectRedlineBackground(tester, const DailyRunScreen());
  });

  testWidgets('Redline applies to Sequence gameplay', (tester) async {
    await expectRedlineBackground(tester, const DotSequenceScreen());
  });

  testWidgets('Redline applies to every countdown launch mode', (tester) async {
    for (final mode in <ReactGameMode>[
      ReactGameMode.classic,
      ReactGameMode.blitz,
      ReactGameMode.endless,
      ReactGameMode.daily,
      ReactGameMode.sequence,
    ]) {
      await expectRedlineBackground(
        tester,
        ReactRunLaunchScreen(mode: mode, consumeDailyAttempt: false),
      );
    }
  });
}
