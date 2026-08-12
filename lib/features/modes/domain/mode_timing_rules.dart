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

  // Compatibility for screens still being moved onto score-aware transition
  // timing. This always returns the starting delay; use successDelayMsForScore
  // for the audited ramp.
  int get successDelayMs => startSuccessDelayMs;

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
  // CLASSIC
  // Starts deliberately readable, then tightens steadily. Three lives give the
  // player room to recover, so the mode can become genuinely quick at higher
  // scores without feeling unfair early on.
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

  // BLITZ
  // Fixed 60-second score attack. Fast from the beginning, but misses cost
  // clock time rather than ending the run.
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

  // ENDLESS
  // Survival mode. It becomes hostile quickly: both the reaction window and
  // the gap between commands collapse as score rises. One miss ends the run.
  static const endless = ModeTimingRules(
    startCommandMs: 2000,
    minimumCommandMs: 800,
    commandSpeedStepMs: 100,
    commandSpeedStepEveryPoints: 2,
    startSuccessDelayMs: 300,
    minimumSuccessDelayMs: 80,
    successDelayStepMs: 35,
    successDelayStepEveryPoints: 3,
    missDelayMs: 0,
  );

  // DAILY
  // Stable pace so every player receives the same meaningful challenge. The
  // deterministic sequence matters more than a hidden speed curve.
  static const daily = ModeTimingRules(
    startCommandMs: 1900,
    minimumCommandMs: 1900,
    commandSpeedStepMs: 0,
    commandSpeedStepEveryPoints: 0,
    startSuccessDelayMs: 420,
    minimumSuccessDelayMs: 420,
    successDelayStepMs: 0,
    successDelayStepEveryPoints: 0,
    missDelayMs: 0,
  );

  // PASS IT
  // The command itself can tighten a little, but the hand-over gap remains
  // intentionally generous so the next player can physically receive the phone.
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
