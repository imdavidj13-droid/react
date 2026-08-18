import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/cosmetics/react_cosmetics.dart';
import 'package:react/features/gameplay/domain/react_command.dart';

void main() {
  tearDown(() {
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;
  });

  test('core command presentation remains unchanged', () {
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.core;

    expect(ReactCommand.tap.title, 'TAP IT');
    expect(ReactCommand.spread.hint, 'MOVE TWO FINGERS APART');
    expect(ReactCommand.tap.usesGlitchVisuals, isFalse);
  });

  test('glitch is visibly different while preserving command words and timing', () {
    final coreWindow = ReactCommand.spread.reactionWindowMs(1000);
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.glitch;

    expect(ReactCommand.tap.title, 'TAP IT //');
    expect(ReactCommand.swipeLeft.title, 'SWIPE LEFT //');
    expect(ReactCommand.spread.title, 'SPREAD IT //');
    expect(ReactCommand.spread.hint, '[ MOVE TWO FINGERS APART ]');
    expect(ReactCommand.spread.usesGlitchVisuals, isTrue);
    expect(ReactCommand.spread.reactionWindowMs(1000), coreWindow);
  });

  test('new command text packs are visibly distinct without changing timing', () {
    final coreWindow = ReactCommand.doubleTap.reactionWindowMs(1000);

    final titles = <String>{};
    for (final style in <ReactCommandStyle>[
      ReactCommandStyle.terminal,
      ReactCommandStyle.arcade,
      ReactCommandStyle.minimal,
      ReactCommandStyle.impact,
    ]) {
      ReactCosmetics.currentCommandStyle = style;
      titles.add(ReactCommand.doubleTap.title);
      expect(ReactCommand.doubleTap.reactionWindowMs(1000), coreWindow);
    }

    expect(titles.length, 4);
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.terminal;
    expect(ReactCommand.swipeLeft.title, '> SWIPE_LEFT');
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.minimal;
    expect(ReactCommand.swipeLeft.title, 'LEFT');
  });
}
