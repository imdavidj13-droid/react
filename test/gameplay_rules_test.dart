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
    test('ramps aggressively to its floor', () {
      expect(ReactModeTiming.endless.commandDurationMsForScore(0), 2000);
      expect(ReactModeTiming.endless.commandDurationMsForScore(2), 1900);
      expect(ReactModeTiming.endless.commandDurationMsForScore(24), 800);
      expect(ReactModeTiming.endless.commandDurationMsForScore(500), 800);
    });

    test('transition gap collapses at high scores', () {
      expect(ReactModeTiming.endless.successDelayMsForScore(0), 300);
      expect(ReactModeTiming.endless.successDelayMsForScore(500), 80);
    });
  });

  group('blitz timing', () {
    test('is a sixty second run with a three second miss penalty', () {
      expect(ReactModeTiming.blitz.runDurationMs, 60000);
      expect(ReactModeTiming.blitz.missTimePenaltyMs, 3000);
    });
  });
}
