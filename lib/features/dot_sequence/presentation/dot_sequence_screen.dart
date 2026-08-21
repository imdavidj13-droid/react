import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/cosmetics/react_cosmetics.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/run_meta_hud.dart';
import '../../results/presentation/results_screen.dart';
import '../domain/dot_sequence_round.dart';

enum _SequenceTransition { none, nextRound, results }

class DotSequenceScreen extends StatefulWidget {
  const DotSequenceScreen({super.key});

  @override
  State<DotSequenceScreen> createState() => _DotSequenceScreenState();
}

class _DotSequenceScreenState extends State<DotSequenceScreen>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 32);

  final _random = Random();
  final _clock = Stopwatch();
  Timer? _timer;
  Timer? _nextTimer;

  late DotSequenceRound _round;
  int _score = 0;
  int _lives = 3;
  int _misses = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;
  int _totalClearMs = 0;
  int _nextIndex = 0;
  int _durationMs = 3200;
  int _elapsedBeforeArmMs = 0;
  double _progress = 1;
  bool _accepting = false;
  bool _paused = false;
  bool _gameOver = false;
  bool _finished = false;
  _SequenceTransition _pendingTransition = _SequenceTransition.none;
  String? _feedback;

  int get _dotCount {
    if (_score < 3) return 2;
    if (_score < 8) return 3;
    if (_score < 15) return 4;
    return 5;
  }

  int get _nextDurationMs =>
      (3200 - (_score * 70)).clamp(1600, 3200).toInt();
  int get _elapsedMs => _elapsedBeforeArmMs + _clock.elapsedMilliseconds;
  int get _remainingMs => max(0, _durationMs - _elapsedMs);
  double get _averageClearSeconds =>
      _score == 0 ? 0 : (_totalClearMs / _score) / 1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _round = DotSequenceRound.generate(_random, count: 2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRound());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_paused && !_finished) {
      _setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _nextTimer?.cancel();
    _clock.stop();
    super.dispose();
  }

  void _startRound() {
    if (!mounted || _paused || _gameOver || _finished) return;
    _timer?.cancel();
    _nextTimer?.cancel();
    _pendingTransition = _SequenceTransition.none;
    _clock
      ..stop()
      ..reset();

    setState(() {
      _round = DotSequenceRound.generate(_random, count: _dotCount);
      _nextIndex = 0;
      _durationMs = _nextDurationMs;
      _elapsedBeforeArmMs = 0;
      _progress = 1;
      _feedback = null;
      _accepting = true;
    });

    unawaited(ReactAudio.play(ReactSoundCue.command));
    _armTimer(_durationMs);
  }

  void _armTimer(int remainingMs) {
    if (_paused || _finished || _gameOver) return;
    final safe = remainingMs.clamp(1, _durationMs).toInt();
    _elapsedBeforeArmMs = _durationMs - safe;
    _clock
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted || !_accepting || _paused || _gameOver || _finished) return;
      final remaining = _remainingMs;
      if (remaining <= 0) {
        _loseLife('TOO SLOW');
        return;
      }
      setState(() => _progress = remaining / _durationMs);
    });
  }

  void _tapDot(int index) {
    if (!_accepting || _paused || _gameOver || _finished) return;
    if (index != _nextIndex) {
      _loseLife('WRONG ORDER');
      return;
    }

    if (index < _round.dotCount - 1) {
      setState(() {
        _nextIndex += 1;
        _feedback = 'GOOD';
      });
      unawaited(ReactAudio.play(ReactSoundCue.success));
      return;
    }

    _timer?.cancel();
    _clock.stop();
    final clearMs = _elapsedMs.clamp(0, _durationMs).toInt();
    setState(() {
      _accepting = false;
      _score += 1;
      _currentStreak += 1;
      _maxStreak = max(_maxStreak, _currentStreak);
      _totalClearMs += clearMs;
      _feedback = 'SEQUENCE CLEAR';
      _progress = 0;
    });
    unawaited(ReactAudio.play(ReactSoundCue.success));
    _scheduleTransition(
      const Duration(milliseconds: 260),
      _SequenceTransition.nextRound,
    );
  }

  void _loseLife(String reason) {
    if (!_accepting || _gameOver || _finished) return;
    _timer?.cancel();
    _clock.stop();
    final remainingLives = _lives - 1;
    setState(() {
      _accepting = false;
      _lives = remainingLives;
      _misses += 1;
      _currentStreak = 0;
      _feedback = reason;
      _progress = 0;
      _gameOver = remainingLives <= 0;
    });
    unawaited(ReactAudio.play(ReactSoundCue.miss));

    _scheduleTransition(
      const Duration(milliseconds: 520),
      remainingLives > 0
          ? _SequenceTransition.nextRound
          : _SequenceTransition.results,
    );
  }

  void _scheduleTransition(Duration delay, _SequenceTransition transition) {
    _nextTimer?.cancel();
    _pendingTransition = transition;
    _nextTimer = Timer(delay, _runPendingTransition);
  }

  void _runPendingTransition() {
    if (!mounted || _paused || _finished) return;
    final transition = _pendingTransition;
    _pendingTransition = _SequenceTransition.none;
    _nextTimer = null;
    switch (transition) {
      case _SequenceTransition.none:
        return;
      case _SequenceTransition.nextRound:
        _startRound();
        return;
      case _SequenceTransition.results:
        _finishRun();
        return;
    }
  }

  void _finishRun() {
    if (!mounted || _finished || _paused) return;
    _finished = true;
    _timer?.cancel();
    _nextTimer?.cancel();
    _pendingTransition = _SequenceTransition.none;
    _clock.stop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          result: ReactRunResult(
            mode: ReactGameMode.sequence,
            score: _score,
            successfulCommands: _score,
            averageTimeSeconds: _averageClearSeconds,
            outcome: ReactRunOutcome.missedCommand,
            misses: _misses,
            maxStreak: _maxStreak,
          ),
        ),
      ),
    );
  }

  void _quit() {
    if (_finished || !mounted || _gameOver) return;
    _finished = true;
    _accepting = false;
    _timer?.cancel();
    _nextTimer?.cancel();
    _pendingTransition = _SequenceTransition.none;
    _clock.stop();
    Navigator.of(context).pop();
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;

    if (value) {
      final hadActiveRound = _accepting && !_gameOver;
      final remaining = hadActiveRound ? max(1, _remainingMs) : 0;
      _timer?.cancel();
      _nextTimer?.cancel();
      _clock.stop();
      setState(() {
        _paused = true;
        _accepting = false;
        if (hadActiveRound) {
          _elapsedBeforeArmMs = _durationMs - remaining;
        }
      });
      return;
    }

    final transition = _pendingTransition;
    setState(() => _paused = false);

    if (transition != _SequenceTransition.none) {
      _runPendingTransition();
      return;
    }

    if (_gameOver) {
      _finishRun();
      return;
    }

    setState(() => _accepting = true);
    _armTimer(_durationMs - _elapsedBeforeArmMs);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_finished && !_paused) _setPaused(true);
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final arenaSize = min(
                constraints.maxWidth - 28,
                constraints.maxHeight * .58,
              ).clamp(290.0, 430.0).toDouble();
              return Stack(
                fit: StackFit.expand,
                children: [
                  const _Backdrop(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Column(
                      children: [
                        _Header(onPause: () => _setPaused(true)),
                        const SizedBox(height: 12),
                        _Hud(score: _score, lives: _lives),
                        const SizedBox(height: 8),
                        RunMetaHud(
                          mode: ReactGameMode.sequence,
                          currentScore: _score,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: _Arena(
                              size: arenaSize,
                              round: _round,
                              nextIndex: _nextIndex,
                              progress: _progress,
                              seconds: _remainingMs / 1000,
                              enabled: _accepting,
                              onTap: _tapDot,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: Center(
                            child: Text(
                              _gameOver ? 'RUN OVER' : _feedback ?? '',
                              style: TextStyle(
                                color: _feedback == 'GOOD' ||
                                        _feedback == 'SEQUENCE CLEAR'
                                    ? palette.secondary
                                    : palette.failure,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                        ),
                        _BottomBar(score: _score, dots: _dotCount),
                      ],
                    ),
                  ),
                  if (_paused)
                    _Overlay(
                      title: 'SEQUENCE PAUSED',
                      subtitle: _gameOver
                          ? 'THE FINISHED RUN IS FROZEN'
                          : 'THE CURRENT ROUND IS FROZEN',
                      primary: _gameOver ? 'SHOW RESULTS' : 'RESUME',
                      onPrimary: () => _setPaused(false),
                      secondary: _gameOver ? null : 'QUIT RUN',
                      onSecondary: _gameOver ? null : _quit,
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
  const _Header({required this.onPause});
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    return Row(
      children: [
        IconButton(
          onPressed: onPause,
          style: IconButton.styleFrom(
            backgroundColor: _themePanelColor(),
            foregroundColor: ReactColors.textPrimary,
            side: BorderSide(color: _themeBorderColor()),
          ),
          icon: const Icon(Icons.pause_rounded),
        ),
        const Spacer(),
        const Text(
          'RE△CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const Spacer(),
        SizedBox(width: 48, child: Icon(Icons.circle, color: palette.primary, size: 0)),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.score, required this.lives});
  final int score;
  final int lives;

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    return Row(
      children: [
        Expanded(
          child: _HudCard(
            label: 'SCORE',
            child: Text(
              '$score',
              style: TextStyle(
                color: palette.secondary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HudCard(
            label: 'MODE',
            child: Text(
              'SEQUENCE',
              style: TextStyle(
                color: palette.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HudCard(
            label: 'LIVES',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.favorite_rounded,
                    size: 19,
                    color: i < lives
                        ? palette.failure
                        : ReactColors.textSecondary.withValues(alpha: .18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HudCard extends StatelessWidget {
  const _HudCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: _themePanelColor(),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _themeBorderColor()),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(' ', style: TextStyle(fontSize: 0)),
              Text(
                label,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              child,
            ],
          ),
        ),
      );
}

class _Arena extends StatelessWidget {
  const _Arena({
    required this.size,
    required this.round,
    required this.nextIndex,
    required this.progress,
    required this.seconds,
    required this.enabled,
    required this.onTap,
  });

  final double size;
  final DotSequenceRound round;
  final int nextIndex;
  final double progress;
  final double seconds;
  final bool enabled;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    final centre = size / 2;
    final fieldCentreY = centre + size * .065;
    final placementRadius = size * .30;
    final dotSize = (size * .135).clamp(44.0, 58.0).toDouble();

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ArenaPainter(progress))),
          Center(
            child: Container(
              width: size * .69,
              height: size * .69,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _themeArenaSurfaceColor(),
                border: Border.all(color: _themeInnerBorderColor(), width: 1.5),
              ),
            ),
          ),
          Positioned(
            top: size * .018,
            left: centre - 37,
            child: Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _themePanelColor(),
                border: Border.all(color: _themeBorderColor(), width: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      seconds.clamp(0, 9.99).toStringAsFixed(2),
                      style: TextStyle(
                        color: progress < .22 ? palette.failure : palette.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'SEC',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: size * .235,
            left: size * .16,
            right: size * .16,
            child: Column(
              children: [
                Text(
                  '${min(nextIndex + 1, round.dotCount)}/${round.dotCount}',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'DOT SEQUENCE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'TAP THE DOTS IN ORDER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < round.positions.length; index++)
            Positioned(
              left: centre + round.positions[index].dx * placementRadius - dotSize / 2,
              top: fieldCentreY + round.positions[index].dy * placementRadius - dotSize / 2,
              child: _Dot(
                number: index + 1,
                size: dotSize,
                active: index == nextIndex,
                completed: index < nextIndex,
                enabled: enabled,
                onTap: () => onTap(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.number,
    required this.size,
    required this.active,
    required this.completed,
    required this.enabled,
    required this.onTap,
  });

  final int number;
  final double size;
  final bool active;
  final bool completed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    final accent = active
        ? palette.primary
        : completed
            ? palette.secondary
            : palette.primary.withValues(alpha: .48);
    return Semantics(
      button: true,
      label: 'Dot $number',
      child: GestureDetector(
        key: ValueKey<String>('sequence-dot-$number'),
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _themeDotSurfaceColor(),
            border: Border.all(color: accent, width: active ? 2.6 : 1.5),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: .38),
                      blurRadius: 14,
                      spreadRadius: 1.5,
                    ),
                  ]
                : const [],
          ),
          child: completed
              ? Icon(Icons.check_rounded, color: palette.secondary, size: 22)
              : Text(
                  '$number',
                  style: TextStyle(
                    color: accent,
                    fontSize: size * .40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  const _ArenaPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = ReactCosmetics.palette;
    final centre = size.center(Offset.zero);
    final radius = size.width * .44;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = _themeRingBaseColor();
    canvas.drawCircle(centre, radius, base);

    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    deco.color = palette.primary.withValues(alpha: .72);
    canvas.drawArc(Rect.fromCircle(center: centre, radius: radius), .8, 1.45, false, deco);
    deco.color = palette.secondary.withValues(alpha: .72);
    canvas.drawArc(Rect.fromCircle(center: centre, radius: radius), 3.0, 1.25, false, deco);
    deco.color = palette.failure.withValues(alpha: .72);
    canvas.drawArc(Rect.fromCircle(center: centre, radius: radius), 4.75, 1.1, false, deco);

    final timerRadius = radius + 14;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = _themeTimerTrackColor();
    canvas.drawCircle(centre, timerRadius, track);

    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..color = progress < .22 ? palette.failure : palette.primary;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: timerRadius),
      -pi / 2,
      pi * 2 * progress,
      false,
      timer,
    );
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      ReactCosmetics.currentTheme != ReactVisualTheme.core;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.score, required this.dots});
  final int score;
  final int dots;

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _themePanelColor(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _themeBorderColor()),
      ),
      child: Row(
        children: [
          Icon(Icons.blur_circular_rounded, color: palette.primary, size: 21),
          const SizedBox(width: 8),
          Text(
            'SEQUENCE',
            style: TextStyle(
              color: palette.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _Metric(label: 'SCORE', value: '$score'),
          const SizedBox(width: 22),
          _Metric(label: 'DOTS', value: '$dots'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    return ColoredBox(
      color: const Color(0xE8050911),
      child: Center(
        child: Container(
          width: 310,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _themePanelColor(),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _themeBorderColor()),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.blur_circular_rounded, color: palette.primary, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onPrimary, child: Text(primary)),
              ),
              if (secondary != null && onSecondary != null)
                TextButton(onPressed: onSecondary, child: Text(secondary!)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BackdropPainter());
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final palette = ReactCosmetics.palette;
    final paint = Paint()..color = palette.primary.withValues(alpha: .17);
    const points = <Offset>[
      Offset(.08, .18),
      Offset(.23, .09),
      Offset(.47, .05),
      Offset(.72, .14),
      Offset(.91, .29),
      Offset(.14, .47),
      Offset(.61, .42),
      Offset(.83, .57),
      Offset(.31, .73),
      Offset(.56, .82),
      Offset(.88, .91),
      Offset(.11, .88),
    ];
    for (final point in points) {
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      ReactCosmetics.currentTheme != ReactVisualTheme.core;
}

Color _themePanelColor() => switch (ReactCosmetics.currentTheme) {
      ReactVisualTheme.core => const Color(0xFF07111D),
      ReactVisualTheme.redline => const Color(0xFF14080B),
      ReactVisualTheme.synthwave => const Color(0xFF0D0920),
      ReactVisualTheme.mono => const Color(0xFF0A0A0A),
    };

Color _themeArenaSurfaceColor() => switch (ReactCosmetics.currentTheme) {
      ReactVisualTheme.core => const Color(0xFF050A13),
      ReactVisualTheme.redline => const Color(0xFF100609),
      ReactVisualTheme.synthwave => const Color(0xFF090718),
      ReactVisualTheme.mono => const Color(0xFF050505),
    };

Color _themeDotSurfaceColor() => switch (ReactCosmetics.currentTheme) {
      ReactVisualTheme.core => const Color(0xFF06101D),
      ReactVisualTheme.redline => const Color(0xFF16090C),
      ReactVisualTheme.synthwave => const Color(0xFF100B24),
      ReactVisualTheme.mono => const Color(0xFF0C0C0C),
    };

Color _themeBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF254766)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _themeInnerBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF153B65)
    : ReactCosmetics.palette.primary.withValues(alpha: .44);

Color _themeRingBaseColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF122038)
    : ReactCosmetics.palette.primary.withValues(alpha: .16);

Color _themeTimerTrackColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF10243D)
    : ReactCosmetics.palette.primary.withValues(alpha: .20);
