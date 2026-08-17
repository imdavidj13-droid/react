import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/cosmetics/react_cosmetics.dart';
import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/domain/run_command_performance_tracker.dart';
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
  static const _tick = Duration(milliseconds: 32);
  static const _lightsOutVisibleMs = 650;

  late final DailyChallenge _challenge;
  late final DailyModifier _modifier;
  late final Random _random;
  late final ReactGame _game;
  late final bool _isDailyDevRun;

  final Stopwatch _commandClock = Stopwatch();
  final RunCommandPerformanceTracker _commandTracker =
      RunCommandPerformanceTracker();

  Timer? _commandTimer;
  Timer? _nextTimer;
  Timer? _obscureTimer;

  ReactCommand _command = ReactCommand.tap;
  ReactCommand? _pendingForcedCommand;
  int _score = 0;
  int _misses = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;
  int _totalResponseMs = 0;
  int _surgeRemaining = 0;
  int _commandSerial = 0;
  int _elapsedBeforeArmMs = 0;
  int _pausedRemainingMs = 0;

  double _progress = 1;
  bool _acceptingInput = false;
  bool _finished = false;
  bool _paused = false;
  bool _obscured = false;
  bool _echoNext = false;
  bool _pendingNextCommand = false;
  bool _pendingFinishAfterMiss = false;
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
    return _command.reactionWindowMs(base);
  }

  int get _commandElapsedMs =>
      _elapsedBeforeArmMs + _commandClock.elapsedMilliseconds;
  int get _commandRemainingMs => max(0, _commandDurationMs - _commandElapsedMs);
  double get _averageTimeSeconds =>
      _score == 0 ? 0 : (_totalResponseMs / _score) / 1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isDailyDevRun = ReactSettings.dailyDevRunActive;
    _challenge = DailyChallenge.today();
    _modifier = _challenge.modifier;
    _random = Random(_challenge.seed);
    _game = ReactGame()
      ..configure(accent: ReactCosmetics.palette.primary, intensity: .30);
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
    _commandClock.stop();
    _commandTimer?.cancel();
    _nextTimer?.cancel();
    _obscureTimer?.cancel();
    super.dispose();
  }

  ReactCommand _nextRandomCommand() {
    final values = ReactCommand.values;
    return values[_random.nextInt(values.length)];
  }

  void _startCommand({ReactCommand? forced}) {
    _commandTimer?.cancel();
    _obscureTimer?.cancel();
    if (!mounted || _finished || _paused) return;

    _nextTimer = null;
    _pendingNextCommand = false;
    _pendingFinishAfterMiss = false;
    _pendingForcedCommand = null;

    final next = forced ?? _nextRandomCommand();
    setState(() {
      _command = next;
      _commandSerial += 1;
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

    _syncFlameIntensity();
    unawaited(ReactAudio.play(ReactSoundCue.command));
    _armCommandTimer(_commandDurationMs);
  }

  void _armCommandTimer(int remainingMs) {
    final full = _commandDurationMs;
    final safe = remainingMs.clamp(1, full).toInt();
    _elapsedBeforeArmMs = full - safe;
    _commandClock
      ..reset()
      ..start();

    setState(() {
      _progress = safe / full;
      _acceptingInput = true;
    });
    _armLightsOutTimer(_elapsedBeforeArmMs);

    _commandTimer?.cancel();
    _commandTimer = Timer.periodic(_tick, (_) {
      if (!mounted || _finished || _paused || !_acceptingInput) return;
      final remaining = _commandRemainingMs;
      if (remaining <= 0) {
        _miss();
        return;
      }
      setState(
        () => _progress = (remaining / _commandDurationMs).clamp(0.0, 1.0),
      );
    });
  }

  void _armLightsOutTimer(int elapsedMs) {
    _obscureTimer?.cancel();
    if (!_isLightsOut || _obscured) return;
    final remaining = _lightsOutVisibleMs - elapsedMs;
    if (remaining <= 0) {
      if (mounted) setState(() => _obscured = true);
      return;
    }
    _obscureTimer = Timer(Duration(milliseconds: remaining), () {
      if (!mounted || _finished || _paused || !_acceptingInput) return;
      setState(() => _obscured = true);
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
    if (_commandRemainingMs <= 0 || performed != _expectedPerformedCommand()) {
      _miss();
      return;
    }
    _complete();
  }

  void _complete() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    _obscureTimer?.cancel();
    _commandClock.stop();

    final responseMs = _commandElapsedMs.clamp(0, _commandDurationMs).toInt();
    final completedCommand = _command;
    final wasSurge = _surgeCommand;
    final wasRedline = _redlineCommand;
    _commandTracker.recordSuccess(_command, responseMs);

    setState(() {
      _acceptingInput = false;
      _score += 1;
      _currentStreak += 1;
      _maxStreak = max(_maxStreak, _currentStreak);
      _totalResponseMs += responseMs;

      if (_isSurge) {
        if (wasSurge) {
          _surgeRemaining = max(0, _surgeRemaining - 1);
        } else if (_score % 5 == 0) {
          _surgeRemaining = 3;
        }
      }
      if (_isEcho && _score % 6 == 0) _echoNext = true;

      _feedback = responseMs <= 650
          ? '+1  PERFECT'
          : responseMs <= 1150
              ? '+1  GREAT'
              : '+1  GOOD';
    });

    unawaited(ReactAudio.play(ReactSoundCue.success));
    _game.triggerSuccess();

    if (_echoNext) {
      _echoNext = false;
      _scheduleNext(150, forced: completedCommand);
      return;
    }
    _scheduleNext(
      _successDelayMs(wasSurge: wasSurge, wasRedline: wasRedline),
    );
  }

  void _scheduleNext(int delayMs, {ReactCommand? forced}) {
    _nextTimer?.cancel();
    _pendingFinishAfterMiss = false;
    _pendingNextCommand = true;
    _pendingForcedCommand = forced;
    _nextTimer = Timer(Duration(milliseconds: max(1, delayMs)), () {
      if (!mounted || _finished || _paused) return;
      final pendingForcedCommand = _pendingForcedCommand;
      _nextTimer = null;
      _pendingNextCommand = false;
      _pendingForcedCommand = null;
      _startCommand(forced: pendingForcedCommand);
    });
  }

  int _successDelayMs({required bool wasSurge, required bool wasRedline}) {
    if (_isChain) return 70;
    if (_isSurge && _surgeRemaining > 0) return wasSurge ? 90 : 220;
    if (_isRedline && wasRedline) return 180;
    return _timing.successDelayMsForScore(_score);
  }

  void _miss() {
    if (!_acceptingInput || _finished) return;
    _commandTimer?.cancel();
    _obscureTimer?.cancel();
    _commandClock.stop();
    _commandTracker.recordMiss(_command);
    _game.triggerMiss();
    _currentStreak = 0;
    unawaited(ReactAudio.play(ReactSoundCue.miss));
    setState(() {
      _acceptingInput = false;
      _misses += 1;
      _feedback = 'MISS';
    });
    _nextTimer?.cancel();
    _pendingNextCommand = false;
    _pendingForcedCommand = null;
    _pendingFinishAfterMiss = true;
    _nextTimer = Timer(const Duration(milliseconds: 320), () {
      if (!mounted || _paused || _finished) return;
      _nextTimer = null;
      _pendingFinishAfterMiss = false;
      _finish(ReactRunOutcome.missedCommand);
    });
  }

  void _syncFlameIntensity() {
    var intensity = (.30 + _score * .010).clamp(.30, .88).toDouble();
    if (_surgeCommand) intensity = .96;
    if (_redlineCommand) intensity = 1.0;
    if (_isChain) intensity = max(intensity, .62);
    _game.setIntensity(intensity);
  }

  void _clearPendingTransition() {
    _nextTimer?.cancel();
    _nextTimer = null;
    _pendingForcedCommand = null;
    _pendingNextCommand = false;
    _pendingFinishAfterMiss = false;
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;
    if (value) {
      _pausedRemainingMs = _acceptingInput ? max(1, _commandRemainingMs) : 0;
      _commandClock.stop();
      _commandTimer?.cancel();
      _obscureTimer?.cancel();
      _nextTimer?.cancel();
      _nextTimer = null;
      _game.pauseEngine();
      setState(() {
        _paused = true;
        _acceptingInput = false;
      });
      return;
    }

    _game.resumeEngine();
    setState(() => _paused = false);
    if (_pausedRemainingMs > 0) {
      final remaining = _pausedRemainingMs;
      _pausedRemainingMs = 0;
      _armCommandTimer(remaining);
      return;
    }
    if (_pendingFinishAfterMiss) {
      _pendingFinishAfterMiss = false;
      _finish(ReactRunOutcome.missedCommand);
      return;
    }
    if (_pendingNextCommand) {
      final forced = _pendingForcedCommand;
      _pendingNextCommand = false;
      _pendingForcedCommand = null;
      _startCommand(forced: forced);
      return;
    }
    _startCommand();
  }

  void _quit() {
    if (_finished || !mounted) return;
    _finished = true;
    _commandTimer?.cancel();
    _clearPendingTransition();
    _obscureTimer?.cancel();
    _game.pauseEngine();
    Navigator.of(context).pop();
  }

  void _finish(ReactRunOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    _acceptingInput = false;
    _commandTimer?.cancel();
    _clearPendingTransition();
    _obscureTimer?.cancel();

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
            maxStreak: _maxStreak,
            failedCommand:
                outcome == ReactRunOutcome.missedCommand ? _command : null,
            dailyDate: _challenge.date,
            dailyModifierLabel: _modifier.label,
            dailyModifierRule: _modifier.shortRule,
            isDailyDevRun: _isDailyDevRun,
            commandPerformance: _commandTracker.snapshot(),
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
    final palette = ReactCosmetics.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_finished && !_paused) _setPaused(true);
      },
      child: Scaffold(
        backgroundColor: palette.background,
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
                        _DailyHeader(
                          score: _score,
                          modifier: _modifier,
                          onPause: () => _setPaused(true),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: ReactGestureSurface(
                              key: ValueKey<int>(_commandSerial),
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
                                  color: _feedback == 'MISS' ||
                                          _feedback == 'REDLINE'
                                      ? palette.failure
                                      : palette.primary,
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

Color _dailyPanelColor() => switch (ReactCosmetics.currentTheme) {
  ReactVisualTheme.core => const Color(0xFF07111D),
  ReactVisualTheme.redline => const Color(0xFF14080B),
  ReactVisualTheme.synthwave => const Color(0xFF0D0920),
  ReactVisualTheme.mono => const Color(0xFF0A0A0A),
};

Color _dailyArenaSurfaceColor() => switch (ReactCosmetics.currentTheme) {
  ReactVisualTheme.core => const Color(0xFF050A13),
  ReactVisualTheme.redline => const Color(0xFF100609),
  ReactVisualTheme.synthwave => const Color(0xFF090718),
  ReactVisualTheme.mono => const Color(0xFF050505),
};

Color _dailyBorderColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF243A57)
    : ReactCosmetics.palette.primary.withValues(alpha: .38);

Color _dailyInnerBorderColor() =>
    ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF153B65)
    : ReactCosmetics.palette.primary.withValues(alpha: .44);

Color _dailyRingBaseColor() => ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF122038)
    : ReactCosmetics.palette.primary.withValues(alpha: .16);

Color _dailyTimerTrackColor() =>
    ReactCosmetics.currentTheme == ReactVisualTheme.core
    ? const Color(0xFF10243D)
    : ReactCosmetics.palette.primary.withValues(alpha: .20);

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
    final palette = ReactCosmetics.palette;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPause,
              style: IconButton.styleFrom(
                backgroundColor: _dailyPanelColor(),
                foregroundColor: ReactColors.textPrimary,
                side: BorderSide(color: _dailyBorderColor()),
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
                color: palette.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HudCard(
                label: 'RULE',
                value: modifier.label,
                color: palette.primary,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HudCard(
                label: 'MISS LIMIT',
                value: '1',
                color: palette.failure,
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
        color: _dailyPanelColor(),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _dailyBorderColor()),
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
    final palette = ReactCosmetics.palette;
    final seconds = (commandDurationMs * progress / 1000).clamp(0, 9.9);
    final accent = redline ? palette.failure : palette.primary;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!hideClock)
            CustomPaint(
              size: Size.square(size),
              painter: _DailyRingPainter(progress: progress, accent: accent),
            ),
          Container(
            width: size * .69,
            height: size * .69,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dailyArenaSurfaceColor(),
              border: Border.all(color: _dailyInnerBorderColor(), width: 1.5),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: obscureCommand ? 0 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (reverse && command.name.startsWith('swipe'))
                    Text(
                      'DO THE OPPOSITE',
                      style: TextStyle(
                        color: palette.failure,
                        fontSize: 9,
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
                      fontSize: 9,
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
                  color: _dailyPanelColor(),
                  border: Border.all(color: _dailyBorderColor(), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      seconds.toStringAsFixed(2),
                      style: TextStyle(
                        color: progress < .2 ? palette.failure : accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'SEC',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 9,
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
  const _DailyRingPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = ReactCosmetics.palette;
    final center = size.center(Offset.zero);
    final radius = size.width * .44;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = _dailyRingBaseColor();
    canvas.drawCircle(center, radius, base);

    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    deco.color = palette.primary.withValues(alpha: .72);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      .8,
      1.45,
      false,
      deco,
    );
    deco.color = palette.secondary.withValues(alpha: .72);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.0,
      1.25,
      false,
      deco,
    );
    deco.color = palette.failure.withValues(alpha: .72);
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
      ..color = _dailyTimerTrackColor();
    canvas.drawCircle(center, timerRadius, track);

    final timer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = progress < .18 ? palette.failure : accent;
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
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _DailyBottomBar extends StatelessWidget {
  const _DailyBottomBar({
    required this.score,
    required this.averageTimeSeconds,
  });

  final int score;
  final double averageTimeSeconds;

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _dailyPanelColor(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _dailyBorderColor()),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: palette.primary,
            size: 21,
          ),
          const SizedBox(width: 8),
          Text(
            'DAILY',
            style: TextStyle(
              color: palette.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            '$score CLEARS',
            style: TextStyle(
              color: palette.secondary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 18),
          Text(
            averageTimeSeconds == 0
                ? '--'
                : '${averageTimeSeconds.toStringAsFixed(2)}s',
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
    final palette = ReactCosmetics.palette;
    return ColoredBox(
      color: const Color(0xE6050911),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _dailyPanelColor(),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _dailyBorderColor()),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_outline_rounded,
                color: palette.primary,
                size: 52,
              ),
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
                  fontSize: 9,
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
