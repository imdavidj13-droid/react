import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/daily/presentation/daily_run_screen.dart';
import 'package:react/features/dot_sequence/presentation/dot_sequence_screen.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_launch_screen.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactCosmetics.equipReactionPack(ReactReactionPack.core);
  });

  tearDown(() async {
    await ReactCosmetics.equipReactionPack(ReactReactionPack.core);
  });

  Future<void> expectPackBackground(
    WidgetTester tester,
    ReactReactionPack pack,
    Widget screen,
  ) async {
    await ReactCosmetics.equipReactionPack(pack);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(
      scaffold.backgroundColor,
      ReactCosmetics.paletteForReactionPack(pack).background,
      reason: pack.packId,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('Redline applies to every gameplay renderer', (tester) async {
    for (final screen in <Widget>[
      const ReactRunScreen(mode: ReactGameMode.classic),
      const ReactRunScreen(mode: ReactGameMode.blitz),
      const ReactRunScreen(mode: ReactGameMode.endless),
      const ReactRunScreen(mode: ReactGameMode.passIt),
      const DailyRunScreen(),
      const DotSequenceScreen(),
    ]) {
      await expectPackBackground(tester, ReactReactionPack.redline, screen);
    }
  });

  testWidgets('four new colour packs apply across every gameplay renderer',
      (tester) async {
    for (final pack in <ReactReactionPack>[
      ReactReactionPack.greenline,
      ReactReactionPack.voltage,
      ReactReactionPack.ember,
      ReactReactionPack.hotPink,
    ]) {
      for (final screen in <Widget>[
        const ReactRunScreen(mode: ReactGameMode.classic),
        const ReactRunScreen(mode: ReactGameMode.blitz),
        const ReactRunScreen(mode: ReactGameMode.endless),
        const ReactRunScreen(mode: ReactGameMode.passIt),
        const DailyRunScreen(),
        const DotSequenceScreen(),
      ]) {
        await expectPackBackground(tester, pack, screen);
      }
    }
  });

  testWidgets('equipped reaction pack applies to every countdown launch mode',
      (tester) async {
    for (final pack in <ReactReactionPack>[
      ReactReactionPack.redline,
      ReactReactionPack.greenline,
      ReactReactionPack.voltage,
      ReactReactionPack.ember,
      ReactReactionPack.hotPink,
    ]) {
      for (final mode in <ReactGameMode>[
        ReactGameMode.classic,
        ReactGameMode.blitz,
        ReactGameMode.endless,
        ReactGameMode.daily,
        ReactGameMode.sequence,
      ]) {
        await expectPackBackground(
          tester,
          pack,
          ReactRunLaunchScreen(mode: mode, consumeDailyAttempt: false),
        );
      }
    }
  });
}
