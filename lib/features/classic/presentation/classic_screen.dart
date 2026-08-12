import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../results/presentation/results_screen.dart';

enum ClassicCommand {
  tap,
  doubleTap,
  hold,
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  pinch,
  spread,
  freeze,
}

extension ClassicCommandUi on ClassicCommand {
  String get title => switch (this) {
        ClassicCommand.tap => 'PRESS IT',
        ClassicCommand.doubleTap => 'DOUBLE TAP',
        ClassicCommand.hold => 'HOLD IT',
        ClassicCommand.swipeLeft => 'SWIPE LEFT',
        ClassicCommand.swipeRight => 'SWIPE RIGHT',
        ClassicCommand.swipeUp => 'SWIPE UP',
        ClassicCommand.swipeDown => 'SWIPE DOWN',
        ClassicCommand.pinch => 'PINCH IT',
        ClassicCommand.spread => 'SPREAD IT',
        ClassicCommand.freeze => 'FREEZE',
      };

  String get hint => switch (this) {
        ClassicCommand.tap => 'TAP ONCE',
        ClassicCommand.doubleTap => 'TAP TWICE QUICKLY',
        ClassicCommand.hold => 'PRESS AND HOLD',
        ClassicCommand.swipeLeft => 'SWIPE TO THE LEFT',
        ClassicCommand.swipeRight => 'SWIPE TO THE RIGHT',
        ClassicCommand.swipeUp => 'SWIPE UPWARD',
        ClassicCommand.swipeDown => 'SWIPE DOWNWARD',
        ClassicCommand.pinch => 'MOVE TWO FINGERS TOGETHER',
        ClassicCommand.spread => 'MOVE TWO FINGERS APART',
        ClassicCommand.freeze => 'DO NOTHING',
      };

  IconData get icon => switch (this) {
        ClassicCommand.tap => Icons.touch_app_rounded,
        ClassicCommand.doubleTap => Icons.ads_click_rounded,
        ClassicCommand.hold => Icons.pan_tool_alt_rounded,
        ClassicCommand.swipeLeft => Icons.arrow_back_rounded,
        ClassicCommand.swipeRight => Icons.arrow_forward_rounded,
        ClassicCommand.swipeUp => Icons.arrow_upward_rounded,
        ClassicCommand.swipeDown => Icons.arrow_downward_rounded,
        ClassicCommand.pinch => Icons.close_fullscreen_rounded,
        ClassicCommand.spread => Icons.open_in_full_rounded,
        ClassicCommand.freeze => Icons.ac_unit_rounded,
      };
}

class ClassicScreen extends StatefulWidget {
  const ClassicScreen({super.key});

  @override
  State<ClassicScreen> createState() => _ClassicScreenState();
}

class _ClassicScreenState extends State<ClassicScreen> {
  static const _commandDuration = Duration(milliseconds: 2200);
  static const _tickDuration = Duration(milliseconds: 40);
  static const _minimumSwipeDistance = 48.0;
  static const _pinchThreshold = 0.72;
  static const _spreadThreshold = 1.28;
  static const _placeholderBestScore = 12850;

  late final ReactGame _game;
  final Random _random = Random();

  Timer? _timer;
  Timer? _nextCommandTimer;
  ClassicCommand _command = ClassicCommand.tap;
  DateTime _commandStartedAt = DateTime.now();
  double _timeRemaining = 1;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _reactions = 0;
  int _totalResponseMs = 0;
  bool _acceptingInput = true;
  bool _finished = false;
  String? _feedback;
  int? _feedbackPoints;

  Offset _dragDelta = Offset.zero;
  bool _multiTouchSeen = false;
  bool _scaleResolved = false;

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

    final next =
        ClassicCommand.values[_random.nextInt(ClassicCommand.values.length)];

    if (!mounted) return;
    setState(() {
      _command = next;
      _commandStartedAt = DateTime.now();
      _timeRemaining = 1;
      _acceptingInput = true;
      _feedback = null;
      _feedbackPoints = null;
      _dragDelta = Offset.zero;
      _multiTouchSeen = false;
      _scaleResolved = false;
    });

    _timer = Timer.periodic(_tickDuration, (_) {
      if (!mounted || _finished || !_acceptingInput) return;

      final elapsed =
          DateTime.now().difference(_commandStartedAt).inMilliseconds;
      final progress = 1 - (elapsed / _commandDuration.inMilliseconds);

      if (progress <= 0) {
        if (_command == ClassicCommand.freeze) {
          _completeCommand(
            responseMs: _commandDuration.inMilliseconds,
            feedbackOverride: 'FROZEN',
          );
        } else {
          _failRun();
        }
        return;
      }

      setState(() => _timeRemaining = progress.clamp(0.0, 1.0));
    });
  }

  void _handleGesture(ClassicCommand performed) {
    if (!_acceptingInput || _finished) return;
    if (performed != _command) {
      _failRun();
      return;
    }
    _completeCommand();
  }

  void _completeCommand({int? responseMs, String? feedbackOverride}) {
    if (!_acceptingInput || _finished) return;
    _timer?.cancel();

    final actualResponseMs = responseMs ??
        DateTime.now().difference(_commandStartedAt).inMilliseconds;
    final newCombo = _combo + 1;

    setState(() {
      _acceptingInput = false;
      _score += 1;
      _combo = newCombo;
      _bestCombo = max(_bestCombo, newCombo);
      _reactions += 1;
      _totalResponseMs += actualResponseMs;
      _feedbackPoints = 1;
      _feedback = feedbackOverride ??
          (actualResponseMs <= 750
              ? 'PERFECT'
              : actualResponseMs <= 1400
                  ? 'GREAT'
                  : 'GOOD');
    });

    _nextCommandTimer = Timer(
      const Duration(milliseconds: 520),
      _startCommand,
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (!_acceptingInput || _finished) return;
    _dragDelta = Offset.zero;
    _multiTouchSeen = details.pointerCount >= 2;
    _scaleResolved = false;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_acceptingInput || _finished || _scaleResolved) return;

    if (details.pointerCount >= 2) {
      _multiTouchSeen = true;
      if (details.scale <= _pinchThreshold) {
        _scaleResolved = true;
        _handleGesture(ClassicCommand.pinch);
      } else if (details.scale >= _spreadThreshold) {
        _scaleResolved = true;
        _handleGesture(ClassicCommand.spread);
      }
      return;
    }

    if (!_multiTouchSeen) {
      _dragDelta += details.focalPointDelta;
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_acceptingInput || _finished || _multiTouchSeen || _scaleResolved) {
      return;
    }

    final dx = _dragDelta.dx;
    final dy = _dragDelta.dy;
    final horizontal = dx.abs() >= dy.abs();
    final primaryDistance = horizontal ? dx.abs() : dy.abs();
    if (primaryDistance < _minimumSwipeDistance) return;

    final performed = horizontal
        ? (dx < 0 ? ClassicCommand.swipeLeft : ClassicCommand.swipeRight)
        : (dy < 0 ? ClassicCommand.swipeUp : ClassicCommand.swipeDown);
    _handleGesture(performed);
  }

  void _failRun() {
    if (_finished) return;
    _finished = true;
    _acceptingInput = false;
    _timer?.cancel();
    _nextCommandTimer?.cancel();
    _openResults();
  }

  void _openResults() {
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
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(height: compact ? 10 : 16),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _handleGesture(ClassicCommand.tap),
                            onDoubleTap: () =>
                                _handleGesture(ClassicCommand.doubleTap),
                            onLongPress: () =>
                                _handleGesture(ClassicCommand.hold),
                            onScaleStart: _handleScaleStart,
                            onScaleUpdate: _handleScaleUpdate,
                            onScaleEnd: _handleScaleEnd,
                            child: _CommandArena(
                              size: arenaSize,
                              command: _command,
                              progress: _timeRemaining,
                            ),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 160),
                        child: _feedback == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: _SuccessFeedback(
                                  key: ValueKey('$_feedback-$_reactions'),
                                  feedback: _feedback!,
                                  points: _feedbackPoints!,
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
    required this.onClose,
  });

  final int score;
  final int combo;
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
            const _ReactWordmark(),
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
            const Expanded(
              child: _HudCard(
                label: 'MODE',
                value: 'CLASSIC',
                color: ReactColors.electricBlueBright,
                compactValue: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReactWordmark extends StatelessWidget {
  const _ReactWordmark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RE',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        Icon(
          Icons.change_history_rounded,
          color: ReactColors.electricBlueBright,
          size: 25,
        ),
        Text(
          'CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
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
                letterSpacing: compactValue ? .8 : 0,
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
  });

  final double size;
  final ClassicCommand command;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final seconds =
        (_ClassicScreenState._commandDuration.inMilliseconds * progress / 1000)
            .clamp(0, 9.9);

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
              border: Border.all(color: const Color(0xFF153B65), width: 1.5),
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
                    letterSpacing: .3,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 18),
                _CommandGraphic(command: command),
                const SizedBox(height: 15),
                Text(
                  command.hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
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
                border: Border.all(color: const Color(0xFF31577E), width: 2),
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
                      letterSpacing: 1.2,
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

class _CommandGraphic extends StatelessWidget {
  const _CommandGraphic({required this.command});

  final ClassicCommand command;

  @override
  Widget build(BuildContext context) {
    if (command == ClassicCommand.tap) {
      return Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF27D9FF), Color(0xFF126CFF)],
          ),
          border: Border.all(color: const Color(0xFFB5F6FF), width: 2.5),
        ),
      );
    }

    return SizedBox(
      width: 120,
      height: 110,
      child: Icon(
        command.icon,
        color: ReactColors.electricBlueBright,
        size: command == ClassicCommand.pinch ||
                command == ClassicCommand.spread
            ? 88
            : 96,
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
    final segments = <Color>[
      ReactColors.electricBlueBright,
      ReactColors.lime,
      ReactColors.coral,
    ];

    var start = pi * .72;
    for (var i = 0; i < 3; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = segments[i].withValues(alpha: .72);
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
    final timerTrack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF10243D);
    canvas.drawCircle(center, timerRadius, timerTrack);

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

    final tickPaint = Paint()..strokeWidth = 1.4;
    for (var i = 0; i < 64; i++) {
      final angle = i * pi * 2 / 64;
      final c = i < 22
          ? ReactColors.electricBlueBright
          : i < 43
              ? ReactColors.lime
              : ReactColors.coral;
      tickPaint.color = c.withValues(alpha: .5);
      final p1 = center + Offset(cos(angle), sin(angle)) * (radius + 30);
      final p2 = center + Offset(cos(angle), sin(angle)) * (radius + 34);
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SuccessFeedback extends StatelessWidget {
  const _SuccessFeedback({
    required this.feedback,
    required this.points,
    super.key,
  });

  final String feedback;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+$points',
          style: const TextStyle(
            color: ReactColors.lime,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          feedback,
          style: const TextStyle(
            color: Color(0xFF2DE7F1),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.3,
          ),
        ),
      ],
    );
  }
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
            value: _formatScore(bestScore),
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

  static String _formatScore(int value) {
    final text = value.toString();
    if (text.length <= 3) return text;
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFF1B304A),
    );
  }
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
                color: highlight ? ReactColors.lime : ReactColors.textPrimary,
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
