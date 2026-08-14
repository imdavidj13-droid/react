import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../modes/domain/mode_timing_rules.dart';
import '../../results/presentation/results_screen.dart';
import '../domain/react_command.dart';
import '../domain/react_run_result.dart';
import '../domain/run_command_performance_tracker.dart';
import 'react_gesture_surface.dart';
import 'react_run_launch_screen.dart';

class ReactRunScreen extends StatefulWidget {
  const ReactRunScreen({required this.mode, super.key});

  final ReactGameMode mode;

  @override
  State<ReactRunScreen> createState() => _ReactRunScreenState();
}

class _ReactRunScreenState extends State<ReactRunScreen>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 32);

  late final ReactGame _game;
  late final Random _random;
  late final List<int> _playerLives;
  late final List<int> _playerClears;

  final Stopwatch _commandClock = Stopwatch();
  final Stopwatch _blitzClock = Stopwatch();
  final Stopwatch _transitionClock = Stopwatch();
  final RunCommandPerformanceTracker _commandTracker =
      RunCommandPerformanceTracker();

  Timer? _commandTimer;
  Timer? _nextTimer;
  Timer? _runTimer;

  ReactCommand _command = ReactCommand.tap;

  double _progress = 1;
  int _score = 0;
  int _successfulCommands = 0;
  int _misses = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;
  int _totalResponseMs = 0;
  int _lives = 3;
  int _currentPlayer = 0;
  int _passItTurnClears = 0;
  int _commandElapsedBaseMs = 0;
  int _pausedCommandRemainingMs = 0;
  int _blitzPenaltyMs = 0;
  int _pendingTransitionDurationMs = 0;
  int _pendingTransitionRemainingMs = 0;
  int? _handoffLostPlayer;
  int? _handoffLivesBefore;
  int? _handoffLivesAfter;
  int? _handoffWinnerPlayer;

  bool _acceptingInput = false;
  bool _finished = false;
  bool _paused = false;
  bool _handoff = false;
  bool _pausedHadActiveCommand = false;
  bool _blitzWarningPlayed = false;

  VoidCallback? _pendingTransitionAction;
  String? _feedback;

  ModeTimingRules get _timing => switch (widget.mode) {
    ReactGameMode.classic => ReactModeTiming.classic,
    ReactGameMode.blitz => ReactModeTiming.blitz,
    ReactGameMode.endless => ReactModeTiming.endless,
    ReactGameMode.daily => ReactModeTiming.daily,
    ReactGameMode.passIt => ReactModeTiming.passIt,
  };

  int get _timingScore =>
      widget.mode == ReactGameMode.passIt ? _passItTurnClears : _score;

  int get _baseCommandMs => _timing.commandDurationMsForScore(_timingScore);

  int get _commandDurationMs => _command.reactionWindowMs(_baseCommandMs);

  int get _commandElapsedMs =>
      _commandElapsedBaseMs + _commandClock.elapsedMilliseconds;

  int get _commandRemainingMs => max(0, _commandDurationMs - _commandElapsedMs);

  double get _averageTimeSeconds => _successfulCommands == 0
      ? 0
      : (_totalResponseMs / _successfulCommands) / 1000;

  int get _blitzMsRemaining {
    final runDuration = _timing.runDurationMs ?? 0;
    return max(
      0,
      runDuration - _blitzClock.elapsedMilliseconds - _blitzPenaltyMs,
    );
  }

  int get _alivePlayers => _playerLives.where((lives) => lives > 0).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final passItPlayers = ReactSettings.passItPlayerCount.clamp(2, 4).toInt();
    _playerLives = List<int>.filled(
      widget.mode == ReactGameMode.passIt ? passItPlayers : 3,
      3,
    );
    _playerClears = List<int>.filled(_playerLives.length, 0);

    _game = ReactGame()
      ..configure(
        accent: _modeColor(widget.mode),
        intensity: _initialFlameIntensity(widget.mode),
      );

    _random = Random();

    if (widget.mode == ReactGameMode.blitz) {
      _blitzClock.start();
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
    _commandClock.stop();
    _blitzClock.stop();
    _transitionClock.stop();
    super.dispose();
  }

  void _startCommand() {
    _commandTimer?.cancel();
    if (!mounted || _finished || _paused || _handoff) return;

    if (widget.mode == ReactGameMode.blitz && _blitzMsRemaining <= 0) {
      _finish(ReactRunOutcome.timeUp);
      return;
    }

    if (widget.mode == ReactGameMode.passIt && _alivePlayers <= 1) {
      final winner = _playerLives.indexWhere((lives) => lives > 0) + 1;
      _finish(ReactRunOutcome.winner, winnerPlayer: winner);
      return;
    }

    final next =
        ReactCommand.values[_random.nextInt(ReactCommand.values.length)];
    setState(() {
      _command = next;
      _progress = 1;
      _feedback = null;
    });

    _syncFlameIntensity();
    unawaited(ReactAudio.play(ReactSoundCue.command));
    _armCommandTimer(_commandDurationMs);
  }

  void _armCommandTimer(int remainingMs) {
    final fullDuration = _commandDurationMs;
    final safeRemaining = remainingMs.clamp(1, fullDuration).toInt();

    _commandElapsedBaseMs = fullDuration - safeRemaining;
    _commandClock
      ..reset()
      ..start();

    setState(() {
      _progress = safeRemaining / fullDuration;
      _acceptingInput = true;
    });

    _commandTimer?.cancel();
    _commandTimer = Timer.periodic(_tick, (_) {
      if (!mounted || _finished || _paused || !_acceptingInput) return;

      final remaining = _commandRemainingMs;
      if (remaining <= 0) {
        _miss();
        return;
      }

      final nextProgress = remaining / _commandDurationMs;
      setState(() => _progress = nextProgress.clamp(0.0, 1.0));
    });
  }

  void _handleCommand(ReactCommand performed) {
    if (!_acceptingInput || _finished || _paused || _handoff) return;

    if (widget.mode == ReactGameMode.blitz && _blitzMsRemaining <= 0) {
      _finish(ReactRunOutcome.timeUp);
      return;
    }

    if (_commandRemainingMs <= 0) {
      _miss();
      return;
    }

    if (performed != _command) {
      _miss();
      return;
    }
    _complete();
  }

  void _complete() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    _commandClock.stop();

    final responseMs = _commandElapsedMs.clamp(0, _commandDurationMs).toInt();
    _commandTracker.recordSuccess(_command, responseMs);

    setState(() {
      _acceptingInput = false;
      _score += 1;
      _successfulCommands += 1;
      _currentStreak += 1;
      _maxStreak = max(_maxStreak, _currentStreak);
      _totalResponseMs += responseMs;
      if (widget.mode == ReactGameMode.passIt) {
        _passItTurnClears += 1;
        _playerClears[_currentPlayer] += 1;
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

    _scheduleTransition(
      _timing.successDelayMsForScore(_timingScore),
      _startCommand,
    );
  }

  void _miss() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    _commandClock.stop();
    _commandTracker.recordMiss(_command);
    _game.triggerMiss();
    _currentStreak = 0;

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
          _scheduleTransition(
            420,
            () => _finish(ReactRunOutcome.missedCommand),
          );
        } else {
          _scheduleTransition(_timing.missDelayMs, _startCommand);
        }
        return;

      case ReactGameMode.blitz:
        final penalty = _timing.missTimePenaltyMs;
        _blitzPenaltyMs += penalty;
        unawaited(ReactAudio.play(ReactSoundCue.miss));
        setState(() {
          _acceptingInput = false;
          _misses += 1;
          _feedback = 'MISS  -${penalty ~/ 1000} SEC';
        });
        if (_blitzMsRemaining <= 0) {
          _finish(ReactRunOutcome.timeUp);
        } else {
          _scheduleTransition(_timing.missDelayMs, _startCommand);
        }
        return;

      case ReactGameMode.endless:
        unawaited(ReactAudio.play(ReactSoundCue.miss));
        setState(() {
          _acceptingInput = false;
          _misses += 1;
          _feedback = 'MISS';
        });
        _scheduleTransition(320, () => _finish(ReactRunOutcome.missedCommand));
        return;

      case ReactGameMode.daily:
        unawaited(ReactAudio.play(ReactSoundCue.miss));
        setState(() {
          _acceptingInput = false;
          _misses += 1;
          _feedback = 'MISS';
        });
        _finish(ReactRunOutcome.missedCommand);
        return;

      case ReactGameMode.passIt:
        final lostPlayer = _currentPlayer;
        final livesBefore = _playerLives[lostPlayer];
        final livesAfter = max(0, livesBefore - 1);
        unawaited(ReactAudio.play(ReactSoundCue.lifeLost));
        setState(() {
          _acceptingInput = false;
          _misses += 1;
          _playerLives[lostPlayer] = livesAfter;
          _feedback =
              'PLAYER ${lostPlayer + 1} LOST A LIFE  •  $livesAfter LEFT';
        });
        _showPassItLifeLoss(
          lostPlayer: lostPlayer,
          livesBefore: livesBefore,
          livesAfter: livesAfter,
        );
        return;
    }
  }

  void _syncFlameIntensity() {
    final intensity = switch (widget.mode) {
      ReactGameMode.classic => (.18 + _score * .008).clamp(.18, .48),
      ReactGameMode.blitz => (.45 + _score * .006).clamp(.45, .72),
      ReactGameMode.endless => (.24 + _score * .035).clamp(.24, 1.0),
      ReactGameMode.daily => (.28 + _score * .014).clamp(.28, .72),
      ReactGameMode.passIt => .30,
    };
    _game.setIntensity(intensity.toDouble());
  }

  void _showPassItLifeLoss({
    required int lostPlayer,
    required int livesBefore,
    required int livesAfter,
  }) {
    setState(() => _acceptingInput = false);

    if (_alivePlayers <= 1) {
      final winner = _playerLives.indexWhere((lives) => lives > 0) + 1;
      _scheduleTransition(300, () {
        if (!mounted || _finished) return;
        setState(() {
          _handoff = true;
          _handoffLostPlayer = lostPlayer;
          _handoffLivesBefore = livesBefore;
          _handoffLivesAfter = livesAfter;
          _handoffWinnerPlayer = winner;
        });
      });
      return;
    }

    var candidate = lostPlayer;
    do {
      candidate = (candidate + 1) % _playerLives.length;
    } while (_playerLives[candidate] <= 0);

    _scheduleTransition(300, () {
      if (!mounted || _finished) return;
      setState(() {
        _currentPlayer = candidate;
        _handoff = true;
        _handoffLostPlayer = lostPlayer;
        _handoffLivesBefore = livesBefore;
        _handoffLivesAfter = livesAfter;
        _handoffWinnerPlayer = null;
      });
      unawaited(ReactAudio.play(ReactSoundCue.handoff));
    });
  }

  void _beginPassItTurn() {
    if (_finished || _paused || !_handoff) return;

    final winner = _handoffWinnerPlayer;
    if (winner != null) {
      _finish(ReactRunOutcome.winner, winnerPlayer: winner);
      return;
    }

    setState(() {
      _handoff = false;
      _handoffLostPlayer = null;
      _handoffLivesBefore = null;
      _handoffLivesAfter = null;
      _passItTurnClears = 0;
      _feedback = null;
    });
    _startCommand();
  }

  void _scheduleTransition(int durationMs, VoidCallback action) {
    _nextTimer?.cancel();
    _transitionClock
      ..stop()
      ..reset()
      ..start();
    _pendingTransitionDurationMs = max(1, durationMs);
    _pendingTransitionRemainingMs = _pendingTransitionDurationMs;
    _pendingTransitionAction = action;
    _nextTimer = Timer(
      Duration(milliseconds: _pendingTransitionDurationMs),
      _runPendingTransition,
    );
  }

  void _runPendingTransition() {
    if (!mounted || _finished) {
      _clearPendingTransition();
      return;
    }
    if (_paused) return;

    final action = _pendingTransitionAction;
    _clearPendingTransition();
    if (action == null) return;
    action();
  }

  void _pausePendingTransition() {
    if (_pendingTransitionAction == null) return;
    _pendingTransitionRemainingMs = max(
      1,
      _pendingTransitionDurationMs - _transitionClock.elapsedMilliseconds,
    );
    _nextTimer?.cancel();
    _transitionClock.stop();
  }

  void _resumePendingTransition() {
    if (_pendingTransitionAction == null) return;
    final remaining = max(1, _pendingTransitionRemainingMs);
    _pendingTransitionDurationMs = remaining;
    _pendingTransitionRemainingMs = remaining;
    _transitionClock
      ..reset()
      ..start();
    _nextTimer?.cancel();
    _nextTimer = Timer(
      Duration(milliseconds: remaining),
      _runPendingTransition,
    );
  }

  void _clearPendingTransition() {
    _nextTimer?.cancel();
    _nextTimer = null;
    _transitionClock
      ..stop()
      ..reset();
    _pendingTransitionDurationMs = 0;
    _pendingTransitionRemainingMs = 0;
    _pendingTransitionAction = null;
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;

    if (value) {
      _pausedHadActiveCommand = _acceptingInput && !_handoff;
      if (_pausedHadActiveCommand) {
        _pausedCommandRemainingMs = max(1, _commandRemainingMs);
        _commandClock.stop();
      } else {
        _pausedCommandRemainingMs = 0;
      }

      _commandTimer?.cancel();
      _pausePendingTransition();
      if (widget.mode == ReactGameMode.blitz) {
        _blitzClock.stop();
      }
      _game.pauseEngine();

      setState(() {
        _paused = true;
        _acceptingInput = false;
      });
      return;
    }

    if (widget.mode == ReactGameMode.blitz && !_blitzClock.isRunning) {
      _blitzClock.start();
    }

    _game.resumeEngine();
    setState(() => _paused = false);

    if (_handoff) return;

    if (_pausedHadActiveCommand && _pausedCommandRemainingMs > 0) {
      final remaining = _pausedCommandRemainingMs;
      _pausedHadActiveCommand = false;
      _pausedCommandRemainingMs = 0;
      _armCommandTimer(remaining);
      return;
    }

    if (_pendingTransitionAction != null) {
      _resumePendingTransition();
      return;
    }

    _startCommand();
  }

  void _restart() {
    if (!mounted) return;

    final screen = switch (widget.mode) {
      ReactGameMode.classic ||
      ReactGameMode.blitz ||
      ReactGameMode.endless => ReactRunLaunchScreen(mode: widget.mode),
      ReactGameMode.passIt => const ReactRunScreen(mode: ReactGameMode.passIt),
      ReactGameMode.daily => null,
    };
    if (screen == null) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _quitRun() {
    if (_finished || !mounted) return;
    _finished = true;
    _acceptingInput = false;
    _commandTimer?.cancel();
    _runTimer?.cancel();
    _clearPendingTransition();
    _commandClock.stop();
    _blitzClock.stop();
    _game.pauseEngine();
    Navigator.of(context).pop();
  }

  void _finish(ReactRunOutcome outcome, {int? winnerPlayer}) {
    if (_finished || !mounted) return;
    _finished = true;
    _acceptingInput = false;
    _commandTimer?.cancel();
    _runTimer?.cancel();
    _clearPendingTransition();
    _commandClock.stop();
    _blitzClock.stop();

    if (outcome == ReactRunOutcome.completed ||
        outcome == ReactRunOutcome.winner) {
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
            maxStreak: _maxStreak,
            failedCommand: outcome == ReactRunOutcome.missedCommand
                ? _command
                : null,
            winnerPlayer: winnerPlayer,
            playerLives: widget.mode == ReactGameMode.passIt
                ? List<int>.unmodifiable(_playerLives)
                : null,
            playerClears: widget.mode == ReactGameMode.passIt
                ? List<int>.unmodifiable(_playerClears)
                : null,
            commandPerformance: _commandTracker.snapshot(),
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
    ReactGameMode.passIt => 'PLAYER',
  };

  String get _statusValue => switch (widget.mode) {
    ReactGameMode.classic => List.filled(_lives, '♥').join(' '),
    ReactGameMode.blitz => '${(_blitzMsRemaining / 1000).ceil()}s',
    ReactGameMode.endless => '${(_baseCommandMs / 1000).toStringAsFixed(2)}s',
    ReactGameMode.daily => 'DAILY',
    ReactGameMode.passIt =>
      'P${_currentPlayer + 1}  ${_playerLives[_currentPlayer]}♥',
  };

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
                  final arenaSize = constraints.maxWidth
                      .clamp(318.0, 390.0)
                      .toDouble();
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
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      _feedback?.contains('LOST A LIFE') ==
                                              true ||
                                          _feedback?.startsWith('MISS') == true
                                      ? ReactColors.coral
                                      : ReactColors.electricBlueBright,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
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
                onRestart: widget.mode == ReactGameMode.daily ? null : _restart,
                onQuit: _quitRun,
              ),
            if (_handoff && !_paused)
              _HandoffOverlay(
                player: _currentPlayer + 1,
                lives: _playerLives[_currentPlayer],
                lostPlayer: _handoffLostPlayer == null
                    ? null
                    : _handoffLostPlayer! + 1,
                livesBefore: _handoffLivesBefore,
                livesAfter: _handoffLivesAfter,
                winnerPlayer: _handoffWinnerPlayer,
                onReady: _beginPassItTurn,
              ),
          ],
        ),
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
                  size:
                      command == ReactCommand.pinch ||
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
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      .8,
      1.45,
      false,
      deco,
    );
    deco.color = ReactColors.lime.withValues(alpha: .7);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.0,
      1.25,
      false,
      deco,
    );
    deco.color = ReactColors.coral.withValues(alpha: .7);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.75,
      1.1,
      false,
      deco,
    );

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
  final VoidCallback? onRestart;
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
            if (onRestart != null)
              TextButton(
                onPressed: onRestart,
                child: const Text('RESTART RUN'),
              ),
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
    required this.lostPlayer,
    required this.livesBefore,
    required this.livesAfter,
    required this.winnerPlayer,
    required this.onReady,
  });

  final int player;
  final int lives;
  final int? lostPlayer;
  final int? livesBefore;
  final int? livesAfter;
  final int? winnerPlayer;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final hasLifeLoss =
        lostPlayer != null && livesBefore != null && livesAfter != null;
    final matchOver = winnerPlayer != null;

    return ColoredBox(
      color: const Color(0xF2050911),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 330,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF07111D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasLifeLoss ? ReactColors.coral : ReactColors.purple,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasLifeLoss
                      ? Icons.heart_broken_rounded
                      : Icons.phone_android_rounded,
                  color: hasLifeLoss ? ReactColors.coral : ReactColors.purple,
                  size: 58,
                ),
                if (hasLifeLoss) ...[
                  const SizedBox(height: 14),
                  Text(
                    'PLAYER $lostPlayer LOST A LIFE',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ReactColors.coral,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LifeCount(value: livesBefore!),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: ReactColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      _LifeCount(value: livesAfter!, lost: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: const Color(0xFF283A52)),
                ],
                const SizedBox(height: 18),
                Text(
                  matchOver
                      ? 'PLAYER $winnerPlayer WINS'
                      : hasLifeLoss
                      ? 'PASS TO PLAYER $player'
                      : 'PLAYER $player STARTS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: matchOver
                        ? ReactColors.lime
                        : ReactColors.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (!matchOver)
                  Text(
                    'PLAYER $player  •  $lives LIVES  •  TAP WHEN READY',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ReactColors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  )
                else
                  const Text(
                    'LAST PLAYER STANDING',
                    style: TextStyle(
                      color: ReactColors.lime,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 230,
                  height: 58,
                  child: FilledButton(
                    onPressed: onReady,
                    child: Text(matchOver ? 'SHOW RESULTS' : 'I’M READY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LifeCount extends StatelessWidget {
  const _LifeCount({required this.value, this.lost = false});

  final int value;
  final bool lost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF090F1B),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: lost
              ? ReactColors.coral.withValues(alpha: .62)
              : const Color(0xFF30445F),
        ),
      ),
      child: Text(
        value == 0 ? '0  OUT' : '$value  ${List.filled(value, '♥').join(' ')}',
        style: TextStyle(
          color: lost ? ReactColors.coral : ReactColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
