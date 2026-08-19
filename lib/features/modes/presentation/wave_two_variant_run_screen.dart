import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/presentation/react_gesture_surface.dart';
import '../data/local_variant_mode_stats.dart';
import '../domain/react_variant_mode.dart';

class WaveTwoVariantRunScreen extends StatefulWidget {
  const WaveTwoVariantRunScreen({required this.mode, super.key});

  final ReactVariantMode mode;

  @override
  State<WaveTwoVariantRunScreen> createState() => _WaveTwoVariantRunScreenState();
}

class _WaveTwoVariantRunScreenState extends State<WaveTwoVariantRunScreen> {
  static const _tick = Duration(milliseconds: 32);
  static const _orange = Color(0xFFFF8A35);

  final Random _random = Random();

  Timer? _ticker;
  Timer? _countdownTimer;
  Timer? _phaseTimer;
  final Stopwatch _clock = Stopwatch();

  int _countdown = 3;
  int _score = 0;
  int _lives = 3;
  int _roundMs = 2400;
  int _volleyRemaining = 0;
  int _breakerLayer = 0;
  int _activeSide = 0;
  int _activeLane = 0;
  int _activeTile = 0;
  int _memoryInput = 0;
  int _memoryFlash = -1;
  int _catalystState = 0;
  int _rampartDamage = 0;

  double _heat = 0;
  double _frost = 0;
  double _momentum = 0;
  double _progress = 1;

  bool _go = false;
  bool _running = false;
  bool _accepting = false;
  bool _finished = false;
  bool _newBest = false;
  bool _ghost = false;
  bool _memoryPlaying = false;
  bool _harpoonDragging = false;
  bool _anchorHeld = false;
  int? _anchorPointer;
  int? _harpoonPointer;

  String _feedback = '';
  ReactCommand _command = ReactCommand.tap;
  Offset _target = const Offset(.5, .5);
  Offset _secondary = const Offset(.25, .25);
  Offset _harpoonDrag = const Offset(.5, .5);
  List<int> _memorySequence = <int>[];
  List<double> _gridCharge = List<double>.filled(9, 0);
  List<int> _blockedLanes = const <int>[];
  List<Offset> _fragments = const <Offset>[];

  ReactVariantMode get mode => widget.mode;
  Color get accent => mode.color;
  int get elapsedMs => _clock.elapsedMilliseconds;
  int get remainingMs => max(0, _roundMs - elapsedMs);
  double get phase => _roundMs <= 0 ? 0 : (elapsedMs / _roundMs).clamp(0.0, 1.0);

  bool get _isWaveTwo => mode.index >= ReactVariantMode.harpoon.index;

  @override
  void initState() {
    super.initState();
    assert(_isWaveTwo);
    _startCountdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _countdownTimer?.cancel();
    _phaseTimer?.cancel();
    _clock.stop();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _finished) return;
      if (_countdown > 1) {
        setState(() => _countdown -= 1);
      } else if (!_go) {
        setState(() => _go = true);
      } else {
        _countdownTimer?.cancel();
        _begin();
      }
    });
  }

  void _begin() {
    if (!mounted) return;
    setState(() => _running = true);
    _ticker = Timer.periodic(_tick, _onTick);
    if (mode == ReactVariantMode.rewind) {
      _memorySequence = <int>[_random.nextInt(4), _random.nextInt(4)];
      _startMemoryPlayback();
    } else {
      _startRound();
    }
  }

  void _onTick(Timer timer) {
    if (!mounted || !_running || _finished) return;

    if (mode == ReactVariantMode.crucible && _accepting) {
      _heat += .0038 + (_score * .000035);
      if (_heat >= 1) {
        _finish('OVERHEATED');
        return;
      }
    }
    if (mode == ReactVariantMode.frostline && _accepting) {
      _frost += .0027 + (_score * .00002);
      if (_frost >= 1) {
        _finish('FROZEN OUT');
        return;
      }
    }
    if (mode == ReactVariantMode.sparkgrid) {
      for (var i = 0; i < _gridCharge.length; i++) {
        _gridCharge[i] = min(1.15, _gridCharge[i] + .003 + i * .00008);
      }
      if (_gridCharge.where((value) => value >= 1).length >= 3) {
        _finish('GRID OVERLOAD');
        return;
      }
    }
    if (mode == ReactVariantMode.rampart && _accepting) {
      if (remainingMs <= 0) {
        _rampartDamage += 1;
        if (_rampartDamage >= 3) {
          _finish('RAMPART BROKEN');
          return;
        }
        _fail('SHIELD BROKE', loseLife: false);
        return;
      }
    } else if (_accepting && _clock.isRunning && remainingMs <= 0) {
      _fail('TOO SLOW');
      return;
    }

    if (_accepting && _clock.isRunning) {
      _progress = (remainingMs / max(1, _roundMs)).clamp(0.0, 1.0);
    }
    setState(() {});
  }

  ReactCommand _randomCommand() {
    final values = ReactCommand.values;
    return values[_random.nextInt(values.length)];
  }

  int _durationForMode() {
    final base = switch (mode) {
      ReactVariantMode.barrage => max(1050, 1700 - _score * 22),
      ReactVariantMode.thruster => max(900, 2250 - (_momentum * 950).round()),
      ReactVariantMode.hush || ReactVariantMode.fadeout => 2600,
      ReactVariantMode.crucible || ReactVariantMode.frostline => 3000,
      ReactVariantMode.dualcast => 2300,
      ReactVariantMode.sparkgrid => 999999,
      ReactVariantMode.rampart => max(1250, 2500 - _score * 25),
      _ => max(1200, 2500 - _score * 18),
    };
    return base;
  }

  void _startRound() {
    if (!mounted || _finished) return;
    _phaseTimer?.cancel();
    _command = _randomCommand();
    _roundMs = _durationForMode();
    _progress = 1;
    _feedback = '';
    _activeSide = _random.nextInt(2);
    _activeLane = _random.nextInt(3);
    _activeTile = _random.nextInt(9);
    _target = Offset(.12 + _random.nextDouble() * .76, .12 + _random.nextDouble() * .76);
    _secondary = Offset(.15 + _random.nextDouble() * .70, .15 + _random.nextDouble() * .70);
    _harpoonDrag = _target;
    _ghost = _random.nextBool();
    _blockedLanes = <int>{
      _random.nextInt(3),
      if (_score > 8) _random.nextInt(3),
    }.where((lane) => lane != _activeLane).toList(growable: false);
    _fragments = List<Offset>.generate(
      min(6, 3 + _score ~/ 5),
      (_) => Offset(.12 + _random.nextDouble() * .76, .18 + _random.nextDouble() * .64),
      growable: false,
    );
    if (mode == ReactVariantMode.barrage && _volleyRemaining <= 0) {
      _volleyRemaining = min(6, 3 + _score ~/ 7);
    }
    if (mode == ReactVariantMode.breaker) _breakerLayer = 0;
    if (mode == ReactVariantMode.sparkgrid) {
      _clock.stop();
      setState(() => _accepting = true);
      return;
    }
    _clock
      ..reset()
      ..start();
    setState(() => _accepting = true);
  }

  void _complete({int points = 1}) {
    if (_finished || !_accepting) return;
    final reaction = elapsedMs;
    _clock.stop();
    _accepting = false;
    _score += points;

    if (mode == ReactVariantMode.crucible) {
      _heat = max(0, _heat - (reaction < 900 ? .30 : .16));
    }
    if (mode == ReactVariantMode.frostline) {
      _frost = max(0, _frost - (reaction < 900 ? .26 : .10));
    }
    if (mode == ReactVariantMode.thruster) {
      _momentum = min(1, _momentum + .10);
    }
    if (mode == ReactVariantMode.catalyst) {
      _catalystState = reaction < 700 ? 1 + _random.nextInt(4) : 0;
    }
    if (mode == ReactVariantMode.barrage) {
      _volleyRemaining -= 1;
    }

    _feedback = '+$points';
    final recovery = mode == ReactVariantMode.barrage && _volleyRemaining > 0
        ? const Duration(milliseconds: 90)
        : const Duration(milliseconds: 250);
    if (mode == ReactVariantMode.barrage && _volleyRemaining <= 0) {
      _volleyRemaining = 0;
    }
    _phaseTimer = Timer(recovery, () {
      if (mounted && !_finished) _startRound();
    });
    setState(() {});
  }

  void _fail(String reason, {bool loseLife = true}) {
    if (_finished || !_accepting) return;
    _clock.stop();
    _accepting = false;
    if (loseLife) _lives -= 1;
    if (mode == ReactVariantMode.thruster) _momentum = max(0, _momentum - .35);
    _feedback = reason;
    if (_lives <= 0) {
      _finish(reason);
      return;
    }
    _phaseTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted || _finished) return;
      if (mode == ReactVariantMode.rewind) {
        _startMemoryPlayback();
      } else {
        _startRound();
      }
    });
    setState(() {});
  }

  Future<void> _finish(String reason) async {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    _phaseTimer?.cancel();
    _clock.stop();
    final best = await LocalVariantModeStats.record(mode, _score);
    if (!mounted) return;
    setState(() {
      _newBest = best;
      _feedback = reason;
    });
  }

  void _restart() {
    _ticker?.cancel();
    _phaseTimer?.cancel();
    _clock.stop();
    setState(() {
      _countdown = 3;
      _score = 0;
      _lives = 3;
      _roundMs = 2400;
      _volleyRemaining = 0;
      _breakerLayer = 0;
      _heat = 0;
      _frost = 0;
      _momentum = 0;
      _progress = 1;
      _go = false;
      _running = false;
      _accepting = false;
      _finished = false;
      _newBest = false;
      _feedback = '';
      _catalystState = 0;
      _rampartDamage = 0;
      _gridCharge = List<double>.filled(9, 0);
    });
    _startCountdown();
  }

  bool _timingWindow() {
    final p = phase;
    return switch (mode) {
      ReactVariantMode.sentry => p >= .46 && p <= .59,
      ReactVariantMode.shockwave => p >= .72 && p <= .84,
      ReactVariantMode.gateline => p >= .44 && p <= .57,
      ReactVariantMode.parallax => p >= .47 && p <= .58,
      ReactVariantMode.pendulum => p >= .46 && p <= .56,
      ReactVariantMode.phaseshift => !_ghost,
      ReactVariantMode.waveline => p >= .44 && p <= .58,
      ReactVariantMode.splice => p >= .55 && p <= .82,
      _ => true,
    };
  }

  ReactCommand _expectedCommand() {
    if (mode == ReactVariantMode.catalyst && _catalystState == 3) {
      return switch (_command) {
        ReactCommand.swipeLeft => ReactCommand.swipeRight,
        ReactCommand.swipeRight => ReactCommand.swipeLeft,
        ReactCommand.swipeUp => ReactCommand.swipeDown,
        ReactCommand.swipeDown => ReactCommand.swipeUp,
        _ => _command,
      };
    }
    return _command;
  }

  void _handleCommand(ReactCommand performed) {
    if (!_accepting || _finished) return;
    if (!_timingWindow()) {
      _fail(mode == ReactVariantMode.phaseshift ? 'GHOST PHASE' : 'OUTSIDE WINDOW');
      return;
    }
    if (performed != _expectedCommand()) {
      _fail('WRONG INPUT');
      return;
    }
    _complete();
  }

  void _tapTimingArena() {
    if (!_accepting) return;
    if (_timingWindow()) {
      _complete();
    } else {
      _fail('MIS-TIMED');
    }
  }

  void _tapGrid(int index) {
    if (!_accepting) return;
    if (mode == ReactVariantMode.sparkgrid) {
      if (_gridCharge[index] >= .72) {
        final points = _gridCharge[index] >= .95 ? 2 : 1;
        _gridCharge[index] = 0;
        _score += points;
        _feedback = '+$points DISCHARGE';
        setState(() {});
      } else {
        _lives -= 1;
        _feedback = 'NOT CHARGED';
        if (_lives <= 0) _finish('GRID FAILED');
        setState(() {});
      }
      return;
    }
    if (mode == ReactVariantMode.rampart) {
      if (index == _activeTile) {
        _complete();
      } else {
        _fail('WRONG ZONE');
      }
    }
  }

  void _startMemoryPlayback() {
    _phaseTimer?.cancel();
    _clock.stop();
    setState(() {
      _memoryPlaying = true;
      _memoryInput = 0;
      _memoryFlash = -1;
      _accepting = false;
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
        _accepting = true;
        _feedback = 'REWIND IT';
        _roundMs = max(2800, _memorySequence.length * 1150);
      });
      _clock
        ..reset()
        ..start();
      return;
    }
    setState(() => _memoryFlash = _memorySequence[index]);
    _phaseTimer = Timer(const Duration(milliseconds: 410), () {
      if (!mounted || _finished) return;
      setState(() => _memoryFlash = -1);
      _phaseTimer = Timer(
        const Duration(milliseconds: 170),
        () => _playMemoryStep(index + 1),
      );
    });
  }

  void _tapMemory(int index) {
    if (_memoryPlaying || !_accepting) return;
    final reverseIndex = _memorySequence.length - 1 - _memoryInput;
    if (index != _memorySequence[reverseIndex]) {
      _fail('WRONG REWIND');
      return;
    }
    _memoryInput += 1;
    if (_memoryInput >= _memorySequence.length) {
      _clock.stop();
      _accepting = false;
      _score += 1;
      _memorySequence.add(_random.nextInt(4));
      _feedback = 'REWIND +1';
      _phaseTimer = Timer(const Duration(milliseconds: 520), () {
        if (mounted && !_finished) _startMemoryPlayback();
      });
    } else {
      setState(() => _feedback = '$_memoryInput/${_memorySequence.length}');
    }
  }

  Offset _movingTarget() {
    final p = phase;
    return switch (mode) {
      ReactVariantMode.railrun => Offset(.06 + p * .88, .25 + _activeLane * .25),
      ReactVariantMode.skyhook => Offset(_target.dx, .05 + p * .9),
      ReactVariantMode.corridor => Offset(
          .5 + sin(p * pi * 2 + _target.dx * 5) * (.30 * (1 - p)),
          .08 + p * .84,
        ),
      ReactVariantMode.sidewinder => Offset(
          .05 + p * .90,
          .5 + sin((p * (3 + _target.dx * 4)) * pi * 2) * (.18 + _target.dy * .12),
        ),
      ReactVariantMode.hinge => Offset(
          .5 + cos(p * pi * 5) * .33,
          .5 + sin(p * pi * 5) * .33,
        ),
      ReactVariantMode.monoline => Offset(
          .08 + p * .84,
          .5 + sin(p * pi * 2 + _target.dy * 5) * .23,
        ),
      ReactVariantMode.riftstep => Offset(
          _activeSide == 0 ? .25 : .75,
          .20 + _target.dy * .60,
        ),
      ReactVariantMode.barricade => Offset(.12 + p * .76, .25 + _activeLane * .25),
      ReactVariantMode.vantage => Offset(
          .5 + cos(p * pi * 4 + _target.dx * 6) * .30,
          .5 + sin(p * pi * 4 + _target.dx * 6) * .30,
        ),
      _ => _target,
    };
  }

  bool get _isMovingTargetMode => const {
        ReactVariantMode.railrun,
        ReactVariantMode.skyhook,
        ReactVariantMode.corridor,
        ReactVariantMode.sidewinder,
        ReactVariantMode.hinge,
        ReactVariantMode.monoline,
        ReactVariantMode.riftstep,
        ReactVariantMode.barricade,
        ReactVariantMode.vantage,
      }.contains(mode);

  bool get _isCommandMode => const {
        ReactVariantMode.dualcast,
        ReactVariantMode.hush,
        ReactVariantMode.phaseshift,
        ReactVariantMode.barrage,
        ReactVariantMode.crucible,
        ReactVariantMode.catalyst,
        ReactVariantMode.waveline,
        ReactVariantMode.splice,
        ReactVariantMode.thruster,
        ReactVariantMode.frostline,
        ReactVariantMode.fadeout,
      }.contains(mode);

  bool get _isTimingTapMode => const {
        ReactVariantMode.sentry,
        ReactVariantMode.shockwave,
        ReactVariantMode.gateline,
        ReactVariantMode.parallax,
        ReactVariantMode.pendulum,
      }.contains(mode);

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
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildStatusStrip(),
                  const SizedBox(height: 10),
                  Expanded(child: _buildArena()),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: Center(
                      child: Text(
                        _feedback,
                        style: TextStyle(
                          color: _feedback.contains('WRONG') ||
                                  _feedback.contains('SLOW') ||
                                  _feedback.contains('MIS') ||
                                  _feedback.contains('BROKE')
                              ? ReactColors.coral
                              : accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  if (mode != ReactVariantMode.sparkgrid)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: accent.withValues(alpha: .10),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                ],
              ),
            ),
            if (!_running) _buildCountdown(),
            if (_finished) _buildResultOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF07111D),
              foregroundColor: ReactColors.textPrimary,
              side: BorderSide(color: accent.withValues(alpha: .35)),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  mode.badge,
                  style: TextStyle(
                    color: accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          _HudValue(label: 'SCORE', value: '$_score', color: accent),
          const SizedBox(width: 8),
          _HudValue(label: 'LIVES', value: '$_lives', color: ReactColors.coral),
        ],
      );

  Widget _buildStatusStrip() {
    String label;
    double value;
    Color color;
    if (mode == ReactVariantMode.crucible) {
      label = 'HEAT';
      value = _heat;
      color = _orange;
    } else if (mode == ReactVariantMode.frostline) {
      label = 'FROST';
      value = _frost;
      color = ReactColors.electricBlueBright;
    } else if (mode == ReactVariantMode.thruster) {
      label = 'MOMENTUM';
      value = _momentum;
      color = _orange;
    } else if (mode == ReactVariantMode.rampart) {
      label = 'BROKEN SHIELDS';
      value = _rampartDamage / 3;
      color = ReactColors.purple;
    } else {
      label = mode.detail;
      value = _progress;
      color = accent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .9,
              ),
            ),
          ),
          if (mode == ReactVariantMode.crucible ||
              mode == ReactVariantMode.frostline ||
              mode == ReactVariantMode.thruster ||
              mode == ReactVariantMode.rampart)
            SizedBox(
              width: 110,
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 5,
                backgroundColor: color.withValues(alpha: .10),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArena() {
    if (mode == ReactVariantMode.rewind) return _buildMemoryArena();
    if (mode == ReactVariantMode.sparkgrid || mode == ReactVariantMode.rampart) {
      return _buildGridArena();
    }
    if (mode == ReactVariantMode.anchor) return _buildAnchorArena();
    if (mode == ReactVariantMode.harpoon) return _buildHarpoonArena();
    if (mode == ReactVariantMode.scatter) return _buildScatterArena();
    if (mode == ReactVariantMode.offset || mode == ReactVariantMode.shadowlink) {
      return _buildOffsetArena();
    }
    if (mode == ReactVariantMode.breaker) return _buildBreakerArena();
    if (mode == ReactVariantMode.pinpoint) return _buildPinpointArena();
    if (_isTimingTapMode) return _buildTimingArena();
    if (_isMovingTargetMode) return _buildMovingTargetArena();
    if (mode == ReactVariantMode.tidebreak) return _buildTideArena();
    if (_isCommandMode) return _buildCommandArena();
    return _buildMovingTargetArena();
  }

  Widget _arenaShell({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF050A13),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: .48)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .06), blurRadius: 22),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(27), child: child),
      );

  Widget _buildCommandArena() {
    final opacity = switch (mode) {
      ReactVariantMode.hush => .16 + (sin(elapsedMs / 180) + 1) * .14,
      ReactVariantMode.fadeout => max(.04, 1 - phase),
      ReactVariantMode.phaseshift => _ghost ? .16 : 1.0,
      ReactVariantMode.catalyst when _catalystState == 2 => .08,
      _ => 1.0,
    };
    final pulseOpen = _timingWindow();
    final catalystLabel = switch (_catalystState) {
      1 => 'SPEED',
      2 => 'HIDDEN',
      3 => 'REVERSE',
      4 => 'PULSE',
      _ => 'BASE',
    };

    Widget face = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mode == ReactVariantMode.dualcast)
          Text(
            _activeSide == 0 ? 'LEFT SIDE' : 'RIGHT SIDE',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        if (mode == ReactVariantMode.barrage)
          Text(
            'VOLLEY  $_volleyRemaining',
            style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        if (mode == ReactVariantMode.catalyst)
          Text(
            catalystLabel,
            style: TextStyle(
              color: _catalystState == 0 ? ReactColors.textSecondary : ReactColors.lime,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        if (mode == ReactVariantMode.phaseshift)
          Text(
            _ghost ? 'GHOST — WAIT' : 'SOLID — ACT',
            style: TextStyle(
              color: _ghost ? ReactColors.textSecondary : ReactColors.lime,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        if (mode == ReactVariantMode.waveline)
          _PulseTrack(progress: phase, active: pulseOpen, color: accent),
        if (mode == ReactVariantMode.splice)
          Text(
            phase < .55 ? '‹  ${_command.title}  ›' : _command.title,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          )
        else
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Column(
              children: [
                Icon(_command.icon, color: accent, size: 64),
                const SizedBox(height: 12),
                Text(
                  _command.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (mode == ReactVariantMode.dualcast) {
      return _arenaShell(
        child: Row(
          children: List.generate(2, (side) {
            final active = side == _activeSide;
            return Expanded(
              child: ReactGestureSurface(
                enabled: _accepting && active,
                expectedCommand: _expectedCommand(),
                onCommand: _handleCommand,
                child: Container(
                  color: active ? accent.withValues(alpha: .09) : Colors.transparent,
                  child: Center(
                    child: active
                        ? face
                        : Icon(
                            Icons.block_rounded,
                            color: ReactColors.textSecondary.withValues(alpha: .18),
                            size: 44,
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    return _arenaShell(
      child: ReactGestureSurface(
        enabled: _accepting,
        expectedCommand: _expectedCommand(),
        onCommand: _handleCommand,
        child: Center(child: face),
      ),
    );
  }

  Widget _buildTimingArena() {
    final active = _timingWindow();
    final p = phase;
    return _arenaShell(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tapTimingArena,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (mode == ReactVariantMode.shockwave) ...[
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .25), width: 3),
                ),
              ),
              Container(
                width: 40 + p * 230,
                height: 40 + p * 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: active ? ReactColors.lime : accent, width: 4),
                ),
              ),
            ] else if (mode == ReactVariantMode.sentry) ...[
              Transform.rotate(
                angle: p * pi * 4,
                child: Container(width: 245, height: 3, color: active ? ReactColors.lime : accent),
              ),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? ReactColors.lime : accent.withValues(alpha: .35),
                    width: 3,
                  ),
                ),
              ),
            ] else if (mode == ReactVariantMode.gateline) ...[
              Positioned(
                left: 35 + sin(p * pi * 4).abs() * 95,
                top: 45,
                bottom: 45,
                child: Container(width: 16, color: active ? ReactColors.lime : accent),
              ),
              Positioned(
                right: 35 + sin(p * pi * 4).abs() * 95,
                top: 45,
                bottom: 45,
                child: Container(width: 16, color: active ? ReactColors.lime : accent),
              ),
            ] else if (mode == ReactVariantMode.parallax) ...[
              Transform.translate(
                offset: Offset(sin(p * pi * 4) * 70, 0),
                child: Icon(Icons.adjust_rounded, color: accent, size: 90),
              ),
              Transform.translate(
                offset: Offset(-sin(p * pi * 4) * 70, 0),
                child: Icon(
                  Icons.adjust_rounded,
                  color: ReactColors.textPrimary.withValues(alpha: .35),
                  size: 55,
                ),
              ),
            ] else if (mode == ReactVariantMode.pendulum) ...[
              Transform.rotate(
                alignment: Alignment.topCenter,
                angle: sin(p * pi * 4) * 1.05,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 3, height: 150, color: accent),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? ReactColors.lime : accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Positioned(
              bottom: 28,
              child: Text(
                active ? 'NOW' : 'WAIT',
                style: TextStyle(
                  color: active ? ReactColors.lime : ReactColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovingTargetArena() {
    final pos = _movingTarget();
    final blocked = mode == ReactVariantMode.barricade;
    return _arenaShell(
      child: LayoutBuilder(
        builder: (context, box) {
          const size = 62.0;
          return Stack(
            children: [
              if (mode == ReactVariantMode.railrun || mode == ReactVariantMode.barricade)
                for (var lane = 0; lane < 3; lane++)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: box.maxHeight * (.25 + lane * .25),
                    child: Container(
                      height: 2,
                      color: blocked && _blockedLanes.contains(lane)
                          ? ReactColors.coral.withValues(alpha: .65)
                          : accent.withValues(alpha: .22),
                    ),
                  ),
              if (mode == ReactVariantMode.corridor)
                Center(
                  child: Container(
                    width: 80 + (1 - phase) * 230,
                    height: box.maxHeight * .9,
                    decoration: BoxDecoration(
                      border: Border.all(color: accent.withValues(alpha: .25)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              Positioned(
                left: pos.dx * max(1, box.maxWidth - size),
                top: pos.dy * max(1, box.maxHeight - size),
                child: GestureDetector(
                  onTap: () {
                    if (mode == ReactVariantMode.barricade && _blockedLanes.contains(_activeLane)) {
                      _fail('BLOCKED LANE');
                    } else {
                      _complete();
                    }
                  },
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: .18),
                      border: Border.all(color: accent, width: 3),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: .25), blurRadius: 18)],
                    ),
                    child: Icon(mode.icon, color: accent, size: 28),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTideArena() => _arenaShell(
        child: Column(
          children: List.generate(3, (lane) {
            final active = lane == _activeLane;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => active ? _complete() : _fail('UNSAFE ZONE'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: active
                        ? accent.withValues(alpha: .16)
                        : accent.withValues(alpha: .025 + lane * .025),
                    border: Border(
                      bottom: BorderSide(color: accent.withValues(alpha: .18)),
                    ),
                  ),
                  child: Center(
                    child: active ? Icon(Icons.touch_app_rounded, color: accent, size: 50) : null,
                  ),
                ),
              ),
            );
          }),
        ),
      );

  Widget _buildScatterArena() => _arenaShell(
        child: LayoutBuilder(
          builder: (context, box) {
            final live = _activeTile % max(1, _fragments.length);
            return Stack(
              children: List.generate(_fragments.length, (index) {
                final pos = _fragments[index];
                final active = index == live;
                return Positioned(
                  left: pos.dx * max(1, box.maxWidth - 48),
                  top: pos.dy * max(1, box.maxHeight - 48),
                  child: GestureDetector(
                    onTap: () => active ? _complete() : _fail('LOST FRAGMENT'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? accent : accent.withValues(alpha: .12),
                        border: Border.all(color: accent, width: active ? 3 : 1),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      );

  Widget _buildOffsetArena() => _arenaShell(
        child: LayoutBuilder(
          builder: (context, box) {
            final truePos = mode == ReactVariantMode.shadowlink
                ? Offset(1 - _target.dx, 1 - _target.dy)
                : _secondary;
            return Stack(
              children: [
                Positioned(
                  left: _target.dx * max(1, box.maxWidth - 58),
                  top: _target.dy * max(1, box.maxHeight - 58),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 3),
                    ),
                    child: Icon(mode.icon, color: accent),
                  ),
                ),
                Positioned(
                  left: truePos.dx * max(1, box.maxWidth - 58),
                  top: truePos.dy * max(1, box.maxHeight - 58),
                  child: GestureDetector(
                    onTap: _complete,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(
                          color: mode == ReactVariantMode.offset
                              ? ReactColors.textSecondary.withValues(alpha: .28)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    mode == ReactVariantMode.shadowlink
                        ? 'HIT THE MIRRORED SHADOW'
                        : 'HIT THE TRUE CROSSHAIR',
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _buildBreakerArena() => _arenaShell(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_accepting) return;
            if (_breakerLayer < 2) {
              setState(() {
                _breakerLayer += 1;
                _feedback = 'LAYER ${_breakerLayer + 1}';
              });
            } else {
              _complete();
            }
          },
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var layer = 0; layer < 3; layer++)
                  Container(
                    width: 230 - layer * 60,
                    height: 230 - layer * 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: layer < _breakerLayer
                            ? ReactColors.textSecondary.withValues(alpha: .10)
                            : layer == _breakerLayer
                                ? accent
                                : accent.withValues(alpha: .22),
                        width: layer == _breakerLayer ? 5 : 2,
                      ),
                    ),
                  ),
                Text(
                  '${_breakerLayer + 1}',
                  style: TextStyle(color: accent, fontSize: 42, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildPinpointArena() {
    final diameter = max(42.0, 210 * (1 - phase));
    return _arenaShell(
      child: Center(
        child: GestureDetector(
          onTap: () {
            final points = diameter < 75 ? 3 : diameter < 125 ? 2 : 1;
            _complete(points: points);
          },
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: .10),
              border: Border.all(color: accent, width: 4),
            ),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ReactColors.lime,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridArena() => _arenaShell(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final charge = _gridCharge[index].clamp(0.0, 1.0);
              final rampartActive = mode == ReactVariantMode.rampart && index == _activeTile;
              return GestureDetector(
                onTap: () => _tapGrid(index),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: mode == ReactVariantMode.sparkgrid
                        ? Color.lerp(const Color(0xFF07111D), accent, charge * .35)
                        : rampartActive
                            ? ReactColors.coral.withValues(alpha: .20)
                            : accent.withValues(alpha: .035),
                    border: Border.all(
                      color: mode == ReactVariantMode.sparkgrid
                          ? (charge >= .72 ? accent : accent.withValues(alpha: .20))
                          : (rampartActive ? ReactColors.coral : accent.withValues(alpha: .20)),
                      width: charge >= .72 || rampartActive ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: mode == ReactVariantMode.sparkgrid
                        ? Text(
                            '${(charge * 100).round()}%',
                            style: TextStyle(
                              color: charge >= .72 ? accent : ReactColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : Icon(
                            rampartActive ? Icons.warning_rounded : Icons.security_rounded,
                            color: rampartActive
                                ? ReactColors.coral
                                : accent.withValues(alpha: .28),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _buildMemoryArena() => _arenaShell(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                _memoryPlaying ? 'WATCH' : 'YOUR TURN — REVERSE',
                style: TextStyle(
                  color: _memoryPlaying ? accent : ReactColors.lime,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final lit = index == _memoryFlash;
                    return GestureDetector(
                      onTap: () => _tapMemory(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: lit
                              ? accent.withValues(alpha: .42)
                              : accent.withValues(alpha: .055),
                          border: Border.all(
                            color: lit ? accent : accent.withValues(alpha: .28),
                            width: lit ? 4 : 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: lit ? ReactColors.textPrimary : accent,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildHarpoonArena() => _arenaShell(
        child: LayoutBuilder(
          builder: (context, box) {
            final moving = _harpoonDragging
                ? _harpoonDrag
                : Offset(
                    (.15 + _target.dx * .55 + sin(elapsedMs / 330) * .18).clamp(.05, .92),
                    (.18 + _target.dy * .48 + cos(elapsedMs / 410) * .16).clamp(.05, .92),
                  );
            return Listener(
              onPointerDown: (event) {
                final norm = Offset(
                  event.localPosition.dx / box.maxWidth,
                  event.localPosition.dy / box.maxHeight,
                );
                if ((norm - moving).distance < .12) {
                  _harpoonPointer = event.pointer;
                  _harpoonDragging = true;
                  _harpoonDrag = norm;
                  setState(() {});
                }
              },
              onPointerMove: (event) {
                if (event.pointer != _harpoonPointer) return;
                _harpoonDrag = Offset(
                  (event.localPosition.dx / box.maxWidth).clamp(0, 1),
                  (event.localPosition.dy / box.maxHeight).clamp(0, 1),
                );
                setState(() {});
              },
              onPointerUp: (event) {
                if (event.pointer != _harpoonPointer) return;
                final success = (_harpoonDrag - const Offset(.5, .5)).distance < .13;
                _harpoonPointer = null;
                _harpoonDragging = false;
                if (success) {
                  _complete();
                } else {
                  _fail('LINE SNAPPED');
                }
              },
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ReactColors.lime, width: 3),
                        color: ReactColors.lime.withValues(alpha: .05),
                      ),
                    ),
                  ),
                  Positioned(
                    left: moving.dx * max(1, box.maxWidth - 58),
                    top: moving.dy * max(1, box.maxHeight - 58),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: .18),
                        border: Border.all(color: accent, width: 3),
                      ),
                      child: Icon(Icons.north_east_rounded, color: accent),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildAnchorArena() => _arenaShell(
        child: LayoutBuilder(
          builder: (context, box) {
            const anchorCenter = Offset(.18, .82);
            final moving = Offset(
              .55 + sin(elapsedMs / 430) * .25,
              .38 + cos(elapsedMs / 520) * .18,
            );
            return Listener(
              onPointerDown: (event) {
                final norm = Offset(
                  event.localPosition.dx / box.maxWidth,
                  event.localPosition.dy / box.maxHeight,
                );
                if ((norm - anchorCenter).distance < .13 && _anchorPointer == null) {
                  _anchorPointer = event.pointer;
                  _anchorHeld = true;
                  setState(() {});
                  return;
                }
                if (_anchorHeld && (norm - moving).distance < .13) {
                  _complete();
                } else if (!_anchorHeld && (norm - moving).distance < .13) {
                  _fail('HOLD ANCHOR FIRST');
                }
              },
              onPointerUp: (event) {
                if (event.pointer == _anchorPointer) {
                  _anchorPointer = null;
                  _anchorHeld = false;
                  if (_accepting) _fail('ANCHOR RELEASED');
                }
              },
              onPointerCancel: (event) {
                if (event.pointer == _anchorPointer) {
                  _anchorPointer = null;
                  _anchorHeld = false;
                }
              },
              child: Stack(
                children: [
                  Positioned(
                    left: anchorCenter.dx * box.maxWidth - 44,
                    top: anchorCenter.dy * box.maxHeight - 44,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_anchorHeld ? ReactColors.lime : accent).withValues(alpha: .13),
                        border: Border.all(
                          color: _anchorHeld ? ReactColors.lime : accent,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.anchor_rounded,
                        color: _anchorHeld ? ReactColors.lime : accent,
                        size: 38,
                      ),
                    ),
                  ),
                  Positioned(
                    left: moving.dx * box.maxWidth - 31,
                    top: moving.dy * box.maxHeight - 31,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: .18),
                        border: Border.all(color: accent, width: 3),
                      ),
                      child: Icon(Icons.touch_app_rounded, color: accent),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildCountdown() => Positioned.fill(
        child: ColoredBox(
          color: ReactColors.background,
          child: Center(
            child: Text(
              _go ? 'GO' : '$_countdown',
              style: TextStyle(color: accent, fontSize: 76, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );

  Widget _buildResultOverlay() => Positioned.fill(
        child: ColoredBox(
          color: ReactColors.background.withValues(alpha: .96),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _newBest ? Icons.workspace_premium_rounded : mode.icon,
                    color: _newBest ? ReactColors.lime : accent,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _newBest ? 'NEW BEST' : 'RUN OVER',
                    style: TextStyle(
                      color: _newBest ? ReactColors.lime : ReactColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_score',
                    style: TextStyle(color: accent, fontSize: 64, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _feedback,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    height: 54,
                    child: FilledButton(
                      onPressed: _restart,
                      style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                      child: const Text(
                        'PLAY AGAIN',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'BACK TO MODE',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .20)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _PulseTrack extends StatelessWidget {
  const _PulseTrack({required this.progress, required this.active, required this.color});

  final double progress;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 230,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 3, color: color.withValues(alpha: .25)),
            Container(
              width: 42,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? ReactColors.lime : color, width: 2),
              ),
            ),
            Align(
              alignment: Alignment(-1 + progress * 2, 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? ReactColors.lime : color,
                ),
              ),
            ),
          ],
        ),
      );
}
