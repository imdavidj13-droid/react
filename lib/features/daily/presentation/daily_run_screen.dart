import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_gesture_surface.dart';
import '../../modes/domain/mode_timing_rules.dart';
import '../../results/presentation/results_screen.dart';
import '../domain/daily_challenge.dart';

class DailyRunScreen extends StatefulWidget {
  const DailyRunScreen({super.key});

  @override
  State<DailyRunScreen> createState() => _DailyRunScreenState();
}

class _DailyRunScreenState extends State<DailyRunScreen>
    with WidgetsBindingObserver {
  static const int target = 60;
  static const _tick = Duration(milliseconds: 32);

  late final DailyChallenge _challenge;
  late final DailyModifier _modifier;
  late final Random _random;
  late final ReactGame _game;

  Timer? _commandTimer;
  Timer? _nextTimer;
  Timer? _obscureTimer;

  ReactCommand _command = ReactCommand.tap;
  ReactCommand? _previousCommand;
  DateTime _commandStartedAt = DateTime.now();

  int _score = 0;
  int _misses = 0;
  int _totalResponseMs = 0;
  int _surgeRemaining = 0;
  int _pausedRemainingMs = 0;

  double _progress = 1;
  bool _acceptingInput = false;
  bool _finished = false;
  bool _paused = false;
  bool _obscured = false;
  bool _echoNext = false;
  bool _pausedHadCommand = false;
  String? _feedback;

  ModeTimingRules get _timing => ReactModeTiming.daily;

  bool get _isLightsOut => _modifier == DailyModifier.lightsOut;
  bool get _isSurge => _modifier == DailyModifier.surge;
  bool get _isNoClock => _modifier == DailyModifier.noClock;
  bool get _isEcho => _modifier == DailyModifier.echo;
  bool get _isReverse => _modifier == DailyModifier.reverse;
  bool get _isChain => _modifier == DailyModifier.chain;
  bool get _isRedline => _modifier == DailyModifier.redline;

  bool get _surgeCommand => _isSurge && _surgeRemaining > 0;
  bool get _redlineCommand => _isRedline && (_score + 1) % 10 == 0;

  int get _baseCommandMs => _timing.commandDurationMsForScore(_score);

  int get _commandDurationMs {
    var base = _baseCommandMs;
    if (_surgeCommand) base = max(650, (base * .62).round());
    if (_redlineCommand) base = max(600, (base * .55).round());

    final multiplier = switch (_command) {
      ReactCommand.tap => 1.0,
      ReactCommand.doubleTap => 1.10,
      ReactCommand.hold => 1.22,
      ReactCommand.swipeLeft ||
      ReactCommand.swipeRight ||
      ReactCommand.swipeUp ||
      ReactCommand.swipeDown => 1.0,
      ReactCommand.pinch || ReactCommand.spread => 1.18,
    };
    return (base * multiplier).round();
  }

  double get _averageTimeSeconds =>
      _score == 0 ? 0 : (_totalResponseMs / _score) / 1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _challenge = DailyChallenge.today();
    _modifier = ReactSettings.dailyDevOverrideEnabled
        ? DailyModifier.values.firstWhere(
            (value) => value.name == ReactSettings.dailyDevModifier,
            orElse: () => _challenge.modifier,
          )
        : _challenge.modifier;
    _random = Random(_challenge.seed);
    _game = ReactGame()
      ..configure(
        accent: ReactColors.electricBlueBright,
        intensity: .30,
      );
    _startCommand();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_finished && !_paused) {
      _setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commandTimer?.cancel();
    _nextTimer?.cancel();
    _obscureTimer?.cancel();
    super.dispose();
  }

  ReactCommand _nextRandomCommand() {
    final values = ReactCommand.values;
    if (values.length <= 1) return values.first;

    ReactCommand next;
    do {
      next = values[_random.nextInt(values.length)];
    } while (next == _previousCommand && _random.nextBool());
    return next;
  }

  void _startCommand({ReactCommand? forced}) {
    _commandTimer?.cancel();
    _nextTimer?.cancel();
    _obscureTimer?.cancel();
    if (!mounted || _finished || _paused) return;

    if (_score >= target) {
      _finish(ReactRunOutcome.completed);
      return;
    }

    final next = forced ?? _nextRandomCommand();
    _previousCommand = _command;

    setState(() {
      _command = next;
      _progress = 1;
      _obscured = false;
      _feedback = _redlineCommand
          ? 'REDLINE'
          : _surgeCommand
              ? 'SURGE'
              : forced != null && _isEcho
                  ? 'ECHO'
                  : null;
    });

    unawaited(ReactAudio.play(ReactSoundCue.command));
    _armCommandTimer(_commandDurationMs);

    if (_isLightsOut) {
      _obscureTimer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted || _finished || _paused || !_acceptingInput) return;
        setState(() => _obscured = true);
      });
    }
  }

  void _armCommandTimer(int remainingMs) {
    final full = _commandDurationMs;
    final safe = remainingMs.clamp(1, full).toInt();
    final elapsedBeforePause = full - safe;

    _commandStartedAt = DateTime.now().subtract(
      Duration(milliseconds: elapsedBeforePause),
    );

    setState(() {
      _progress = safe / full;
      _acceptingInput = true;
    });

    _commandTimer?.cancel();
    _commandTimer = Timer.periodic(_tick, (_) {
      if (!mounted || _finished || _paused || !_acceptingInput) return;
      final elapsed = DateTime.now().difference(_commandStartedAt).inMilliseconds;
      final next = 1 - elapsed / _commandDurationMs;
      if (next <= 0) {
        _miss();
        return;
      }
      setState(() => _progress = next.clamp(0.0, 1.0));
    });
  }

  ReactCommand _expectedPerformedCommand() {
    if (!_isReverse) return _command;
    return switch (_command) {
      ReactCommand.swipeLeft => ReactCommand.swipeRight,
      ReactCommand.swipeRight => ReactCommand.swipeLeft,
      ReactCommand.swipeUp => ReactCommand.swipeDown,
      ReactCommand.swipeDown => ReactCommand.swipeUp,
      _ => _command,
    };
  }

  void _handleCommand(ReactCommand performed) {
    if (!_acceptingInput || _finished || _paused) return;
    if (performed != _expectedPerformedCommand()) {
      _miss();
      return;
    }
    _complete();
  }

  void _complete() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    _obscureTimer?.cancel();

    final responseMs = DateTime.now().difference(_commandStartedAt).inMilliseconds;
    final completedCommand = _command;
    final wasSurge = _surgeCommand;

    setState(() {
      _acceptingInput = false;
      _score += 1;
      _totalResponseMs += responseMs;

      if (_isSurge) {
        if (wasSurge) {
          _surgeRemaining = max(0, _surgeRemaining - 1);
        } else if (_score % 5 == 0 && _score < target) {
          _surgeRemaining = 3;
        }
      }

      if (_isEcho && _score % 6 == 0 && _score < target) {
        _echoNext = true;
      }

      _feedback = responseMs <= 650
          ? '+1  PERFECT'
          : responseMs <= 1150
              ? '+1  GREAT'
              : '+1  GOOD';
    });

    unawaited(ReactAudio.play(ReactSoundCue.success));
    _game.triggerSuccess();
    _syncFlameIntensity();

    if (_score >= target) {
      _nextTimer = Timer(
        const Duration(milliseconds: 260),
        () => _finish(ReactRunOutcome.completed),
      );
      return;
    }

    if (_echoNext) {
      _echoNext = false;
      _nextTimer = Timer(
        const Duration(milliseconds: 150),
        () => _startCommand(forced: completedCommand),
      );
      return;
    }

    final delay = _successDelayMs(wasSurge: wasSurge);
    _nextTimer = Timer(Duration(milliseconds: delay), _startCommand);
  }

  int _successDelayMs({required bool wasSurge}) {
    if (_isChain) return 70;
    if (_isSurge && _surgeRemaining > 0) return wasSurge ? 90 : 220;
    if (_isRedline && _redlineCommand) return 180;
    return _timing.successDelayMsForScore(_score);
  }

  void _miss() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    _obscureTimer?.cancel();
    _game.triggerMiss();
    unawaited(ReactAudio.play(ReactSoundCue.miss));
    setState(() {
      _acceptingInput = false;
      _misses += 1;
      _feedback = 'MISS';
    });
    _nextTimer = Timer(
      const Duration(milliseconds: 320),
      () => _finish(ReactRunOutcome.missedCommand),
    );
  }

  void _syncFlameIntensity() {
    var intensity = (.30 + _score * .010).clamp(.30, .88).toDouble();
    if (_surgeCommand) intensity = .96;
    if (_redlineCommand) intensity = 1.0;
    if (_isChain) intensity = max(intensity, .62);
    _game.setIntensity(intensity);
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;

    if (value) {
      _pausedHadCommand = _acceptingInput;
      _pausedRemainingMs = _pausedHadCommand
          ? max(1, (_commandDurationMs * _progress).round())
          : 0;
      _commandTimer?.cancel();
      _nextTimer?.cancel();
      _obscureTimer?.cancel();
      _game.pauseEngine();
      setState(() {
        _paused = true;
        _acceptingInput = false;
      });
      return;
    }

    _game.resumeEngine();
    setState(() => _paused = false);
    if (_pausedHadCommand && _pausedRemainingMs > 0) {
      final remaining = _pausedRemainingMs;
      _pausedHadCommand = false;
      _pausedRemainingMs = 0;
      _armCommandTimer(remaining);
      if (_isLightsOut && !_obscured) {
        _obscureTimer = Timer(const Duration(milliseconds: 250), () {
          if (!mounted || !_acceptingInput || _paused) return;
          setState(() => _obscured = true);
        });
      }
    } else {
      _startCommand();
    }
  }

  void _quit() {
    if (_finished || !mounted) return;
    _finished = true;
    _commandTimer?.cancel();
    _nextTimer?.cancel();
    _obscureTimer?.cancel();
    _game.pauseEngine();
    Navigator.of(context).pop();
  }

  void _finish(ReactRunOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    _acceptingInput = false;
    _commandTimer?.cancel();
    _nextTimer?.cancel();
    _obscureTimer?.cancel();

    if (outcome == ReactRunOutcome.completed) {
      unawaited(ReactAudio.play(ReactSoundCue.completed));
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          result: ReactRunResult(
            mode: ReactGameMode.daily,
            score: _score,
            successfulCommands: _score,
            averageTimeSeconds: _averageTimeSeconds,
            outcome: outcome,
            misses: _misses,
            failedCommand:
                outcome == ReactRunOutcome.missedCommand ? _command : null,
          ),
        ),
      ),
    );
  }

  String get _displayHint {
    if (_isReverse) {
      return switch (_command) {
        ReactCommand.swipeLeft => 'SWIPE RIGHT',
        ReactCommand.swipeRight => 'SWIPE LEFT',
        ReactCommand.swipeUp => 'SWIPE DOWN',
        ReactCommand.swipeDown => 'SWIPE UP',
        _ => _command.hint,
      };
    }
    return _command.hint;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _finished || _paused) return;
        _setPaused(true);
      },
      child: Scaffold(
        backgroundColor: ReactColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(game: _game),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final arenaSize =
                      constraints.maxWidth.clamp(318.0, 390.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      children: [
                        _DailyHeader(
                          score: _score,
                          modifier: _modifier,
                          onPause: () => _setPaused(true),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: ReactGestureSurface(
                              enabled: _acceptingInput && !_paused,
                              expectedCommand: _expectedPerformedCommand(),
                              onCommand: _handleCommand,
                              child: _DailyArena(
                                size: arenaSize,
                                command: _command,
                                hint: _displayHint,
                                progress: _progress,
                                commandDurationMs: _commandDurationMs,
                                obscureCommand: _obscured,
                                hideClock: _isNoClock,
                                reverse: _isReverse,
                                redline: _redlineCommand,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 100),
                              opacity: _feedback == null ? 0 : 1,
                              child: Text(
                                _feedback ?? '',
                                style: TextStyle(
                                  color: _feedback == 'MISS'
                                      ? ReactColors.coral
                                      : _feedback == 'REDLINE'
                                          ? ReactColors.coral
                                          : ReactColors.electricBlueBright,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _DailyBottomBar(
                          score: _score,
                          averageTimeSeconds: _averageTimeSeconds,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_paused)
              _DailyPauseOverlay(
                onResume: () => _setPaused(false),
                onQuit: _quit,
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyHeader extends StatelessWidget {
  const _DailyHeader({
    required this.score,
    required this.modifier,
    required this.onPause,
  });

  final int score;
  final DailyModifier modifier;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPause,
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
            const SizedBox(width: 8),
            Expanded(
              child: _HudCard(
                label: 'RULE',
                value: modifier.label,
                color: ReactColors.electricBlueBright,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HudCard(
                label: 'STEP',
                value: '$score/$target',
                color: ReactColors.purple,
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
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF243A57)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: compact ? 13 : 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyArena extends StatelessWidget {
  const _DailyArena({
    required this.size,
    required this.command,
    required this.hint,
    required this.progress,
    required this.commandDurationMs,
    required this.obscureCommand,
    required this.hideClock,
    required this.reverse,
    required this.redline,
  });

  final double size;
  final ReactCommand command;
  final String hint;
  final double progress;
  final int commandDurationMs;
  final bool obscureCommand;
  final bool hideClock;
  final bool reverse;
  final bool redline;

  @override
  Widget build(BuildContext context) {
    final seconds = (commandDurationMs * progress / 1000).clamp(0, 9.9);
    final accent = redline ? ReactColors.coral : ReactColors.electricBlueBright;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DailyRingPainter(
              progress: progress,
              accent: accent,
              hideClock: hideClock,
            ),
          ),
          Container(
            width: size * .69,
            height: size * .69,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(color: const Color(0xFF153B65), width: 1.5),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: obscureCommand ? 0 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (reverse && command.name.startsWith('swipe'))
                    const Text(
                      'DO THE OPPOSITE',
                      style: TextStyle(
                        color: ReactColors.coral,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
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
                  Icon(command.icon, color: accent, size: 92),
                  const SizedBox(height: 15),
                  Text(
                    hint,
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
          ),
          if (!hideClock)
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
        ],
      ),
    );
  }
}

class _DailyRingPainter extends CustomPainter {
  const _DailyRingPainter({
    required this.progress,
    required this.accent,
    required this.hideClock,
  });

  final double progress;
  final Color accent;
  final bool hideClock;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .44;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = const Color(0xFF122038);
    canvas.drawCircle(center, radius, base);

    if (hideClock) return;

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
  bool shouldRepaint(covariant _DailyRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.hideClock != hideClock;
}

class _DailyBottomBar extends StatelessWidget {
  const _DailyBottomBar({required this.score, required this.averageTimeSeconds});

  final int score;
  final double averageTimeSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF213A57)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: ReactColors.electricBlueBright, size: 21),
          const SizedBox(width: 8),
          const Text(
            'DAILY',
            style: TextStyle(
              color: ReactColors.electricBlueBright,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            '$score / $target',
            style: const TextStyle(
              color: ReactColors.lime,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 18),
          Text(
            averageTimeSeconds == 0 ? '--' : '${averageTimeSeconds.toStringAsFixed(2)}s',
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyPauseOverlay extends StatelessWidget {
  const _DailyPauseOverlay({required this.onResume, required this.onQuit});

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6050911),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF07111D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2B496B)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline_rounded, color: ReactColors.electricBlueBright, size: 52),
              const SizedBox(height: 12),
              const Text(
                'DAILY PAUSED',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'THE CURRENT COMMAND IS FROZEN',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onResume, child: const Text('RESUME')),
              TextButton(onPressed: onQuit, child: const Text('QUIT RUN')),
            ],
          ),
        ),
      ),
    );
  }
}
