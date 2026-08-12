class ModeTimingRules {
  const ModeTimingRules({
    required this.startCommandMs,
    required this.minimumCommandMs,
    required this.speedStepMs,
    required this.speedStepEveryPoints,
    required this.successDelayMs,
    required this.missDelayMs,
    this.runDurationMs,
    this.missTimePenaltyMs = 0,
  });

  final int startCommandMs;
  final int minimumCommandMs;
  final int speedStepMs;
  final int speedStepEveryPoints;
  final int successDelayMs;
  final int missDelayMs;
  final int? runDurationMs;
  final int missTimePenaltyMs;

  int commandDurationMsForScore(int score) {
    if (speedStepMs <= 0 || speedStepEveryPoints <= 0) {
      return startCommandMs;
    }

    final steps = score ~/ speedStepEveryPoints;
    final duration = startCommandMs - (steps * speedStepMs);
    return duration.clamp(minimumCommandMs, startCommandMs);
  }
}

abstract final class ReactModeTiming {
  // Core mode: forgiving, readable pace, 3 lives.
  static const classic = ModeTimingRules(
    startCommandMs: 2200,
    minimumCommandMs: 1500,
    speedStepMs: 100,
    speedStepEveryPoints: 8,
    successDelayMs: 500,
    missDelayMs: 520,
  );

  // Score attack: intentionally fast from the start. Misses do not end the run;
  // they cost clock time and reset combo.
  static const blitz = ModeTimingRules(
    startCommandMs: 1450,
    minimumCommandMs: 1000,
    speedStepMs: 75,
    speedStepEveryPoints: 10,
    successDelayMs: 240,
    missDelayMs: 420,
    runDurationMs: 60000,
    missTimePenaltyMs: 3000,
  );

  // Survival mode: starts relaxed but ramps aggressively. One miss ends the run.
  static const endless = ModeTimingRules(
    startCommandMs: 2400,
    minimumCommandMs: 850,
    speedStepMs: 100,
    speedStepEveryPoints: 2,
    successDelayMs: 360,
    missDelayMs: 0,
  );

  // Same challenge for everyone that day. Stable pace so the sequence, not a
  // hidden speed curve, is what players compete on.
  static const daily = ModeTimingRules(
    startCommandMs: 1900,
    minimumCommandMs: 1900,
    speedStepMs: 0,
    speedStepEveryPoints: 0,
    successDelayMs: 420,
    missDelayMs: 0,
  );

  // Local multiplayer needs enough time to hand the phone over without the
  // command itself becoming trivial.
  static const passIt = ModeTimingRules(
    startCommandMs: 1900,
    minimumCommandMs: 1400,
    speedStepMs: 100,
    speedStepEveryPoints: 9,
    successDelayMs: 700,
    missDelayMs: 850,
  );
}
