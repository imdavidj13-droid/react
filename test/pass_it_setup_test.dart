import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/pass_it/presentation/pass_it_screen.dart';

void main() {
  Future<void> pumpSetup(WidgetTester tester, int players) async {
    ReactSettings.passItPlayerCount = players;
    await tester.pumpWidget(const MaterialApp(home: PassItScreen()));
  }

  for (final players in const [2, 3, 4]) {
    testWidgets('Pass It renders the configured $players-player roster',
        (tester) async {
      await pumpSetup(tester, players);

      expect(find.text('$players PLAYERS'), findsOneWidget);
      for (var player = 1; player <= players; player++) {
        expect(find.text('PLAYER $player'), findsOneWidget);
      }
      if (players < 4) {
        expect(find.text('PLAYER 4'), findsNothing);
      }

      expect(find.text('MISS'), findsOneWidget);
      expect(find.text('THEN PASS'), findsOneWidget);
      expect(
        find.text(
          '$players PLAYERS • KEEP PLAYING UNTIL YOU MISS • THEN PASS',
        ),
        findsOneWidget,
      );
    });
  }
}
