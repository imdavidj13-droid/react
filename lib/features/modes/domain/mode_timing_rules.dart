class ModeTimingRules {
  const ModeTimingRules({
    required this.startCommandMs,
    required this.minimumCommandMs,
    required this.commandSpeedStepMs,
    required this.commandSpeedStepEveryPoints,
    required this.startSuccessDelayMs,
    required this.minimumSuccessDelayMs,
    required this.successDelayStepMs,
    required this.successDelayStepEveryPoints,
    required this.missDelayMs,
    this.runDurationMs,
    this.missTimePenaltyMs = 0,
  });

  final int startCommandMs;
  final int minimumCommandMs;
  final int commandSpeedStepMs;
  final int commandSpeedStepEveryPoints;
  final int startSuccessDelayMs;
  final int minimumSuccessDelayMs;
  final int successDelayStepMs;
  final int successDelayStepEveryPoints;
  final int missDelayMs;
  final int? runDurationMs;
  final int missTimePenaltyMs;

  int commandDurationMsForScore(int score) {
    if (commandSpeedStepMs <= 0 || commandSpeedStepEveryPoints <= 0) {
      return startCommandMs;
    }

    final steps = score ~/ commandSpeedStepEveryPoints;
    final duration = startCommandMs - (steps * commandSpeedStepMs);
    return duration.clamp(minimumCommandMs, startCommandMs);
  }

  int successDelayMsForScore(int score) {
    if (successDelayStepMs <= 0 || successDelayStepEveryPoints <= 0) {
      return startSuccessDelayMs;
    }

    final steps = score ~/ successDelayStepEveryPoints;
    final delay = startSuccessDelayMs - (steps * successDelayStepMs);
    return delay.clamp(minimumSuccessDelayMs, startSuccessDelayMs);
  }
}

abstract final class ReactModeTiming {
  static const classic = ModeTimingRules(
    startCommandMs: 2300,
    minimumCommandMs: 1250,
    commandSpeedStepMs: 100,
    commandSpeedStepEveryPoints: 5,
    startSuccessDelayMs: 500,
    minimumSuccessDelayMs: 260,
    successDelayStepMs: 40,
    successDelayStepEveryPoints: 8,
    missDelayMs: 600,
  );

  static const blitz = ModeTimingRules(
    startCommandMs: 1450,
    minimumCommandMs: 1000,
    commandSpeedStepMs: 75,
    commandSpeedStepEveryPoints: 10,
    startSuccessDelayMs: 240,
    minimumSuccessDelayMs: 180,
    successDelayStepMs: 20,
    successDelayStepEveryPoints: 15,
    missDelayMs: 420,
    runDurationMs: 60000,
    missTimePenaltyMs: 3000,
  );

  static const endless = ModeTimingRules(
    startCommandMs: 2000,
    minimumCommandMs: 900,
    commandSpeedStepMs: 100,
    commandSpeedStepEveryPoints: 2,
    startSuccessDelayMs: 300,
    minimumSuccessDelayMs: 80,
    successDelayStepMs: 35,
    successDelayStepEveryPoints: 3,
    missDelayMs: 0,
  );

  // Daily is an uncapped endurance run. The pace tightens to protected floors
  // while the selected Daily modifier provides the day's rule twist.
  static const daily = ModeTimingRules(
    startCommandMs: 1850,
    minimumCommandMs: 950,
    commandSpeedStepMs: 75,
    commandSpeedStepEveryPoints: 5,
    startSuccessDelayMs: 360,
    minimumSuccessDelayMs: 120,
    successDelayStepMs: 20,
    successDelayStepEveryPoints: 5,
    missDelayMs: 0,
  );

  static const passIt = ModeTimingRules(
    startCommandMs: 1900,
    minimumCommandMs: 1400,
    commandSpeedStepMs: 100,
    commandSpeedStepEveryPoints: 9,
    startSuccessDelayMs: 700,
    minimumSuccessDelayMs: 600,
    successDelayStepMs: 50,
    successDelayStepEveryPoints: 18,
    missDelayMs: 850,
  );
}
