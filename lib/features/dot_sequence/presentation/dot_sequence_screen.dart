import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/domain/react_run_result.dart';
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
    return Scaffold(
      backgroundColor: ReactColors.background,
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
                      const SizedBox(height: 10),
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
                                  ? ReactColors.lime
                                  : ReactColors.coral,
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
                    secondary: 'QUIT RUN',
                    onSecondary: () => Navigator.of(context).pop(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPause});
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: onPause,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF07101E),
              foregroundColor: ReactColors.textPrimary,
              side: const BorderSide(color: Color(0xFF20547C)),
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
          const SizedBox(width: 48),
        ],
      );
}

class _Hud extends StatelessWidget {
  const _Hud({required this.score, required this.lives});
  final int score;
  final int lives;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _HudCard(
              label: 'SCORE',
              child: Text(
                '$score',
                style: const TextStyle(
                  color: ReactColors.lime,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: _HudCard(
              label: 'MODE',
              child: Text(
                'SEQUENCE',
                style: TextStyle(
                  color: ReactColors.electricBlueBright,
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
                          ? ReactColors.coral
                          : ReactColors.textSecondary.withValues(alpha: .18),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _HudCard extends StatelessWidget {
  const _HudCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF254766)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            FittedBox(fit: BoxFit.scaleDown, child: child),
          ],
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
    final centre = size / 2;
    final placementRadius = size * .39;
    final dotSize = (size * .15).clamp(48.0, 64.0).toDouble();
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ArenaPainter(progress)),
          ),
          Positioned(
            top: 4,
            left: centre - 37,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF07111D),
                border: Border.all(color: const Color(0xFF315D86), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    seconds.clamp(0, 9.99).toStringAsFixed(2),
                    style: TextStyle(
                      color: progress < .22
                          ? ReactColors.coral
                          : ReactColors.electricBlueBright,
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
          Positioned(
            top: size * .19,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  '${min(nextIndex + 1, round.dotCount)}/${round.dotCount}',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'DOT SEQUENCE',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const Text(
                  'TAP THE DOTS IN ORDER',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < round.positions.length; index++)
            Positioned(
              left:
                  centre + round.positions[index].dx * placementRadius - dotSize / 2,
              top: centre +
                  round.positions[index].dy * placementRadius -
                  dotSize / 2 +
                  size * .08,
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
    final accent = active
        ? ReactColors.electricBlueBright
        : completed
            ? ReactColors.lime
            : const Color(0xFF2C6A9B);
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
            color: const Color(0xFF06101D),
            border: Border.all(color: accent, width: active ? 2.6 : 1.5),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: ReactColors.electricBlueBright.withValues(alpha: .45),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: completed
              ? const Icon(Icons.check_rounded, color: ReactColors.lime, size: 24)
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
    final centre = size.center(Offset.zero);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF155486);
    canvas.drawCircle(centre, size.width * .43, inner);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFF102A45);
    canvas.drawCircle(centre, size.width * .475, track);

    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = progress < .22
          ? ReactColors.coral
          : ReactColors.electricBlueBright;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: size.width * .475),
      -pi / 2,
      pi * 2 * progress,
      false,
      timer,
    );
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.score, required this.dots});
  final int score;
  final int dots;

  @override
  Widget build(BuildContext context) => Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF254766)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.blur_circular_rounded,
              color: ReactColors.electricBlueBright,
              size: 21,
            ),
            const SizedBox(width: 8),
            const Text(
              'SEQUENCE',
              style: TextStyle(
                color: ReactColors.electricBlueBright,
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
    required this.secondary,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primary;
  final VoidCallback onPrimary;
  final String secondary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xE8050911),
        child: Center(
          child: Container(
            width: 310,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF07111D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2E587C)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.blur_circular_rounded,
                  color: ReactColors.electricBlueBright,
                  size: 48,
                ),
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
                  child: FilledButton(
                    onPressed: onPrimary,
                    child: Text(primary),
                  ),
                ),
                TextButton(onPressed: onSecondary, child: Text(secondary)),
              ],
            ),
          ),
        ),
      );
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BackdropPainter());
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0D3555);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
