import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/dot_sequence/domain/dot_sequence_round.dart';
import 'package:react/features/dot_sequence/presentation/dot_sequence_screen.dart';

void main() {
  test('generated sequence positions keep safe arena edge clearance', () {
    for (var seed = 0; seed < 100; seed++) {
      final round = DotSequenceRound.generate(Random(seed), count: 5);

      expect(round.dotCount, 5);
      for (final position in round.positions) {
        expect(position.distance, lessThanOrEqualTo(DotSequenceRound.maximumRadius));
      }

      for (var a = 0; a < round.positions.length; a++) {
        for (var b = a + 1; b < round.positions.length; b++) {
          expect(
            (round.positions[a] - round.positions[b]).distance,
            greaterThanOrEqualTo(.32),
          );
        }
      }
    }
  });

  testWidgets('Sequence starts with two dots and accepts them only in order',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DotSequenceScreen()));
    await tester.pump();

    expect(find.text('DOT SEQUENCE'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('sequence-dot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('sequence-dot-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('sequence-dot-1')));
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('sequence-dot-2')));
    await tester.pump();
    expect(find.text('SEQUENCE CLEAR'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a later dot first costs one life', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DotSequenceScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('sequence-dot-2')));
    await tester.pump();

    expect(find.text('WRONG ORDER'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sequence timer miss costs a life and starts another round',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DotSequenceScreen()));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 3250));
    expect(find.text('TOO SLOW'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 530));
    expect(find.text('1/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sequence fits a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DotSequenceScreen()));
    await tester.pump();

    expect(find.text('SEQUENCE'), findsWidgets);
    expect(find.text('DOT SEQUENCE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
