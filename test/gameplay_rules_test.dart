import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/domain/react_command.dart';
import 'package:react/features/modes/domain/mode_timing_rules.dart';

void main() {
  group('command pool', () {
    test('contains exactly nine active commands', () {
      expect(ReactCommand.values.length, 9);
      expect(ReactCommand.values, contains(ReactCommand.pinch));
      expect(ReactCommand.values, contains(ReactCommand.spread));
    });

    test('complex commands have protected reaction floors', () {
      expect(ReactCommand.tap.reactionWindowMs(300), 650);
      expect(ReactCommand.doubleTap.reactionWindowMs(300), 900);
      expect(ReactCommand.hold.reactionWindowMs(300), 1000);
      expect(ReactCommand.swipeLeft.reactionWindowMs(300), 750);
      expect(ReactCommand.swipeRight.reactionWindowMs(300), 750);
      expect(ReactCommand.swipeUp.reactionWindowMs(300), 750);
      expect(ReactCommand.swipeDown.reactionWindowMs(300), 750);
      expect(ReactCommand.pinch.reactionWindowMs(300), 1050);
      expect(ReactCommand.spread.reactionWindowMs(300), 1050);
    });

    test('command multipliers still apply above their minimum floors', () {
      expect(ReactCommand.tap.reactionWindowMs(1500), 1500);
      expect(ReactCommand.doubleTap.reactionWindowMs(1500), 1650);
      expect(ReactCommand.hold.reactionWindowMs(1500), 1830);
      expect(ReactCommand.pinch.reactionWindowMs(1500), 1770);
      expect(ReactCommand.spread.reactionWindowMs(1500), 1770);
    });
  });

  group('classic timing', () {
    test('ramps but never goes below its floor', () {
      expect(ReactModeTiming.classic.commandDurationMsForScore(0), 2300);
      expect(ReactModeTiming.classic.commandDurationMsForScore(5), 2200);
      expect(ReactModeTiming.classic.commandDurationMsForScore(500), 1250);
    });

    test('transition delay also ramps', () {
      expect(ReactModeTiming.classic.successDelayMsForScore(0), 500);
      expect(ReactModeTiming.classic.successDelayMsForScore(500), 260);
    });
  });

  group('endless timing', () {
    test('ramps aggressively to its safer floor', () {
      expect(ReactModeTiming.endless.commandDurationMsForScore(0), 2000);
      expect(ReactModeTiming.endless.commandDurationMsForScore(2), 1900);
      expect(ReactModeTiming.endless.commandDurationMsForScore(22), 900);
      expect(ReactModeTiming.endless.commandDurationMsForScore(500), 900);
    });

    test('transition gap collapses at high scores', () {
      expect(ReactModeTiming.endless.successDelayMsForScore(0), 300);
      expect(ReactModeTiming.endless.successDelayMsForScore(500), 80);
    });
  });

  group('daily timing', () {
    test('ramps across the full 60-command challenge', () {
      expect(ReactModeTiming.daily.commandDurationMsForScore(0), 1850);
      expect(ReactModeTiming.daily.commandDurationMsForScore(5), 1775);
      expect(ReactModeTiming.daily.commandDurationMsForScore(30), 1400);
      expect(ReactModeTiming.daily.commandDurationMsForScore(55), 1025);
      expect(ReactModeTiming.daily.commandDurationMsForScore(60), 950);
      expect(ReactModeTiming.daily.commandDurationMsForScore(500), 950);
    });

    test('transition gap keeps tightening into the closing phase', () {
      expect(ReactModeTiming.daily.successDelayMsForScore(0), 360);
      expect(ReactModeTiming.daily.successDelayMsForScore(30), 240);
      expect(ReactModeTiming.daily.successDelayMsForScore(55), 140);
      expect(ReactModeTiming.daily.successDelayMsForScore(60), 120);
      expect(ReactModeTiming.daily.successDelayMsForScore(500), 120);
    });

    test('redline-style compressed bases cannot break physical floors', () {
      const compressedBase = 600;
      expect(ReactCommand.tap.reactionWindowMs(compressedBase), 650);
      expect(ReactCommand.doubleTap.reactionWindowMs(compressedBase), 900);
      expect(ReactCommand.hold.reactionWindowMs(compressedBase), 1000);
      expect(ReactCommand.pinch.reactionWindowMs(compressedBase), 1050);
      expect(ReactCommand.spread.reactionWindowMs(compressedBase), 1050);
    });
  });

  group('blitz timing', () {
    test('is a sixty second run with a three second miss penalty', () {
      expect(ReactModeTiming.blitz.runDurationMs, 60000);
      expect(ReactModeTiming.blitz.missTimePenaltyMs, 3000);
    });
  });
}
