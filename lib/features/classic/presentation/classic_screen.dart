import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/presentation/react_gesture_surface.dart';
import '../../modes/domain/mode_timing_rules.dart';
import '../../results/presentation/results_screen.dart';

class ClassicScreen extends StatefulWidget {
  const ClassicScreen({super.key});

  @override
  State<ClassicScreen> createState() => _ClassicScreenState();
}

class _ClassicScreenState extends State<ClassicScreen> {
  static const _tickDuration = Duration(milliseconds: 40);
  static const _placeholderBestScore = 42;

  late final ReactGame _game;
  final Random _random = Random();

  Timer? _timer;
  Timer? _nextCommandTimer;
  ReactCommand _command = ReactCommand.tap;
  DateTime _commandStartedAt = DateTime.now();
  double _timeRemaining = 1;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _reactions = 0;
  int _totalResponseMs = 0;
  int _lives = 3;
  bool _acceptingInput = true;
  bool _finished = false;
  String? _feedback;

  int get _commandDurationMs =>
      ReactModeTiming.classic.commandDurationMsForScore(_score);

  double get _averageTimeSeconds =>
      _reactions == 0 ? 0 : (_totalResponseMs / _reactions) / 1000;

  @override
  void initState() {
    super.initState();
    _game = ReactGame();
    _startCommand();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nextCommandTimer?.cancel();
    super.dispose();
  }

  void _startCommand() {
    _timer?.cancel();
    _nextCommandTimer?.cancel();
    if (!mounted || _finished) return;

    final next = ReactCommand.values[_random.nextInt(ReactCommand.values.length)];

    setState(() {
      _command = next;
      _commandStartedAt = DateTime.now();
      _timeRemaining = 1;
      _acceptingInput = true;
      _feedback = null;
    });

    _timer = Timer.periodic(_tickDuration, (_) {
      if (!mounted || _finished || !_acceptingInput) return;

      final elapsed =
          DateTime.now().difference(_commandStartedAt).inMilliseconds;
      final progress = 1 - (elapsed / _commandDurationMs);

      if (progress <= 0) {
        _loseLife();
        return;
      }

      setState(() => _timeRemaining = progress.clamp(0.0, 1.0));
    });
  }

  void _handleGesture(ReactCommand performed) {
    if (!_acceptingInput || _finished) return;
    if (performed != _command) {
      _loseLife();
      return;
    }
    _completeCommand();
  }

  void _completeCommand() {
    if (!_acceptingInput || _finished) return;
    _timer?.cancel();

    final actualResponseMs =
        DateTime.now().difference(_commandStartedAt).inMilliseconds;
    final newCombo = _combo + 1;

    setState(() {
      _acceptingInput = false;
      _score += 1;
      _combo = newCombo;
      _bestCombo = max(_bestCombo, newCombo);
      _reactions += 1;
      _totalResponseMs += actualResponseMs;
      _feedback = actualResponseMs <= 750
          ? 'PERFECT'
          : actualResponseMs <= 1400
              ? 'GREAT'
              : 'GOOD';
    });

    _nextCommandTimer = Timer(
      Duration(
        milliseconds:
            ReactModeTiming.classic.successDelayMsForScore(_score),
      ),
      _startCommand,
    );
  }

  void _loseLife() {
    if (!_acceptingInput || _finished) return;
    _timer?.cancel();

    final remaining = _lives - 1;
    setState(() {
      _acceptingInput = false;
      _lives = remaining;
      _combo = 0;
      _feedback = 'MISS';
    });

    if (remaining <= 0) {
      _nextCommandTimer = Timer(
        const Duration(milliseconds: 420),
        _finishRun,
      );
      return;
    }

    _nextCommandTimer = Timer(
      Duration(milliseconds: ReactModeTiming.classic.missDelayMs),
      _startCommand,
    );
  }

  void _finishRun() {
    if (_finished || !mounted) return;
    _finished = true;
    _acceptingInput = false;
    _timer?.cancel();
    _nextCommandTimer?.cancel();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          score: _score,
          reactions: _reactions,
          bestCombo: _bestCombo,
          averageTimeSeconds: _averageTimeSeconds,
          failedCommand: _command.title,
          failedCommandIcon: _command.icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 760;
                final arenaSize =
                    constraints.maxWidth.clamp(320.0, 390.0).toDouble();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    children: [
                      _GameplayHeader(
                        score: _score,
                        combo: _combo,
                        lives: _lives,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(height: compact ? 10 : 16),
                      Expanded(
                        child: Center(
                          child: ReactGestureSurface(
                            enabled: _acceptingInput && !_finished,
                            onCommand: _handleGesture,
                            child: _CommandArena(
                              size: arenaSize,
                              command: _command,
                              progress: _timeRemaining,
                              commandDurationMs: _commandDurationMs,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _feedback == null ? 0 : 1,
                            child: Text(
                              _feedback == 'MISS'
                                  ? 'MISS  •  $_lives LIVES LEFT'
                                  : '+1  ${_feedback ?? ''}',
                              style: TextStyle(
                                color: _feedback == 'MISS'
                                    ? ReactColors.coral
                                    : ReactColors.electricBlueBright,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _PacePanel(
                        score: _score,
                        bestScore: max(_placeholderBestScore, _score),
                        averageTimeSeconds: _averageTimeSeconds,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameplayHeader extends StatelessWidget {
  const _GameplayHeader({
    required this.score,
    required this.combo,
    required this.lives,
    required this.onClose,
  });

  final int score;
  final int combo;
  final int lives;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF07101E),
                foregroundColor: ReactColors.textPrimary,
                side: const BorderSide(color: Color(0xFF20456E)),
              ),
              icon: const Icon(Icons.pause_rounded),
            ),
            const Spacer(),
            const Text(
              'RE△CT',
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 46),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HudCard(
                label: 'SCORE',
                value: '$score',
                color: ReactColors.lime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HudCard(
                label: 'COMBO',
                value: 'x$combo',
                color: ReactColors.purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HudCard(
                label: 'LIVES',
                value: List.filled(lives, '♥').join(' '),
                color: ReactColors.coral,
                compactValue: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HudCard extends StatelessWidget {
  const _HudCard({
    required this.label,
    required this.value,
    required this.color,
    this.compactValue = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF243A57)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: compactValue ? 15 : 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandArena extends StatelessWidget {
  const _CommandArena({
    required this.size,
    required this.command,
    required this.progress,
    required this.commandDurationMs,
  });

  final double size;
  final ReactCommand command;
  final double progress;
  final int commandDurationMs;

  @override
  Widget build(BuildContext context) {
    final seconds = (commandDurationMs * progress / 1000).clamp(0, 9.9);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _SegmentedRingPainter(progress: progress),
          ),
          Container(
            width: size * .69,
            height: size * .69,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(
                color: const Color(0xFF153B65),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  command.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 18),
                Icon(
                  command.icon,
                  color: ReactColors.electricBlueBright,
                  size: command == ReactCommand.pinch ||
                          command == ReactCommand.spread
                      ? 88
                      : 96,
                ),
                const SizedBox(height: 15),
                Text(
                  command.hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: size * .015,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF07111D),
                border: Border.all(
                  color: const Color(0xFF31577E),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    seconds.toStringAsFixed(2),
                    style: TextStyle(
                      color: progress < .2
                          ? ReactColors.coral
                          : ReactColors.electricBlueBright,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  const _SegmentedRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .44;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF122038);
    canvas.drawCircle(center, radius, base);

    const gap = .12;
    const segmentSweep = (pi * 2 - gap * 3) / 3;
    final colors = <Color>[
      ReactColors.electricBlueBright,
      ReactColors.lime,
      ReactColors.coral,
    ];

    var start = pi * .72;
    for (final color in colors) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: .72);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segmentSweep,
        false,
        paint,
      );
      start += segmentSweep + gap;
    }

    final timerRadius = radius + 14;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF10243D);
    canvas.drawCircle(center, timerRadius, track);

    final timerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = progress < .18
          ? ReactColors.coral
          : ReactColors.electricBlueBright;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: timerRadius),
      -pi / 2,
      pi * 2 * progress,
      false,
      timerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PacePanel extends StatelessWidget {
  const _PacePanel({
    required this.score,
    required this.bestScore,
    required this.averageTimeSeconds,
  });

  final int score;
  final int bestScore;
  final double averageTimeSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF213A57)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: ReactColors.electricBlueBright,
            size: 21,
          ),
          const SizedBox(width: 8),
          const Text(
            'CLASSIC',
            style: TextStyle(
              color: ReactColors.electricBlueBright,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _PaceMetric(label: 'SCORE', value: '$score'),
          const _MetricDivider(),
          _PaceMetric(
            label: 'YOUR BEST RESULT',
            value: '$bestScore',
            highlight: true,
          ),
          const _MetricDivider(),
          _PaceMetric(
            label: 'AVG TIME',
            value: averageTimeSeconds == 0
                ? '--'
                : '${averageTimeSeconds.toStringAsFixed(2)}s',
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: const Color(0xFF1B304A),
      );
}

class _PaceMetric extends StatelessWidget {
  const _PaceMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 6.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: highlight
                    ? ReactColors.lime
                    : ReactColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
