import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../results/presentation/results_screen.dart';
import '../domain/mode_timing_rules.dart';

enum ReactRunMode { blitz, endless, daily, passIt }

extension ReactRunModeUi on ReactRunMode {
  String get label => switch (this) {
        ReactRunMode.blitz => 'BLITZ',
        ReactRunMode.endless => 'ENDLESS',
        ReactRunMode.daily => 'DAILY',
        ReactRunMode.passIt => 'PASS IT',
      };

  Color get color => switch (this) {
        ReactRunMode.blitz => ReactColors.coral,
        ReactRunMode.endless => ReactColors.lime,
        ReactRunMode.daily => ReactColors.electricBlueBright,
        ReactRunMode.passIt => ReactColors.purple,
      };

  ModeTimingRules get timing => switch (this) {
        ReactRunMode.blitz => ReactModeTiming.blitz,
        ReactRunMode.endless => ReactModeTiming.endless,
        ReactRunMode.daily => ReactModeTiming.daily,
        ReactRunMode.passIt => ReactModeTiming.passIt,
      };
}

class ModeRunScreen extends StatefulWidget {
  const ModeRunScreen({required this.mode, super.key});

  final ReactRunMode mode;

  @override
  State<ModeRunScreen> createState() => _ModeRunScreenState();
}

class _ModeRunScreenState extends State<ModeRunScreen> {
  static const _tickDuration = Duration(milliseconds: 40);
  static const _minimumSwipeDistance = 48.0;
  static const _pinchThreshold = 0.72;
  static const _spreadThreshold = 1.28;
  static const _dailyTarget = 20;

  late final ReactGame _game;
  late final Random _random;

  Timer? _commandTimer;
  Timer? _nextCommandTimer;
  Timer? _runTimer;

  ClassicCommand _command = ClassicCommand.tap;
  DateTime _commandStartedAt = DateTime.now();
  double _timeRemaining = 1;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _reactions = 0;
  int _totalResponseMs = 0;
  int _runMsRemaining = 0;
  int _misses = 0;
  bool _acceptingInput = true;
  bool _finished = false;
  String? _feedback;

  Offset _dragDelta = Offset.zero;
  bool _multiTouchSeen = false;
  bool _scaleResolved = false;

  int _currentPlayer = 0;
  final List<int> _playerLives = [3, 3, 3];

  ModeTimingRules get _timing => widget.mode.timing;
  int get _commandDurationMs => _timing.commandDurationMsForScore(_score);

  double get _averageTimeSeconds =>
      _reactions == 0 ? 0 : (_totalResponseMs / _reactions) / 1000;

  int get _alivePlayers => _playerLives.where((lives) => lives > 0).length;

  @override
  void initState() {
    super.initState();
    _game = ReactGame();

    final now = DateTime.now();
    final dailySeed = now.year * 10000 + now.month * 100 + now.day;
    _random = widget.mode == ReactRunMode.daily ? Random(dailySeed) : Random();

    _runMsRemaining = _timing.runDurationMs ?? 0;
    if (_timing.runDurationMs != null) {
      _startRunClock();
    }
    _startCommand();
  }

  @override
  void dispose() {
    _commandTimer?.cancel();
    _nextCommandTimer?.cancel();
    _runTimer?.cancel();
    super.dispose();
  }

  void _startRunClock() {
    _runTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _finished) return;
      final next = max(0, _runMsRemaining - 100);
      setState(() => _runMsRemaining = next);
      if (next <= 0) {
        _finishRun(
          failedCommand: 'TIME UP',
          failedIcon: Icons.timer_rounded,
        );
      }
    });
  }

  void _startCommand() {
    _commandTimer?.cancel();
    _nextCommandTimer?.cancel();
    if (_finished || !mounted) return;

    if (widget.mode == ReactRunMode.daily && _score >= _dailyTarget) {
      _finishRun(
        failedCommand: 'DAILY COMPLETE',
        failedIcon: Icons.emoji_events_rounded,
      );
      return;
    }

    if (widget.mode == ReactRunMode.passIt && _alivePlayers <= 1) {
      final winner = _playerLives.indexWhere((lives) => lives > 0) + 1;
      _finishRun(
        failedCommand: 'PLAYER $winner WINS',
        failedIcon: Icons.emoji_events_rounded,
      );
      return;
    }

    final next =
        ClassicCommand.values[_random.nextInt(ClassicCommand.values.length)];

    setState(() {
      _command = next;
      _commandStartedAt = DateTime.now();
      _timeRemaining = 1;
      _acceptingInput = true;
      _feedback = null;
      _dragDelta = Offset.zero;
      _multiTouchSeen = false;
      _scaleResolved = false;
    });

    _commandTimer = Timer.periodic(_tickDuration, (_) {
      if (!mounted || _finished || !_acceptingInput) return;

      final elapsed =
          DateTime.now().difference(_commandStartedAt).inMilliseconds;
      final progress = 1 - (elapsed / _commandDurationMs);

      if (progress <= 0) {
        if (_command == ClassicCommand.freeze) {
          _completeCommand(
            responseMs: _commandDurationMs,
            feedbackOverride: 'FROZEN',
          );
        } else {
          _handleMiss();
        }
        return;
      }

      setState(() => _timeRemaining = progress.clamp(0.0, 1.0));
    });
  }

  void _handleGesture(ClassicCommand performed) {
    if (!_acceptingInput || _finished) return;
    if (performed != _command) {
      _handleMiss();
      return;
    }
    _completeCommand();
  }

  void _completeCommand({int? responseMs, String? feedbackOverride}) {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();

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
      _feedback = feedbackOverride ??
          (actualResponseMs <= 650
              ? 'PERFECT'
              : actualResponseMs <= 1150
                  ? 'GREAT'
                  : 'GOOD');
    });

    if (widget.mode == ReactRunMode.passIt) {
      _advancePlayer();
    }

    _nextCommandTimer = Timer(
      Duration(milliseconds: _timing.successDelayMs),
      _startCommand,
    );
  }

  void _handleMiss() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();

    switch (widget.mode) {
      case ReactRunMode.blitz:
        final penalized = max(0, _runMsRemaining - _timing.missTimePenaltyMs);
        setState(() {
          _acceptingInput = false;
          _combo = 0;
          _misses += 1;
          _runMsRemaining = penalized;
          _feedback = 'MISS  -${_timing.missTimePenaltyMs ~/ 1000} SEC';
        });
        if (penalized <= 0) {
          _finishRun(
            failedCommand: 'TIME UP',
            failedIcon: Icons.timer_rounded,
          );
          return;
        }
        _nextCommandTimer = Timer(
          Duration(milliseconds: _timing.missDelayMs),
          _startCommand,
        );
        return;

      case ReactRunMode.endless:
        _misses += 1;
        _finishRun();
        return;

      case ReactRunMode.daily:
        _misses += 1;
        _finishRun();
        return;

      case ReactRunMode.passIt:
        setState(() {
          _acceptingInput = false;
          _combo = 0;
          _misses += 1;
          _playerLives[_currentPlayer] =
              max(0, _playerLives[_currentPlayer] - 1);
          _feedback = 'MISS  •  LIFE LOST';
        });
        _advancePlayer();
        _nextCommandTimer = Timer(
          Duration(milliseconds: _timing.missDelayMs),
          _startCommand,
        );
        return;
    }
  }

  void _advancePlayer() {
    if (widget.mode != ReactRunMode.passIt || _alivePlayers <= 1) return;

    var candidate = _currentPlayer;
    do {
      candidate = (candidate + 1) % _playerLives.length;
    } while (_playerLives[candidate] <= 0);
    _currentPlayer = candidate;
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
    final distance = horizontal ? dx.abs() : dy.abs();
    if (distance < _minimumSwipeDistance) return;

    final performed = horizontal
        ? (dx < 0 ? ClassicCommand.swipeLeft : ClassicCommand.swipeRight)
        : (dy < 0 ? ClassicCommand.swipeUp : ClassicCommand.swipeDown);
    _handleGesture(performed);
  }

  void _finishRun({String? failedCommand, IconData? failedIcon}) {
    if (_finished || !mounted) return;

    _finished = true;
    _acceptingInput = false;
    _commandTimer?.cancel();
    _nextCommandTimer?.cancel();
    _runTimer?.cancel();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          score: _score,
          reactions: _reactions,
          bestCombo: _bestCombo,
          averageTimeSeconds: _averageTimeSeconds,
          failedCommand: failedCommand ?? _command.title,
          failedCommandIcon: failedIcon ?? _command.icon,
        ),
      ),
    );
  }

  String get _statusLabel => switch (widget.mode) {
        ReactRunMode.blitz => 'TIME',
        ReactRunMode.endless => 'PACE',
        ReactRunMode.daily => 'STEP',
        ReactRunMode.passIt => 'TURN',
      };

  String get _statusValue => switch (widget.mode) {
        ReactRunMode.blitz => '${(_runMsRemaining / 1000).ceil()}s',
        ReactRunMode.endless => '${(_commandDurationMs / 1000).toStringAsFixed(1)}s',
        ReactRunMode.daily => '$_score/$_dailyTarget',
        ReactRunMode.passIt =>
          'P${_currentPlayer + 1} ${List.filled(_playerLives[_currentPlayer], '♥').join()}',
      };

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
                      _RunHeader(
                        mode: widget.mode,
                        score: _score,
                        combo: _combo,
                        statusLabel: _statusLabel,
                        statusValue: _statusValue,
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
                            child: _RunArena(
                              size: arenaSize,
                              command: _command,
                              progress: _timeRemaining,
                              commandDurationMs: _commandDurationMs,
                              accent: widget.mode.color,
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
                              _feedback ?? 'READY',
                              style: TextStyle(
                                color: _feedback?.startsWith('MISS') == true
                                    ? ReactColors.coral
                                    : ReactColors.electricBlueBright,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _BottomPanel(
                        mode: widget.mode,
                        score: _score,
                        misses: _misses,
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

class _RunHeader extends StatelessWidget {
  const _RunHeader({
    required this.mode,
    required this.score,
    required this.combo,
    required this.statusLabel,
    required this.statusValue,
    required this.onClose,
  });

  final ReactRunMode mode;
  final int score;
  final int combo;
  final String statusLabel;
  final String statusValue;
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
            Expanded(child: _HudCard(label: 'SCORE', value: '$score', color: ReactColors.lime)),
            const SizedBox(width: 10),
            Expanded(child: _HudCard(label: 'COMBO', value: 'x$combo', color: ReactColors.purple)),
            const SizedBox(width: 10),
            Expanded(
              child: _HudCard(
                label: statusLabel,
                value: statusValue,
                color: mode.color,
                compact: true,
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
    this.compact = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool compact;

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
                fontSize: compact ? 15 : 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunArena extends StatelessWidget {
  const _RunArena({
    required this.size,
    required this.command,
    required this.progress,
    required this.commandDurationMs,
    required this.accent,
  });

  final double size;
  final ClassicCommand command;
  final double progress;
  final int commandDurationMs;
  final Color accent;

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
            painter: _ModeRingPainter(progress: progress, accent: accent),
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
                    height: 1,
                  ),
                ),
                const SizedBox(height: 18),
                Icon(
                  command.icon,
                  color: ReactColors.electricBlueBright,
                  size: command == ClassicCommand.pinch || command == ClassicCommand.spread ? 88 : 96,
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
                border: Border.all(color: const Color(0xFF31577E), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    seconds.toStringAsFixed(2),
                    style: TextStyle(
                      color: progress < .2 ? ReactColors.coral : accent,
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

class _ModeRingPainter extends CustomPainter {
  const _ModeRingPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .44;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = const Color(0xFF122038);
    canvas.drawCircle(center, radius, base);

    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    deco.color = ReactColors.electricBlueBright.withValues(alpha: .7);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), .8, 1.45, false, deco);
    deco.color = ReactColors.lime.withValues(alpha: .7);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.0, 1.25, false, deco);
    deco.color = ReactColors.coral.withValues(alpha: .7);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 4.75, 1.1, false, deco);

    final timerRadius = radius + 14;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color(0xFF10243D);
    canvas.drawCircle(center, timerRadius, track);

    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = progress < .18 ? ReactColors.coral : accent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: timerRadius),
      -pi / 2,
      pi * 2 * progress,
      false,
      timer,
    );
  }

  @override
  bool shouldRepaint(covariant _ModeRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.mode,
    required this.score,
    required this.misses,
    required this.averageTimeSeconds,
  });

  final ReactRunMode mode;
  final int score;
  final int misses;
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
          Icon(Icons.bolt_rounded, color: mode.color, size: 21),
          const SizedBox(width: 8),
          Text(
            mode.label,
            style: TextStyle(
              color: mode.color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _BottomMetric(label: 'SCORE', value: '$score'),
          const _Divider(),
          _BottomMetric(label: 'MISSES', value: '$misses'),
          const _Divider(),
          _BottomMetric(
            label: 'AVG TIME',
            value: averageTimeSeconds == 0 ? '--' : '${averageTimeSeconds.toStringAsFixed(2)}s',
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 9),
        color: const Color(0xFF1B304A),
      );
}

class _BottomMetric extends StatelessWidget {
  const _BottomMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 6.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
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
}
