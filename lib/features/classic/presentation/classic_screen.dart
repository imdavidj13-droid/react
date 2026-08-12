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
        ClassicCommand.tap => 'TAP',
        ClassicCommand.doubleTap => 'DOUBLE\nTAP',
        ClassicCommand.hold => 'HOLD',
        ClassicCommand.swipeLeft => 'SWIPE\nLEFT',
        ClassicCommand.swipeRight => 'SWIPE\nRIGHT',
        ClassicCommand.swipeUp => 'SWIPE\nUP',
        ClassicCommand.swipeDown => 'SWIPE\nDOWN',
        ClassicCommand.pinch => 'PINCH',
        ClassicCommand.spread => 'SPREAD',
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
        ClassicCommand.freeze => Icons.pause_circle_outline_rounded,
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

    // Independent random selection: consecutive duplicates are allowed.
    final next = ClassicCommand.values[
      _random.nextInt(ClassicCommand.values.length),
    ];

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

      final elapsed = DateTime.now().difference(_commandStartedAt).inMilliseconds;
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

      setState(() {
        _timeRemaining = progress.clamp(0.0, 1.0);
      });
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
    final averageTimeSeconds =
        _reactions == 0 ? 0.0 : (_totalResponseMs / _reactions) / 1000;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          score: _score,
          reactions: _reactions,
          bestCombo: _bestCombo,
          averageTimeSeconds: averageTimeSeconds,
          failedCommand: _command.title.replaceAll('\n', ' '),
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

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _RoundControl(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          _HudMetric(
                            label: 'SCORE',
                            value: '$_score',
                            color: ReactColors.lime,
                          ),
                          const SizedBox(width: 22),
                          _HudMetric(
                            label: 'COMBO',
                            value: 'x$_combo',
                            color: ReactColors.purple,
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 24 : 34),
                      const Text(
                        'CLASSIC RUN',
                        style: TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.1,
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 28),
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
                            child: _CommandDisplay(
                              command: _command,
                              progress: _timeRemaining,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 52,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: _feedback == null
                              ? const _InstructionCopy(
                                  key: ValueKey('instruction'),
                                )
                              : _SuccessFeedback(
                                  key: ValueKey('$_feedback-$_reactions'),
                                  feedback: _feedback!,
                                  points: _feedbackPoints!,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _CommandHints(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _timer?.cancel();
                            _nextCommandTimer?.cancel();
                            _openResults();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5E6D88),
                            side: const BorderSide(color: Color(0xFF1A2740)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.flag_outlined, size: 15),
                          label: const Text(
                            'PREVIEW RESULT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
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

class _CommandDisplay extends StatelessWidget {
  const _CommandDisplay({required this.command, required this.progress});

  final ClassicCommand command;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width.clamp(300.0, 360.0).toDouble();
    final seconds =
        (_ClassicScreenState._commandDuration.inMilliseconds * progress / 1000)
            .clamp(0, 9.9);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size - 20,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFF13213A),
              color: progress < .28
                  ? ReactColors.coral
                  : ReactColors.electricBlueBright,
            ),
          ),
          SizedBox.square(
            dimension: size - 52,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFF172033),
              color: ReactColors.electricBlue.withValues(alpha: .55),
            ),
          ),
          Container(
            width: size - 84,
            height: size - 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF070B15),
              border: Border.all(color: const Color(0xFF17345C)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  command.icon,
                  color: ReactColors.electricBlueBright,
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  command.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: .92,
                  ),
                ),
                const SizedBox(height: 11),
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
                const SizedBox(height: 14),
                Text(
                  seconds.toStringAsFixed(1),
                  style: TextStyle(
                    color: progress < .28
                        ? ReactColors.coral
                        : ReactColors.electricBlueBright,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'SECONDS',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCopy extends StatelessWidget {
  const _InstructionCopy({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PERFORM THE COMMAND',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Complete it before the timer ring expires',
          style: TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '+$points',
          style: const TextStyle(
            color: ReactColors.lime,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          feedback,
          style: const TextStyle(
            color: ReactColors.electricBlueBright,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

class _CommandHints extends StatelessWidget {
  const _CommandHints();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HintDot(color: ReactColors.electricBlueBright),
        SizedBox(width: 8),
        Text(
          '10 COMMANDS ACTIVE',
          style: TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(width: 8),
        _HintDot(color: ReactColors.purple),
      ],
    );
  }
}

class _HintDot extends StatelessWidget {
  const _HintDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 8)],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF090E19),
        foregroundColor: ReactColors.textPrimary,
        side: const BorderSide(color: Color(0xFF1B2B46)),
      ),
      icon: Icon(icon),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}
