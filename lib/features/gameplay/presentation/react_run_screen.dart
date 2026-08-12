import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../modes/domain/mode_timing_rules.dart';
import '../../results/presentation/results_screen.dart';
import '../domain/react_command.dart';
import '../domain/react_run_result.dart';
import 'react_gesture_surface.dart';

class ReactRunScreen extends StatefulWidget {
  const ReactRunScreen({required this.mode, super.key});

  final ReactGameMode mode;

  @override
  State<ReactRunScreen> createState() => _ReactRunScreenState();
}

class _ReactRunScreenState extends State<ReactRunScreen>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 32);
  static const _dailyTarget = 20;

  late final ReactGame _game;
  late final Random _random;

  Timer? _commandTimer;
  Timer? _nextTimer;
  Timer? _runTimer;

  ReactCommand _command = ReactCommand.tap;
  DateTime _commandStartedAt = DateTime.now();
  DateTime? _blitzDeadline;
  Duration _pausedBlitzRemaining = Duration.zero;

  double _progress = 1;
  int _score = 0;
  int _successfulCommands = 0;
  int _misses = 0;
  int _totalResponseMs = 0;
  int _lives = 3;
  int _currentPlayer = 0;
  final List<int> _playerLives = [3, 3, 3];

  bool _acceptingInput = false;
  bool _finished = false;
  bool _paused = false;
  bool _handoff = false;
  bool _pausedHadActiveCommand = false;
  bool _blitzWarningPlayed = false;
  int _pausedCommandRemainingMs = 0;
  String? _feedback;

  ModeTimingRules get _timing => switch (widget.mode) {
        ReactGameMode.classic => ReactModeTiming.classic,
        ReactGameMode.blitz => ReactModeTiming.blitz,
        ReactGameMode.endless => ReactModeTiming.endless,
        ReactGameMode.daily => ReactModeTiming.daily,
        ReactGameMode.passIt => ReactModeTiming.passIt,
      };

  int get _baseCommandMs => _timing.commandDurationMsForScore(_score);

  int get _commandDurationMs {
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
    return (_baseCommandMs * multiplier).round();
  }

  double get _averageTimeSeconds => _successfulCommands == 0
      ? 0
      : (_totalResponseMs / _successfulCommands) / 1000;

  int get _blitzMsRemaining {
    final deadline = _blitzDeadline;
    if (deadline == null) return _timing.runDurationMs ?? 0;
    return max(0, deadline.difference(DateTime.now()).inMilliseconds);
  }

  int get _alivePlayers => _playerLives.where((lives) => lives > 0).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _game = ReactGame()
      ..configure(
        accent: _modeColor(widget.mode),
        intensity: _initialFlameIntensity(widget.mode),
      );

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    _random = widget.mode == ReactGameMode.daily ? Random(seed) : Random();

    if (widget.mode == ReactGameMode.blitz) {
      _blitzDeadline = DateTime.now().add(
        Duration(milliseconds: _timing.runDurationMs!),
      );
      _runTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted || _finished || _paused) return;

        final remaining = _blitzMsRemaining;
        if (remaining <= 10000 && !_blitzWarningPlayed) {
          _blitzWarningPlayed = true;
          unawaited(ReactAudio.play(ReactSoundCue.blitzWarning));
        }

        if (remaining <= 0) {
          _finish(ReactRunOutcome.timeUp);
        } else {
          setState(() {});
        }
      });
    }

    if (widget.mode == ReactGameMode.passIt) {
      _handoff = true;
      _acceptingInput = false;
      unawaited(ReactAudio.play(ReactSoundCue.handoff));
    } else {
      _startCommand();
    }
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
    _runTimer?.cancel();
    super.dispose();
  }

  void _startCommand() {
    _commandTimer?.cancel();
    _nextTimer?.cancel();
    if (!mounted || _finished || _paused || _handoff) return;

    if (widget.mode == ReactGameMode.daily && _score >= _dailyTarget) {
      _finish(ReactRunOutcome.completed);
      return;
    }

    if (widget.mode == ReactGameMode.passIt && _alivePlayers <= 1) {
      final winner = _playerLives.indexWhere((lives) => lives > 0) + 1;
      _finish(ReactRunOutcome.winner, winnerPlayer: winner);
      return;
    }

    final next = ReactCommand.values[_random.nextInt(ReactCommand.values.length)];
    setState(() {
      _command = next;
      _progress = 1;
      _feedback = null;
    });

    unawaited(ReactAudio.play(ReactSoundCue.command));
    _armCommandTimer(_commandDurationMs);
  }

  void _armCommandTimer(int remainingMs) {
    final fullDuration = _commandDurationMs;
    final safeRemaining = remainingMs.clamp(1, fullDuration).toInt();
    final elapsedBeforePause = fullDuration - safeRemaining;

    _commandStartedAt = DateTime.now().subtract(
      Duration(milliseconds: elapsedBeforePause),
    );

    setState(() {
      _progress = safeRemaining / fullDuration;
      _acceptingInput = true;
    });

    _commandTimer?.cancel();
    _commandTimer = Timer.periodic(_tick, (_) {
      if (!mounted || _finished || _paused || !_acceptingInput) return;

      final elapsed = DateTime.now().difference(_commandStartedAt).inMilliseconds;
      final nextProgress = 1 - (elapsed / _commandDurationMs);
      if (nextProgress <= 0) {
        _miss();
        return;
      }
      setState(() => _progress = nextProgress.clamp(0.0, 1.0));
    });
  }

  void _handleCommand(ReactCommand performed) {
    if (!_acceptingInput || _finished || _paused || _handoff) return;
    if (performed != _command) {
      _miss();
      return;
    }
    _complete();
  }

  void _complete() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    final responseMs = DateTime.now().difference(_commandStartedAt).inMilliseconds;

    setState(() {
      _acceptingInput = false;
      _score += 1;
      _successfulCommands += 1;
      _totalResponseMs += responseMs;
      _feedback = responseMs <= 650
          ? '+1  PERFECT'
          : responseMs <= 1150
              ? '+1  GREAT'
              : '+1  GOOD';
    });

    unawaited(ReactAudio.play(ReactSoundCue.success));
    _game.triggerSuccess();
    _syncFlameIntensity();

    if (widget.mode == ReactGameMode.passIt) {
      _advancePlayerAndHandoff();
      return;
    }

    _nextTimer = Timer(
      Duration(milliseconds: _timing.successDelayMsForScore(_score)),
      _startCommand,
    );
  }

  void _miss() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    _game.triggerMiss();

    switch (widget.mode) {
      case ReactGameMode.classic:
        final remaining = _lives - 1;
        unawaited(ReactAudio.play(ReactSoundCue.lifeLost));
        setState(() {
          _acceptingInput = false;
          _lives = remaining;
          _misses += 1;
          _feedback = 'MISS  •  $remaining LIVES LEFT';
        });
        if (remaining <= 0) {
          _nextTimer = Timer(
            const Duration(milliseconds: 420),
            () => _finish(ReactRunOutcome.missedCommand),
          );
        } else {
          _nextTimer = Timer(
            Duration(milliseconds: _timing.missDelayMs),
            _startCommand,
          );
        }
        return;

      case ReactGameMode.blitz:
        final penalty = _timing.missTimePenaltyMs;
        final remaining = max(0, _blitzMsRemaining - penalty);
        _blitzDeadline = DateTime.now().add(Duration(milliseconds: remaining));
        unawaited(ReactAudio.play(ReactSoundCue.miss));
        setState(() {
          _acceptingInput = false;
          _misses += 1;
          _feedback = 'MISS  -${penalty ~/ 1000} SEC';
        });
        if (remaining <= 0) {
          _finish(ReactRunOutcome.timeUp);
        } else {
          _nextTimer = Timer(
            Duration(milliseconds: _timing.missDelayMs),
            _startCommand,
          );
        }
        return;

      case ReactGameMode.endless:
        unawaited(ReactAudio.play(ReactSoundCue.miss));
        setState(() => _misses += 1);
        _finish(ReactRunOutcome.missedCommand);
        return;

      case ReactGameMode.daily:
        unawaited(ReactAudio.play(ReactSoundCue.miss));
        setState(() => _misses += 1);
        _finish(ReactRunOutcome.missedCommand);
        return;

      case ReactGameMode.passIt:
        unawaited(ReactAudio.play(ReactSoundCue.lifeLost));
        setState(() {
          _acceptingInput = false;
          _misses += 1;
          _playerLives[_currentPlayer] = max(0, _playerLives[_currentPlayer] - 1);
          _feedback = 'MISS  •  LIFE LOST';
        });
        _advancePlayerAndHandoff();
        return;
    }
  }

  void _syncFlameIntensity() {
    final intensity = switch (widget.mode) {
      ReactGameMode.classic => (.18 + _score * .008).clamp(.18, .48),
      ReactGameMode.blitz => (.45 + _score * .006).clamp(.45, .72),
      ReactGameMode.endless => (.24 + _score * .035).clamp(.24, 1.0),
      ReactGameMode.daily => .28,
      ReactGameMode.passIt => .30,
    };
    _game.setIntensity(intensity.toDouble());
  }

  void _advancePlayerAndHandoff() {
    setState(() => _acceptingInput = false);

    if (_alivePlayers <= 1) {
      final winner = _playerLives.indexWhere((lives) => lives > 0) + 1;
      _nextTimer = Timer(
        const Duration(milliseconds: 450),
        () => _finish(ReactRunOutcome.winner, winnerPlayer: winner),
      );
      return;
    }

    var candidate = _currentPlayer;
    do {
      candidate = (candidate + 1) % _playerLives.length;
    } while (_playerLives[candidate] <= 0);

    _nextTimer = Timer(const Duration(milliseconds: 320), () {
      if (!mounted || _finished) return;
      setState(() {
        _currentPlayer = candidate;
        _handoff = true;
        _feedback = null;
      });
      unawaited(ReactAudio.play(ReactSoundCue.handoff));
    });
  }

  void _beginPassItTurn() {
    setState(() {
      _handoff = false;
      _feedback = null;
    });
    _startCommand();
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;

    if (value) {
      _pausedHadActiveCommand = _acceptingInput && !_handoff;
      if (_pausedHadActiveCommand) {
        _pausedCommandRemainingMs = max(
          1,
          (_commandDurationMs * _progress).round(),
        );
      } else {
        _pausedCommandRemainingMs = 0;
      }

      _commandTimer?.cancel();
      _nextTimer?.cancel();
      _game.pauseEngine();

      if (widget.mode == ReactGameMode.blitz) {
        _pausedBlitzRemaining = Duration(milliseconds: _blitzMsRemaining);
      }

      setState(() {
        _paused = true;
        _acceptingInput = false;
      });
      return;
    }

    if (widget.mode == ReactGameMode.blitz) {
      _blitzDeadline = DateTime.now().add(_pausedBlitzRemaining);
    }

    _game.resumeEngine();
    setState(() => _paused = false);

    if (_handoff) return;

    if (_pausedHadActiveCommand && _pausedCommandRemainingMs > 0) {
      final remaining = _pausedCommandRemainingMs;
      _pausedHadActiveCommand = false;
      _pausedCommandRemainingMs = 0;
      _armCommandTimer(remaining);
    } else {
      _startCommand();
    }
  }

  void _restart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReactRunScreen(mode: widget.mode),
      ),
    );
  }

  void _finish(ReactRunOutcome outcome, {int? winnerPlayer}) {
    if (_finished || !mounted) return;
    _finished = true;
    _acceptingInput = false;
    _commandTimer?.cancel();
    _nextTimer?.cancel();
    _runTimer?.cancel();

    if (outcome == ReactRunOutcome.completed || outcome == ReactRunOutcome.winner) {
      unawaited(ReactAudio.play(ReactSoundCue.completed));
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          result: ReactRunResult(
            mode: widget.mode,
            score: _score,
            successfulCommands: _successfulCommands,
            averageTimeSeconds: _averageTimeSeconds,
            outcome: outcome,
            misses: _misses,
            failedCommand: outcome == ReactRunOutcome.missedCommand
                ? _command
                : null,
            winnerPlayer: winnerPlayer,
            playerLives: widget.mode == ReactGameMode.passIt
                ? List<int>.unmodifiable(_playerLives)
                : null,
          ),
        ),
      ),
    );
  }

  String get _statusLabel => switch (widget.mode) {
        ReactGameMode.classic => 'LIVES',
        ReactGameMode.blitz => 'TIME',
        ReactGameMode.endless => 'PACE',
        ReactGameMode.daily => 'STEP',
        ReactGameMode.passIt => 'TURN',
      };

  String get _statusValue => switch (widget.mode) {
        ReactGameMode.classic => List.filled(_lives, '♥').join(' '),
        ReactGameMode.blitz => '${(_blitzMsRemaining / 1000).ceil()}s',
        ReactGameMode.endless => '${(_baseCommandMs / 1000).toStringAsFixed(2)}s',
        ReactGameMode.daily => '$_score/$_dailyTarget',
        ReactGameMode.passIt =>
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
                final arenaSize = constraints.maxWidth.clamp(318.0, 390.0).toDouble();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    children: [
                      _Header(
                        mode: widget.mode,
                        score: _score,
                        statusLabel: _statusLabel,
                        statusValue: _statusValue,
                        onPause: () => _setPaused(true),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: ReactGestureSurface(
                            enabled: _acceptingInput && !_paused && !_handoff,
                            expectedCommand: _command,
                            onCommand: _handleCommand,
                            child: _Arena(
                              size: arenaSize,
                              command: _command,
                              progress: _progress,
                              commandDurationMs: _commandDurationMs,
                              accent: _modeColor(widget.mode),
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
                              _feedback ?? '',
                              style: TextStyle(
                                color: _feedback?.startsWith('MISS') == true
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
                      _BottomBar(
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
          if (_paused)
            _PauseOverlay(
              onResume: () => _setPaused(false),
              onRestart: _restart,
              onQuit: () => Navigator.of(context).pop(),
            ),
          if (_handoff && !_paused)
            _HandoffOverlay(
              player: _currentPlayer + 1,
              lives: _playerLives[_currentPlayer],
              onReady: _beginPassItTurn,
            ),
        ],
      ),
    );
  }
}

Color _modeColor(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => ReactColors.electricBlueBright,
      ReactGameMode.blitz => ReactColors.coral,
      ReactGameMode.endless => ReactColors.lime,
      ReactGameMode.daily => ReactColors.electricBlueBright,
      ReactGameMode.passIt => ReactColors.purple,
    };

double _initialFlameIntensity(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => .18,
      ReactGameMode.blitz => .45,
      ReactGameMode.endless => .24,
      ReactGameMode.daily => .28,
      ReactGameMode.passIt => .30,
    };

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.score,
    required this.statusLabel,
    required this.statusValue,
    required this.onPause,
  });

  final ReactGameMode mode;
  final int score;
  final String statusLabel;
  final String statusValue;
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
                label: 'MODE',
                value: mode.label,
                color: _modeColor(mode),
                compact: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HudCard(
                label: statusLabel,
                value: statusValue,
                color: mode == ReactGameMode.classic
                    ? ReactColors.coral
                    : _modeColor(mode),
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

class _Arena extends StatelessWidget {
  const _Arena({
    required this.size,
    required this.command,
    required this.progress,
    required this.commandDurationMs,
    required this.accent,
  });

  final double size;
  final ReactCommand command;
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
            painter: _RingPainter(progress: progress, accent: accent),
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
                  size: command == ReactCommand.pinch || command == ReactCommand.spread
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

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.accent});

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
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.mode,
    required this.score,
    required this.misses,
    required this.averageTimeSeconds,
  });

  final ReactGameMode mode;
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
          Icon(Icons.bolt_rounded, color: _modeColor(mode), size: 21),
          const SizedBox(width: 8),
          Text(
            mode.label,
            style: TextStyle(
              color: _modeColor(mode),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _Metric(label: 'SCORE', value: '$score'),
          const _Divider(),
          _Metric(label: 'MISSES', value: '$misses'),
          const _Divider(),
          _Metric(
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
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

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) => ColoredBox(
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
                const Icon(
                  Icons.pause_circle_outline_rounded,
                  color: ReactColors.electricBlueBright,
                  size: 52,
                ),
                const SizedBox(height: 12),
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
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
                TextButton(onPressed: onRestart, child: const Text('RESTART RUN')),
                TextButton(onPressed: onQuit, child: const Text('QUIT RUN')),
              ],
            ),
          ),
        ),
      );
}

class _HandoffOverlay extends StatelessWidget {
  const _HandoffOverlay({
    required this.player,
    required this.lives,
    required this.onReady,
  });

  final int player;
  final int lives;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xF2050911),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_android_rounded,
                  color: ReactColors.purple,
                  size: 66,
                ),
                const SizedBox(height: 18),
                Text(
                  'PASS TO PLAYER $player',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${List.filled(lives, '♥').join(' ')}  •  TAP WHEN READY',
                  style: const TextStyle(
                    color: ReactColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 230,
                  height: 58,
                  child: FilledButton(
                    onPressed: onReady,
                    child: const Text('I’M READY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
