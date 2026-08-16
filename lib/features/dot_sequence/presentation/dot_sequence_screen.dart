import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/theme/react_colors.dart';
import '../domain/dot_sequence_round.dart';

class DotSequenceScreen extends StatefulWidget {
  const DotSequenceScreen({super.key});

  @override
  State<DotSequenceScreen> createState() => _DotSequenceScreenState();
}

class _DotSequenceScreenState extends State<DotSequenceScreen>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 32);

  final Random _random = Random();
  final Stopwatch _clock = Stopwatch();

  Timer? _timer;
  late DotSequenceRound _round;

  int _score = 0;
  int _lives = 3;
  int _nextIndex = 0;
  int _roundDurationMs = 3200;
  int _elapsedBeforeArmMs = 0;
  int _totalRoundTimeMs = 0;
  int _completedRounds = 0;

  double _progress = 1;
  bool _paused = false;
  bool _gameOver = false;
  bool _acceptingInput = false;
  String? _feedback;

  int get _dotCount {
    if (_score < 3) return 2;
    if (_score < 8) return 3;
    if (_score < 15) return 4;
    return 5;
  }

  int get _nextRoundDurationMs => (3200 - (_score * 70)).clamp(1600, 3200);

  int get _elapsedMs => _elapsedBeforeArmMs + _clock.elapsedMilliseconds;

  int get _remainingMs => max(0, _roundDurationMs - _elapsedMs);

  double get _averageSeconds => _completedRounds == 0
      ? 0
      : (_totalRoundTimeMs / _completedRounds) / 1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _round = DotSequenceRound.generate(_random, count: 2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRound());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_paused && !_gameOver) {
      _setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }

  void _startRound() {
    if (!mounted || _paused || _gameOver) return;

    _timer?.cancel();
    _clock
      ..stop()
      ..reset();

    final count = _dotCount;
    final duration = _nextRoundDurationMs;

    setState(() {
      _round = DotSequenceRound.generate(_random, count: count);
      _nextIndex = 0;
      _roundDurationMs = duration;
      _elapsedBeforeArmMs = 0;
      _progress = 1;
      _feedback = null;
      _acceptingInput = true;
    });

    unawaited(ReactAudio.play(ReactSoundCue.command));
    _armTimer(duration);
  }

  void _armTimer(int remainingMs) {
    final safe = remainingMs.clamp(1, _roundDurationMs);
    _elapsedBeforeArmMs = _roundDurationMs - safe;
    _clock
      ..reset()
      ..start();

    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted || _paused || _gameOver || !_acceptingInput) return;

      final remaining = _remainingMs;
      if (remaining <= 0) {
        _loseLife('TOO SLOW');
        return;
      }

      setState(() => _progress = remaining / _roundDurationMs);
    });
  }

  void _tapDot(int index) {
    if (!_acceptingInput || _paused || _gameOver) return;

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

    _completeRound();
  }

  void _completeRound() {
    if (!_acceptingInput) return;

    _timer?.cancel();
    _clock.stop();
    final elapsed = _elapsedMs.clamp(0, _roundDurationMs);

    setState(() {
      _acceptingInput = false;
      _score += 1;
      _completedRounds += 1;
      _totalRoundTimeMs += elapsed;
      _feedback = 'SEQUENCE CLEAR';
      _progress = 0;
    });

    unawaited(ReactAudio.play(ReactSoundCue.success));
    Timer(const Duration(milliseconds: 260), _startRound);
  }

  void _loseLife(String reason) {
    if (!_acceptingInput || _gameOver) return;

    _timer?.cancel();
    _clock.stop();
    final livesAfter = _lives - 1;

    setState(() {
      _acceptingInput = false;
      _lives = livesAfter;
      _feedback = reason;
      _progress = 0;
      if (livesAfter <= 0) _gameOver = true;
    });

    unawaited(ReactAudio.play(ReactSoundCue.miss));

    if (livesAfter > 0) {
      Timer(const Duration(milliseconds: 520), _startRound);
    }
  }

  void _setPaused(bool value) {
    if (_gameOver || _paused == value) return;

    if (value) {
      final remaining = max(1, _remainingMs);
      _clock.stop();
      _timer?.cancel();
      setState(() {
        _paused = true;
        _acceptingInput = false;
        _elapsedBeforeArmMs = _roundDurationMs - remaining;
      });
      return;
    }

    setState(() {
      _paused = false;
      _acceptingInput = true;
    });
    _armTimer(_roundDurationMs - _elapsedBeforeArmMs);
  }

  void _restart() {
    _timer?.cancel();
    _clock
      ..stop()
      ..reset();

    setState(() {
      _score = 0;
      _lives = 3;
      _nextIndex = 0;
      _totalRoundTimeMs = 0;
      _completedRounds = 0;
      _gameOver = false;
      _paused = false;
      _feedback = null;
      _progress = 1;
    });

    _startRound();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_paused,
      child: Scaffold(
        backgroundColor: ReactColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final arenaSize = min(
                constraints.maxWidth - 28,
                constraints.maxHeight * .58,
              ).clamp(300.0, 430.0).toDouble();

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
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: _SequenceArena(
                              size: arenaSize,
                              round: _round,
                              nextIndex: _nextIndex,
                              progress: _progress,
                              remainingSeconds: _remainingMs / 1000,
                              enabled: _acceptingInput,
                              onDotTap: _tapDot,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 38,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _feedback == null ? 0 : 1,
                              duration: const Duration(milliseconds: 100),
                              child: Text(
                                _feedback ?? '',
                                style: TextStyle(
                                  color: _feedback == 'SEQUENCE CLEAR' ||
                                          _feedback == 'GOOD'
                                      ? ReactColors.lime
                                      : ReactColors.coral,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _BottomBar(
                          score: _score,
                          averageSeconds: _averageSeconds,
                          dotCount: _dotCount,
                        ),
                      ],
                    ),
                  ),
                  if (_paused)
                    _PauseOverlay(
                      onResume: () => _setPaused(false),
                      onQuit: () => Navigator.of(context).pop(),
                    ),
                  if (_gameOver)
                    _GameOverOverlay(
                      score: _score,
                      onReplay: _restart,
                      onQuit: () => Navigator.of(context).pop(),
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
    return Row(
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
}

class _Hud extends StatelessWidget {
  const _Hud({required this.score, required this.lives});

  final int score;
  final int lives;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                fontSize: 14,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: i < lives
                          ? ReactColors.coral
                          : ReactColors.textSecondary.withValues(alpha: .18),
                    ),
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
  Widget build(BuildContext context) {
    return Container(
      height: 78,
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
}

class _SequenceArena extends StatelessWidget {
  const _SequenceArena({
    required this.size,
    required this.round,
    required this.nextIndex,
    required this.progress,
    required this.remainingSeconds,
    required this.enabled,
    required this.onDotTap,
  });

  final double size;
  final DotSequenceRound round;
  final int nextIndex;
  final double progress;
  final double remainingSeconds;
  final bool enabled;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    final centre = size / 2;
    final placementRadius = size * .39;
    final dotSize = (size * .16).clamp(50.0, 66.0).toDouble();

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ArenaPainter(progress: progress),
            ),
          ),
          Positioned(
            top: 2,
            left: centre - 39,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF07111D),
                border: Border.all(color: const Color(0xFF315D86), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    remainingSeconds.clamp(0, 9.99).toStringAsFixed(2),
                    style: TextStyle(
                      color: progress < .22
                          ? ReactColors.coral
                          : ReactColors.electricBlueBright,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'SEC',
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 8,
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
                const SizedBox(height: 6),
                const Text(
                  'DOT SEQUENCE',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
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
              left: centre + round.positions[index].dx * placementRadius - dotSize / 2,
              top: centre + round.positions[index].dy * placementRadius - dotSize / 2 + size * .08,
              child: _SequenceDot(
                number: index + 1,
                size: dotSize,
                active: index == nextIndex,
                completed: index < nextIndex,
                enabled: enabled,
                onTap: () => onDotTap(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _SequenceDot extends StatelessWidget {
  const _SequenceDot({
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
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? ReactColors.lime.withValues(alpha: .08)
                : const Color(0xFF06101D),
            border: Border.all(color: accent, width: active ? 2.6 : 1.6),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: ReactColors.electricBlueBright.withValues(alpha: .46),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: completed
              ? const Icon(Icons.check_rounded, color: ReactColors.lime, size: 25)
              : Text(
                  '$number',
                  style: TextStyle(
                    color: accent,
                    fontSize: size * .42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  const _ArenaPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final innerRadius = size.width * .43;
    final outerRadius = size.width * .475;

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF155486);
    canvas.drawCircle(centre, innerRadius, inner);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..color = const Color(0xFF102A45);
    canvas.drawCircle(centre, outerRadius, track);

    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 11
      ..color = progress < .22
          ? ReactColors.coral
          : ReactColors.electricBlueBright;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: outerRadius),
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
  const _BottomBar({
    required this.score,
    required this.averageSeconds,
    required this.dotCount,
  });

  final int score;
  final double averageSeconds;
  final int dotCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
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
            size: 22,
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
          _MiniMetric(label: 'SCORE', value: '$score'),
          const SizedBox(width: 18),
          _MiniMetric(label: 'DOTS', value: '$dotCount'),
          const SizedBox(width: 18),
          _MiniMetric(
            label: 'AVG',
            value: averageSeconds == 0 ? '--' : '${averageSeconds.toStringAsFixed(2)}s',
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onQuit});

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      icon: Icons.pause_circle_outline_rounded,
      title: 'SEQUENCE PAUSED',
      subtitle: 'THE CURRENT ROUND IS FROZEN',
      primaryLabel: 'RESUME',
      onPrimary: onResume,
      secondaryLabel: 'QUIT RUN',
      onSecondary: onQuit,
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.onReplay,
    required this.onQuit,
  });

  final int score;
  final VoidCallback onReplay;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      icon: Icons.blur_circular_rounded,
      title: 'RUN OVER',
      subtitle: 'SEQUENCES CLEARED  $score',
      primaryLabel: 'PLAY AGAIN',
      onPrimary: onReplay,
      secondaryLabel: 'BACK TO MODES',
      onSecondary: onQuit,
    );
  }
}

class _OverlayShell extends StatelessWidget {
  const _OverlayShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
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
              Icon(icon, color: ReactColors.electricBlueBright, size: 50),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
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
                  letterSpacing: .9,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPrimary,
                  child: Text(primaryLabel),
                ),
              ),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
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
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackdropPainter());
  }
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
