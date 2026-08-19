import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/presentation/react_gesture_surface.dart';
import '../data/local_variant_mode_stats.dart';
import '../domain/react_variant_mode.dart';

class EnhancedVariantRunScreen extends StatefulWidget {
  const EnhancedVariantRunScreen({required this.mode, super.key});

  final ReactVariantMode mode;

  @override
  State<EnhancedVariantRunScreen> createState() => _EnhancedVariantRunScreenState();
}

class _EnhancedVariantRunScreenState extends State<EnhancedVariantRunScreen> {
  static const _tick = Duration(milliseconds: 32);

  final Random _random = Random();
  final Stopwatch _roundClock = Stopwatch();

  Timer? _ticker;
  Timer? _phaseTimer;
  Timer? _countdownTimer;

  ReactCommand _command = ReactCommand.tap;
  ReactCommand _decoyCommand = ReactCommand.hold;

  int _countdown = 3;
  int _score = 0;
  int _lives = 3;
  int _streak = 0;
  int _maxStreak = 0;
  int _roundDurationMs = 2400;
  int _illusionEffect = 0;
  int _tempestRule = 0;
  int _memoryInput = 0;
  int _memoryFlash = -1;

  double _progress = 1;

  bool _running = false;
  bool _finished = false;
  bool _accepting = false;
  bool _go = false;
  bool _decoy = false;
  bool _memoryPlaying = false;

  String? _feedback;
  List<int> _memorySequence = <int>[];

  ReactVariantMode get mode => widget.mode;
  Color get _accent => mode.color;

  bool get _isMemory => mode == ReactVariantMode.memory;
  bool get _isGlitch => mode == ReactVariantMode.glitch;
  bool get _isTempest => mode == ReactVariantMode.tempest;
  bool get _isIllusion => mode == ReactVariantMode.illusion;

  int get _remainingMs => max(
        0,
        _roundDurationMs - _roundClock.elapsedMilliseconds,
      );

  bool get _beatOpen {
    if (!_roundClock.isRunning) return false;
    final phase = _roundClock.elapsedMilliseconds % 900;
    return phase >= 560 && phase <= 760;
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _roundClock.stop();
    super.dispose();
  }

  void _startCountdown() {
    unawaited(ReactAudio.play(ReactSoundCue.countdownTick));
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _finished) return;
      if (_countdown > 1) {
        setState(() => _countdown -= 1);
        unawaited(ReactAudio.play(ReactSoundCue.countdownTick));
        return;
      }
      if (!_go) {
        setState(() => _go = true);
        unawaited(ReactAudio.play(ReactSoundCue.countdownGo));
        return;
      }
      _countdownTimer?.cancel();
      _beginRun();
    });
  }

  void _beginRun() {
    if (!mounted || _finished) return;
    setState(() => _running = true);
    _ticker = Timer.periodic(_tick, _onTick);
    if (_isMemory) {
      _memorySequence = <int>[_random.nextInt(4)];
      _startMemoryPlayback();
    } else {
      _startCommandRound();
    }
  }

  void _onTick(Timer timer) {
    if (!mounted || _finished || !_running) return;
    if (_accepting && _roundClock.isRunning) {
      if (_remainingMs <= 0) {
        _fail('TOO SLOW');
        return;
      }
      setState(() => _progress = _remainingMs / max(1, _roundDurationMs));
    } else if (_isIllusion && _roundClock.isRunning) {
      setState(() {});
    }
  }

  ReactCommand _randomCommand() {
    final values = ReactCommand.values;
    return values[_random.nextInt(values.length)];
  }

  bool _isSwipe(ReactCommand command) =>
      command == ReactCommand.swipeLeft ||
      command == ReactCommand.swipeRight ||
      command == ReactCommand.swipeUp ||
      command == ReactCommand.swipeDown;

  ReactCommand _opposite(ReactCommand command) => switch (command) {
        ReactCommand.swipeLeft => ReactCommand.swipeRight,
        ReactCommand.swipeRight => ReactCommand.swipeLeft,
        ReactCommand.swipeUp => ReactCommand.swipeDown,
        ReactCommand.swipeDown => ReactCommand.swipeUp,
        _ => command,
      };

  ReactCommand get _expectedCommand {
    if (_isTempest && _tempestRule == 2) return _opposite(_command);
    return _command;
  }

  void _startCommandRound() {
    if (!mounted || _finished) return;
    _phaseTimer?.cancel();
    _decoy = false;

    var next = _randomCommand();
    if (_isTempest && _tempestRule == 2 && !_isSwipe(next)) {
      final swipes = <ReactCommand>[
        ReactCommand.swipeLeft,
        ReactCommand.swipeRight,
        ReactCommand.swipeUp,
        ReactCommand.swipeDown,
      ];
      next = swipes[_random.nextInt(swipes.length)];
    }
    _command = next;

    if (_isIllusion) {
      _illusionEffect = _random.nextInt(5);
    }
    if (_isTempest && _score % 4 == 0) {
      _tempestRule = (_score ~/ 4) % 4;
    }

    if (_isGlitch && _score.isOdd) {
      _decoyCommand = _randomCommand();
      while (_decoyCommand == _command) {
        _decoyCommand = _randomCommand();
      }
      setState(() {
        _decoy = true;
        _accepting = false;
        _feedback = 'FAKE';
      });
      _phaseTimer = Timer(const Duration(milliseconds: 620), () {
        if (!mounted || _finished) return;
        setState(() {
          _decoy = false;
          _feedback = 'LIVE';
        });
        _armRound(_durationForRound());
      });
      return;
    }

    _feedback = _isGlitch ? 'LIVE' : null;
    _armRound(_durationForRound());
  }

  int _durationForRound() {
    if (_isTempest && _tempestRule == 0) return 1450;
    return max(1150, 2450 - _score * 26);
  }

  void _armRound(int durationMs) {
    _roundDurationMs = durationMs;
    _progress = 1;
    _roundClock
      ..reset()
      ..start();
    setState(() => _accepting = true);
    unawaited(ReactAudio.play(ReactSoundCue.command));
  }

  void _handleCommand(ReactCommand performed) {
    if (!_accepting || _finished) return;
    if (_isTempest && _tempestRule == 3 && !_beatOpen) {
      _fail('OFF PULSE');
      return;
    }
    if (performed != _expectedCommand) {
      _fail('WRONG INPUT');
      return;
    }
    _completeCommand();
  }

  void _completeCommand() {
    _roundClock.stop();
    _accepting = false;
    _score += 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);
    unawaited(ReactAudio.play(ReactSoundCue.success));
    setState(() => _feedback = '+1 CLEAR');
    _phaseTimer = Timer(const Duration(milliseconds: 170), () {
      if (mounted && !_finished) _startCommandRound();
    });
  }

  void _fail(String reason) {
    if (_finished || !_running) return;
    _roundClock.stop();
    _accepting = false;
    _streak = 0;
    _lives -= 1;
    unawaited(ReactAudio.play(ReactSoundCue.lifeLost));
    if (_lives <= 0) {
      _finish(reason);
      return;
    }
    setState(() => _feedback = '$reason  •  $_lives LIVES');
    _phaseTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted || _finished) return;
      if (_isMemory) {
        _memorySequence = <int>[_random.nextInt(4)];
        _startMemoryPlayback();
      } else {
        _startCommandRound();
      }
    });
  }

  void _startMemoryPlayback() {
    _phaseTimer?.cancel();
    _roundClock.stop();
    setState(() {
      _memoryPlaying = true;
      _accepting = false;
      _memoryInput = 0;
      _memoryFlash = -1;
      _feedback = 'WATCH';
    });
    _playMemoryStep(0);
  }

  void _playMemoryStep(int index) {
    if (!mounted || _finished) return;
    if (index >= _memorySequence.length) {
      setState(() {
        _memoryPlaying = false;
        _memoryFlash = -1;
        _feedback = 'YOUR TURN';
      });
      _armRound(max(3200, _memorySequence.length * 1200));
      return;
    }

    setState(() => _memoryFlash = _memorySequence[index]);
    unawaited(ReactAudio.play(ReactSoundCue.command));
    _phaseTimer = Timer(const Duration(milliseconds: 420), () {
      if (!mounted || _finished) return;
      setState(() => _memoryFlash = -1);
      _phaseTimer = Timer(const Duration(milliseconds: 190), () {
        _playMemoryStep(index + 1);
      });
    });
  }

  void _tapMemory(int index) {
    if (_memoryPlaying || !_accepting || _finished) return;
    if (index != _memorySequence[_memoryInput]) {
      _fail('SEQUENCE BROKEN');
      return;
    }

    _memoryInput += 1;
    if (_memoryInput < _memorySequence.length) {
      setState(() => _feedback = '$_memoryInput/${_memorySequence.length}');
      return;
    }

    _roundClock.stop();
    _accepting = false;
    _score += 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);
    _memorySequence.add(_random.nextInt(4));
    unawaited(ReactAudio.play(ReactSoundCue.success));
    setState(() => _feedback = 'CHAIN +1');
    _phaseTimer = Timer(const Duration(milliseconds: 620), () {
      if (mounted && !_finished) _startMemoryPlayback();
    });
  }

  Future<void> _finish(String reason) async {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _roundClock.stop();
    unawaited(ReactAudio.play(ReactSoundCue.completed));
    final newBest = await LocalVariantModeStats.record(mode, _score);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _EnhancedResultScreen(
          mode: mode,
          score: _score,
          maxStreak: _maxStreak,
          reason: reason,
          newBest: newBest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  _Header(
                    mode: mode,
                    score: _score,
                    lives: _lives,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 12),
                  if (_isTempest) _TempestBanner(rule: _tempestRule),
                  if (_isGlitch)
                    _GlitchBanner(
                      fake: _decoy,
                      active: _running,
                    ),
                  if (_isTempest || _isGlitch) const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: _isMemory
                          ? _buildMemoryArena()
                          : _buildCommandArena(),
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: Center(
                      child: Text(
                        _feedback ?? '',
                        style: TextStyle(
                          color: _feedbackColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: _accent.withValues(alpha: .10),
                      valueColor: AlwaysStoppedAnimation<Color>(_accent),
                    ),
                  ),
                ],
              ),
            ),
            if (!_running)
              _CountdownOverlay(
                mode: mode,
                count: _countdown,
                go: _go,
              ),
          ],
        ),
      ),
    );
  }

  Color get _feedbackColor {
    if (_isGlitch && _decoy) return ReactColors.coral;
    if (_isGlitch && _feedback == 'LIVE') return ReactColors.lime;
    if ((_feedback ?? '').contains('WRONG') ||
        (_feedback ?? '').contains('BROKEN') ||
        (_feedback ?? '').contains('SLOW')) {
      return ReactColors.coral;
    }
    return _accent;
  }

  Widget _buildCommandArena() {
    final shownCommand = _decoy ? _decoyCommand : _command;
    final activeColor = _isGlitch
        ? (_decoy ? ReactColors.coral : ReactColors.lime)
        : _isTempest
            ? _tempestColor(_tempestRule)
            : _accent;

    Widget face = _CommandFace(
      command: shownCommand,
      color: activeColor,
      hidden: _isTempest &&
          _tempestRule == 1 &&
          _roundClock.isRunning &&
          (_roundClock.elapsedMilliseconds % 700) > 280,
      pulseOpen: _isTempest && _tempestRule == 3 && _beatOpen,
    );

    if (_isIllusion) {
      final t = _roundClock.elapsedMilliseconds / 1000;
      face = switch (_illusionEffect) {
        0 => Transform.rotate(angle: t * pi * 1.7, child: face),
        1 => Opacity(
            opacity: (sin(t * 13) > -.15) ? 1 : .08,
            child: face,
          ),
        2 => Transform.scale(
            scale: .72 + ((sin(t * 8) + 1) / 2) * .70,
            child: face,
          ),
        3 => Transform.translate(
            offset: Offset(sin(t * 7) * 72, cos(t * 5) * 54),
            child: face,
          ),
        _ => Transform.rotate(
            angle: sin(t * 6) * .65,
            child: Transform.flip(
              flipX: sin(t * 4) > 0,
              child: face,
            ),
          ),
      };
    }

    return SizedBox.square(
      dimension: 330,
      child: ReactGestureSurface(
        enabled: _accepting && !_decoy,
        expectedCommand: _expectedCommand,
        onCommand: _handleCommand,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF050A13),
            border: Border.all(
              color: activeColor,
              width: _isTempest && _tempestRule == 3 && _beatOpen ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: .18),
                blurRadius: 30,
              ),
            ],
          ),
          child: face,
        ),
      ),
    );
  }

  Widget _buildMemoryArena() {
    const padColors = <Color>[
      ReactColors.electricBlueBright,
      ReactColors.lime,
      ReactColors.purple,
      ReactColors.coral,
    ];

    return Container(
      width: 340,
      height: 340,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF050A13),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: _accent.withValues(alpha: .46), width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final lit = index == _memoryFlash;
          final color = padColors[index];
          return GestureDetector(
            onTap: () => _tapMemory(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: lit
                    ? color.withValues(alpha: .42)
                    : color.withValues(alpha: .055),
                border: Border.all(
                  color: lit ? Colors.white : color.withValues(alpha: .58),
                  width: lit ? 4 : 1.6,
                ),
                boxShadow: lit
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: .55),
                          blurRadius: 34,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: lit ? Colors.white : color,
                        fontSize: lit ? 48 : 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.score,
    required this.lives,
    required this.onBack,
  });

  final ReactVariantMode mode;
  final int score;
  final int lives;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: ReactColors.textPrimary,
              side: BorderSide(color: mode.color.withValues(alpha: .35)),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mode.title,
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          _Metric(label: 'SCORE', value: '$score', color: mode.color),
          const SizedBox(width: 8),
          _Metric(
            label: 'LIVES',
            value: List<String>.filled(lives, '♥').join(),
            color: ReactColors.coral,
          ),
        ],
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 62),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Column(
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
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _CommandFace extends StatelessWidget {
  const _CommandFace({
    required this.command,
    required this.color,
    required this.hidden,
    required this.pulseOpen,
  });

  final ReactCommand command;
  final Color color;
  final bool hidden;
  final bool pulseOpen;

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return Center(
        child: Icon(
          Icons.visibility_off_rounded,
          color: color.withValues(alpha: .30),
          size: 64,
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            command.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Icon(command.icon, color: color, size: 90),
          const SizedBox(height: 14),
          Text(
            command.hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          if (pulseOpen) ...[
            const SizedBox(height: 12),
            Text(
              'NOW',
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlitchBanner extends StatelessWidget {
  const _GlitchBanner({required this.fake, required this.active});

  final bool fake;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = fake ? ReactColors.coral : ReactColors.lime;
    final label = !active ? 'READY' : fake ? 'FAKE' : 'LIVE';
    final icon = fake ? Icons.block_rounded : Icons.bolt_rounded;
    return _StateBanner(label: label, icon: icon, color: color);
  }
}

class _TempestBanner extends StatelessWidget {
  const _TempestBanner({required this.rule});

  final int rule;

  @override
  Widget build(BuildContext context) {
    final label = switch (rule) {
      0 => 'SPEED',
      1 => 'BLACKOUT',
      2 => 'REVERSE',
      _ => 'PULSE',
    };
    final icon = switch (rule) {
      0 => Icons.speed_rounded,
      1 => Icons.visibility_off_rounded,
      2 => Icons.swap_horiz_rounded,
      _ => Icons.monitor_heart_rounded,
    };
    return _StateBanner(label: label, icon: icon, color: _tempestColor(rule));
  }
}

class _StateBanner extends StatelessWidget {
  const _StateBanner({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .16), blurRadius: 18),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
}

Color _tempestColor(int rule) => switch (rule) {
      0 => ReactColors.coral,
      1 => ReactColors.purple,
      2 => const Color(0xFFFFD33D),
      _ => ReactColors.electricBlueBright,
    };

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({
    required this.mode,
    required this.count,
    required this.go,
  });

  final ReactVariantMode mode;
  final int count;
  final bool go;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: ColoredBox(
          color: ReactColors.background.withValues(alpha: .96),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mode.title,
                  style: TextStyle(
                    color: mode.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  go ? 'GO' : '$count',
                  style: TextStyle(
                    color: go ? mode.color : ReactColors.textPrimary,
                    fontSize: go ? 86 : 112,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EnhancedResultScreen extends StatelessWidget {
  const _EnhancedResultScreen({
    required this.mode,
    required this.score,
    required this.maxStreak,
    required this.reason,
    required this.newBest,
  });

  final ReactVariantMode mode;
  final int score;
  final int maxStreak;
  final String reason;
  final bool newBest;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ReactColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Spacer(),
                Icon(mode.icon, color: mode.color, size: 64),
                const SizedBox(height: 12),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 92,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  newBest ? 'NEW BEST' : 'FINAL SCORE',
                  style: TextStyle(
                    color: newBest ? ReactColors.lime : ReactColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'MAX STREAK  $maxStreak',
                  style: TextStyle(
                    color: mode.color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => EnhancedVariantRunScreen(mode: mode),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: mode.color,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('BACK TO MODE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
