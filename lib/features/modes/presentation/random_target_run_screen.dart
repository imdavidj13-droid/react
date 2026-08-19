import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/cosmetics/react_cosmetics.dart';
import '../../../core/theme/react_colors.dart';
import '../data/local_variant_mode_stats.dart';
import '../domain/react_variant_mode.dart';
import 'variant_run_screen.dart';

class RandomTargetRunScreen extends StatefulWidget {
  const RandomTargetRunScreen({required this.mode, super.key})
      : assert(
          mode == ReactVariantMode.ricochet || mode == ReactVariantMode.vortex,
        );

  final ReactVariantMode mode;

  @override
  State<RandomTargetRunScreen> createState() => _RandomTargetRunScreenState();
}

class _RandomTargetRunScreenState extends State<RandomTargetRunScreen>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 16);

  final Random _random = Random();
  final Stopwatch _roundClock = Stopwatch();

  Timer? _ticker;
  Timer? _countdownTimer;

  int _countdown = 3;
  int _score = 0;
  int _lives = 3;
  int _streak = 0;
  int _maxStreak = 0;
  int _roundDurationMs = 2300;

  bool _go = false;
  bool _running = false;
  bool _paused = false;
  bool _finished = false;

  String? _feedback;

  // Ricochet state.
  double _x = .5;
  double _y = .5;
  double _vx = .5;
  double _vy = .5;
  Duration _lastTickElapsed = Duration.zero;

  // Vortex state. Every successful hit regenerates all of these values.
  double _vortexStartAngle = 0;
  double _vortexAngularSpeed = 4;
  double _vortexDirection = 1;
  double _vortexStartRadius = .36;
  double _vortexEndRadius = .08;
  double _vortexRadialPower = 1;

  ReactVariantMode get mode => widget.mode;
  ReactCosmeticPalette get _palette => ReactCosmetics.palette;
  Color get _accent => ReactCosmetics.effectAccentFor(mode.color);

  int get _remainingMs => max(
        0,
        _roundDurationMs - _roundClock.elapsedMilliseconds,
      );

  double get _progress =>
      (_remainingMs / max(1, _roundDurationMs)).clamp(0.0, 1.0).toDouble();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _randomizePattern();
    _startCountdown();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        _running &&
        !_paused &&
        !_finished) {
      _setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _countdownTimer?.cancel();
    _roundClock.stop();
    super.dispose();
  }

  void _startCountdown() {
    unawaited(ReactAudio.play(ReactSoundCue.countdownTick));
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _paused || _finished) return;
      if (_countdown > 1) {
        setState(() => _countdown -= 1);
        unawaited(ReactAudio.play(ReactSoundCue.countdownTick));
        return;
      }
      if (!_go) {
        setState(() => _go = true);
        unawaited(ReactAudio.play(ReactSoundCue.countdownGo));
        return;
      }
      _countdownTimer?.cancel();
      _beginRun();
    });
  }

  void _beginRun() {
    if (!mounted || _finished) return;
    _running = true;
    _armRound();
    _ticker = Timer.periodic(_tick, _onTick);
    setState(() {});
  }

  void _armRound() {
    _roundDurationMs = max(1050, 2300 - _score * 24);
    _roundClock
      ..reset()
      ..start();
    _lastTickElapsed = Duration.zero;
    unawaited(ReactAudio.play(ReactSoundCue.command));
  }

  void _onTick(Timer timer) {
    if (!mounted || !_running || _paused || _finished) return;
    if (_remainingMs <= 0) {
      _miss('TOO SLOW');
      return;
    }

    if (mode == ReactVariantMode.ricochet) {
      final elapsed = _roundClock.elapsed;
      final dt = _lastTickElapsed == Duration.zero
          ? _tick.inMicroseconds / Duration.microsecondsPerSecond
          : (elapsed - _lastTickElapsed).inMicroseconds /
              Duration.microsecondsPerSecond;
      _lastTickElapsed = elapsed;

      _x += _vx * dt;
      _y += _vy * dt;

      const minEdge = .10;
      const maxEdge = .90;
      if (_x <= minEdge) {
        _x = minEdge;
        _vx = _vx.abs();
      } else if (_x >= maxEdge) {
        _x = maxEdge;
        _vx = -_vx.abs();
      }
      if (_y <= minEdge) {
        _y = minEdge;
        _vy = _vy.abs();
      } else if (_y >= maxEdge) {
        _y = maxEdge;
        _vy = -_vy.abs();
      }
    }

    setState(() {});
  }

  void _randomizePattern() {
    if (mode == ReactVariantMode.ricochet) {
      _x = .14 + _random.nextDouble() * .72;
      _y = .14 + _random.nextDouble() * .72;

      double angle;
      do {
        angle = _random.nextDouble() * pi * 2;
      } while (cos(angle).abs() < .22 || sin(angle).abs() < .22);

      final speed = .38 + _random.nextDouble() * .52;
      _vx = cos(angle) * speed;
      _vy = sin(angle) * speed;
      return;
    }

    _vortexStartAngle = _random.nextDouble() * pi * 2;
    _vortexDirection = _random.nextBool() ? 1 : -1;
    _vortexAngularSpeed = 2.7 + _random.nextDouble() * 4.4;
    _vortexStartRadius = .30 + _random.nextDouble() * .10;
    _vortexEndRadius = .045 + _random.nextDouble() * .065;
    _vortexRadialPower = .65 + _random.nextDouble() * 1.25;
  }

  Offset _target(double size) {
    if (mode == ReactVariantMode.ricochet) {
      return Offset(_x * size, _y * size);
    }

    final elapsed = _roundClock.elapsedMilliseconds / 1000;
    final t = (1 - _progress).clamp(0.0, 1.0).toDouble();
    final curvedT = pow(t, _vortexRadialPower).toDouble();
    final radiusFraction =
        _vortexStartRadius + (_vortexEndRadius - _vortexStartRadius) * curvedT;
    final angle = _vortexStartAngle +
        elapsed * _vortexAngularSpeed * _vortexDirection;

    return Offset(
      size / 2 + cos(angle) * size * radiusFraction,
      size / 2 + sin(angle) * size * radiusFraction,
    );
  }

  void _hit() {
    if (!_running || _paused || _finished || !_roundClock.isRunning) return;

    _roundClock.stop();
    _score += 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);
    _feedback = '+1  NEW PATTERN';
    unawaited(ReactAudio.play(ReactSoundCue.success));

    // Every successful target generates a genuinely new motion profile.
    _randomizePattern();
    _armRound();
    setState(() {});
  }

  void _miss(String reason) {
    if (_finished || !_running) return;
    _roundClock.stop();
    _lives -= 1;
    _streak = 0;
    _feedback = '$reason  •  $_lives ${_lives == 1 ? 'LIFE' : 'LIVES'}';
    unawaited(ReactAudio.play(ReactSoundCue.lifeLost));

    if (_lives <= 0) {
      unawaited(_finish(reason));
      return;
    }

    _randomizePattern();
    _armRound();
    setState(() {});
  }

  Future<void> _finish(String reason) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker?.cancel();
    _countdownTimer?.cancel();
    _roundClock.stop();
    unawaited(ReactAudio.play(ReactSoundCue.completed));

    final newBest = await LocalVariantModeStats.record(mode, _score);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VariantResultsScreen(
          mode: mode,
          score: _score,
          maxStreak: _maxStreak,
          reason: reason,
          newBest: newBest,
        ),
      ),
    );
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;
    setState(() => _paused = value);
    if (value) {
      _roundClock.stop();
      return;
    }
    if (_running) {
      _roundClock.start();
      _lastTickElapsed = _roundClock.elapsed;
    }
  }

  void _quit() {
    if (!mounted || _finished) return;
    _finished = true;
    _ticker?.cancel();
    _countdownTimer?.cancel();
    _roundClock.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_paused && !_finished) _setPaused(true);
      },
      child: Scaffold(
        backgroundColor: _palette.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final arenaSize = min(
                constraints.maxWidth - 28,
                constraints.maxHeight * .58,
              ).clamp(280.0, 390.0).toDouble();
              final target = _target(arenaSize);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      children: [
                        _Header(
                          mode: mode,
                          score: _score,
                          lives: _lives,
                          accent: _accent,
                          failure: _palette.failure,
                          onPause: () => _setPaused(true),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Center(
                            child: SizedBox.square(
                              dimension: arenaSize,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _palette.background.withValues(alpha: .90),
                                  border: Border.all(
                                    color: _accent.withValues(alpha: .48),
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: target.dx - 31,
                                      top: target.dy - 31,
                                      child: GestureDetector(
                                        key: const ValueKey('random_target'),
                                        onTap: _hit,
                                        child: Container(
                                          width: 62,
                                          height: 62,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _accent.withValues(alpha: .15),
                                            border: Border.all(
                                              color: _accent,
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _accent.withValues(alpha: .28),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            mode.icon,
                                            color: _accent,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              _feedback ??
                                  (mode == ReactVariantMode.ricochet
                                      ? 'TRACK THE BOUNCE'
                                      : 'TRACK THE SPIRAL'),
                              style: TextStyle(
                                color: _accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: .045),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: _accent.withValues(alpha: .22),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 72,
                                child: Text(
                                  'ROUND',
                                  style: TextStyle(
                                    color: ReactColors.textSecondary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 7,
                                    backgroundColor:
                                        _accent.withValues(alpha: .10),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(_accent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_running)
                    _Countdown(
                      mode: mode,
                      count: _countdown,
                      go: _go,
                      accent: _accent,
                      background: _palette.background,
                    ),
                  if (_paused)
                    _Pause(
                      accent: _accent,
                      background: _palette.background,
                      onResume: () => _setPaused(false),
                      onQuit: _quit,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.score,
    required this.lives,
    required this.accent,
    required this.failure,
    required this.onPause,
  });

  final ReactVariantMode mode;
  final int score;
  final int lives;
  final Color accent;
  final Color failure;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: onPause,
            style: IconButton.styleFrom(
              backgroundColor: accent.withValues(alpha: .07),
              foregroundColor: ReactColors.textPrimary,
              side: BorderSide(color: accent.withValues(alpha: .30)),
            ),
            icon: const Icon(Icons.pause_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.title,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'RANDOM PATTERN EACH HIT',
                  style: TextStyle(
                    color: accent,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _Metric(label: 'SCORE', value: '$score', color: accent),
          const SizedBox(width: 8),
          _Metric(
            label: 'LIVES',
            value: List<String>.filled(lives, '♥').join(),
            color: failure,
          ),
        ],
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 62),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _Countdown extends StatelessWidget {
  const _Countdown({
    required this.mode,
    required this.count,
    required this.go,
    required this.accent,
    required this.background,
  });

  final ReactVariantMode mode;
  final int count;
  final bool go;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: background.withValues(alpha: .96),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mode.title,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                go ? 'GO' : '$count',
                style: TextStyle(
                  color: go ? accent : ReactColors.textPrimary,
                  fontSize: go ? 88 : 116,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Pause extends StatelessWidget {
  const _Pause({
    required this.accent,
    required this.background,
    required this.onResume,
    required this.onQuit,
  });

  final Color accent;
  final Color background;
  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black.withValues(alpha: .88),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: .55)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onResume,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('RESUME'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onQuit,
                    child: const Text('QUIT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
