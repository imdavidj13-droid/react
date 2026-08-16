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
  });

  test('glitch style changes presentation but not timing', () {
    final coreWindow = ReactCommand.spread.reactionWindowMs(1000);
    ReactCosmetics.currentCommandStyle = ReactCommandStyle.glitch;

    expect(ReactCommand.tap.title, 'TAP//IT');
    expect(ReactCommand.swipeLeft.title, 'SWIPE<LEFT');
    expect(ReactCommand.spread.title, 'SPREAD::OUT');
    expect(ReactCommand.spread.hint, 'MULTI_02 • EXPAND');
    expect(ReactCommand.spread.reactionWindowMs(1000), coreWindow);
  });
}
