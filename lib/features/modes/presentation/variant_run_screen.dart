import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/cosmetics/react_cosmetics.dart';
import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/presentation/react_gesture_surface.dart';
import '../data/local_variant_mode_stats.dart';
import '../domain/react_variant_mode.dart';

class VariantRunScreen extends StatefulWidget {
  const VariantRunScreen({required this.mode, super.key});

  final ReactVariantMode mode;

  @override
  State<VariantRunScreen> createState() => _VariantRunScreenState();
}

class _VariantRunScreenState extends State<VariantRunScreen>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 32);

  final Random _random = Random();
  final Stopwatch _roundClock = Stopwatch();
  final Map<int, Offset> _tetherPointers = <int, Offset>{};

  late final ReactGame _game;
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
  int _checkpoint = 0;
  int _roundDurationMs = 2400;
  int _pausedRemainingMs = 0;
  int _repeatRemaining = 1;
  int _bossHitsRemaining = 0;
  int _burstPosition = 0;
  int _gridActive = 0;
  int _overloadExpected = 1;
  int _memoryInput = 0;
  int _memoryFlash = -1;
  int _tempestRule = 0;
  int _prismRule = 0;

  double _progress = 1;
  double _heat = 0;
  double _fuseMs = 5000;
  double _timeDropMs = 20000;

  bool _go = false;
  bool _running = false;
  bool _accepting = false;
  bool _paused = false;
  bool _finished = false;
  bool _hidden = false;
  bool _decoy = false;
  bool _memoryPlaying = false;
  bool _tetherHeld = false;
  int? _tetherPointer;

  String? _feedback;
  String _finishReason = 'RUN OVER';

  Offset _target = const Offset(.5, .5);
  List<Offset> _decoys = const <Offset>[];
  List<int> _memorySequence = <int>[];
  List<(Offset, int)> _overloadTargets = const <(Offset, int)>[];

  ReactVariantMode get mode => widget.mode;
  Color get _accent => ReactCosmetics.effectAccentFor(mode.color);
  ReactCosmeticPalette get _palette => ReactCosmetics.palette;

  int get _remainingMs => max(
        0,
        _roundDurationMs - _roundClock.elapsedMilliseconds,
      );

  bool get _isBoss => mode == ReactVariantMode.titan && _bossHitsRemaining > 0;
  bool get _shuffleFlipped => mode == ReactVariantMode.shuffle && (_score ~/ 5).isOdd;
  bool get _nexusGhost => mode == ReactVariantMode.nexus && (_score ~/ 3) % 4 == 1;
  bool get _nexusReverse => mode == ReactVariantMode.nexus && (_score ~/ 3) % 4 == 2;
  bool get _nexusPulse => mode == ReactVariantMode.nexus && (_score ~/ 3) % 4 == 3;
  bool get _tempestBlackout => mode == ReactVariantMode.tempest && _tempestRule == 1;
  bool get _tempestReverse => mode == ReactVariantMode.tempest && _tempestRule == 2;
  bool get _tempestPulse => mode == ReactVariantMode.tempest && _tempestRule == 3;

  bool get _beatOpen {
    if (!_roundClock.isRunning) return false;
    final beatMs = mode == ReactVariantMode.lockstep ? 760 : 900;
    final phase = _roundClock.elapsedMilliseconds % beatMs;
    final start = mode == ReactVariantMode.lockstep ? 535 : 570;
    final end = mode == ReactVariantMode.lockstep ? 700 : 760;
    return phase >= start && phase <= end;
  }

  int get _initialLives => switch (mode) {
        ReactVariantMode.accel ||
        ReactVariantMode.chain ||
        ReactVariantMode.survivor ||
        ReactVariantMode.stealth ||
        ReactVariantMode.lockstep => 1,
        _ => 3,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lives = _initialLives;
    _game = ReactGame()
      ..configure(accent: mode.color, intensity: .32);
    _startCountdown();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_paused && !_finished) {
      _setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _roundClock.stop();
    super.dispose();
  }

  void _startCountdown() {
    unawaited(ReactAudio.play(ReactSoundCue.countdownTick));
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _paused || _finished) return;
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
    setState(() {
      _running = true;
      _feedback = null;
    });
    _ticker = Timer.periodic(_tick, _onTick);
    if (mode == ReactVariantMode.memory) {
      _memorySequence = <int>[_random.nextInt(4)];
      _startMemoryPlayback();
    } else if (mode == ReactVariantMode.tether) {
      _startTetherRound();
    } else {
      _startRound();
    }
  }

  void _onTick(Timer timer) {
    if (!mounted || _paused || _finished || !_running) return;

    if (mode == ReactVariantMode.reactor) {
      _heat = max(0.0, _heat - .34);
    }
    if (mode == ReactVariantMode.fuse) {
      _fuseMs -= _tick.inMilliseconds;
      if (_fuseMs <= 0) {
        _finish('FUSE BURNED');
        return;
      }
    }
    if (mode == ReactVariantMode.timedrop) {
      _timeDropMs -= _tick.inMilliseconds;
      if (_timeDropMs <= 0) {
        _finish('TIME DROPPED');
        return;
      }
    }

    if (_accepting && _roundClock.isRunning) {
      if (_remainingMs <= 0) {
        _fail('TOO SLOW');
        return;
      }
      _progress = _remainingMs / max(1, _roundDurationMs);
    }

    _game.setIntensity((.30 + _score * .018).clamp(.30, 1.0).toDouble());
    setState(() {});
  }

  void _startRound() {
    if (!mounted || _paused || _finished) return;
    _phaseTimer?.cancel();
    _hidden = false;
    _decoy = false;

    switch (mode.mechanic) {
      case ReactVariantMechanic.command:
        _startCommandRound();
        return;
      case ReactVariantMechanic.target:
        _startTargetRound();
        return;
      case ReactVariantMechanic.grid:
        _startGridRound();
        return;
      case ReactVariantMechanic.memory:
        _startMemoryPlayback();
        return;
      case ReactVariantMechanic.tether:
        _startTetherRound();
        return;
      case ReactVariantMechanic.overload:
        _startOverloadRound();
        return;
    }
  }

  ReactCommand _randomCommand() {
    final values = ReactCommand.values;
    return values[_random.nextInt(values.length)];
  }

  void _startCommandRound() {
    if (mode == ReactVariantMode.echo && _repeatRemaining > 1) {
      _armRound(_durationForCurrentRound());
      return;
    }
    if (_isBoss) {
      _armRound(_durationForCurrentRound());
      return;
    }

    var next = _randomCommand();
    if ((mode == ReactVariantMode.prism && _random.nextBool()) ||
        _shuffleFlipped ||
        _tempestReverse ||
        _nexusReverse) {
      if (!_isSwipe(next)) {
        final swipes = <ReactCommand>[
          ReactCommand.swipeLeft,
          ReactCommand.swipeRight,
          ReactCommand.swipeUp,
          ReactCommand.swipeDown,
        ];
        next = swipes[_random.nextInt(swipes.length)];
      }
    }

    _command = next;
    _prismRule = mode == ReactVariantMode.prism && _random.nextBool() ? 1 : 0;
    if (mode == ReactVariantMode.tempest && _score % 4 == 0) {
      _tempestRule = (_score ~/ 4) % 4;
    }

    if (mode == ReactVariantMode.titan && (_score + 1) % 5 == 0) {
      _bossHitsRemaining = 3;
    }
    if (mode == ReactVariantMode.echo) {
      _repeatRemaining = 2 + _random.nextInt(4);
    }

    if (mode == ReactVariantMode.glitch && _score.isOdd) {
      _decoyCommand = _randomCommand();
      while (_decoyCommand == _command) {
        _decoyCommand = _randomCommand();
      }
      setState(() {
        _decoy = true;
        _accepting = false;
        _feedback = 'DECOY  •  WAIT';
      });
      _phaseTimer = Timer(const Duration(milliseconds: 480), () {
        if (!mounted || _paused || _finished) return;
        setState(() {
          _decoy = false;
          _feedback = 'LIVE';
        });
        _armRound(_durationForCurrentRound());
      });
      return;
    }

    _feedback = _phaseLabel;
    _armRound(_durationForCurrentRound());

    if (mode == ReactVariantMode.phantom || _nexusGhost) {
      _phaseTimer = Timer(const Duration(milliseconds: 480), () {
        if (mounted && !_paused && !_finished && _accepting) {
          setState(() => _hidden = true);
        }
      });
    }
  }

  String? get _phaseLabel {
    if (_isBoss) return 'BOSS  •  ${_bossHitsRemaining} HITS';
    if (mode == ReactVariantMode.echo) return 'REPEAT ×$_repeatRemaining';
    if (mode == ReactVariantMode.prism) {
      return _prismRule == 1 ? 'PINK  •  OPPOSITE' : 'BLUE  •  NORMAL';
    }
    if (mode == ReactVariantMode.shuffle) {
      return _shuffleFlipped ? 'FLIPPED CONTROLS' : 'NORMAL CONTROLS';
    }
    if (mode == ReactVariantMode.tempest) {
      return switch (_tempestRule) {
        0 => 'STORM  •  SPEED',
        1 => 'STORM  •  BLACKOUT',
        2 => 'STORM  •  REVERSE',
        _ => 'STORM  •  PULSE',
      };
    }
    if (mode == ReactVariantMode.nexus) {
      return switch ((_score ~/ 3) % 4) {
        0 => 'NEXUS  •  STANDARD',
        1 => 'NEXUS  •  GHOST',
        2 => 'NEXUS  •  REVERSE',
        _ => 'NEXUS  •  PULSE',
      };
    }
    if (mode == ReactVariantMode.snap) return 'BURST  ${_burstPosition + 1}/5';
    if (mode == ReactVariantMode.ascent) return 'LEVEL ${(_score ~/ 5) + 1}';
    if (mode == ReactVariantMode.zenith && _score >= 16) return 'PEAK PACE';
    return null;
  }

  int _durationForCurrentRound() {
    final base = switch (mode) {
      ReactVariantMode.phantom => 2600,
      ReactVariantMode.accel => max(650, 2400 - _score * 80),
      ReactVariantMode.titan => _isBoss ? 5200 : 2600,
      ReactVariantMode.magnet => 2400,
      ReactVariantMode.illusion => 2300,
      ReactVariantMode.checkpoint => max(1050, 2500 - _score * 30),
      ReactVariantMode.reactor => 2600,
      ReactVariantMode.nexus => max(1000, 2400 - _score * 22),
      ReactVariantMode.prism => 2300,
      ReactVariantMode.ascent => max(850, 2600 - (_score ~/ 5) * 280),
      ReactVariantMode.tempest => _tempestRule == 0 ? 1450 : 2300,
      ReactVariantMode.chain => max(900, 2200 - _score * 35),
      ReactVariantMode.survivor => max(850, 2350 - _score * 42),
      ReactVariantMode.decoder => 2100,
      ReactVariantMode.stealth => 1800,
      ReactVariantMode.snap => 1050,
      ReactVariantMode.timedrop => 1900,
      ReactVariantMode.echo => 2500,
      ReactVariantMode.fuse => 1700,
      ReactVariantMode.shuffle => 2200,
      ReactVariantMode.pulse => 2700,
      ReactVariantMode.glitch => 2100,
      ReactVariantMode.zenith => max(760, 2550 - _score * 110),
      ReactVariantMode.blackout => 2500,
      ReactVariantMode.lockstep => 2300,
      _ => 2400,
    };
    return _command.reactionWindowMs(base);
  }

  void _armRound(int durationMs) {
    _roundDurationMs = max(1, durationMs);
    _progress = 1;
    _roundClock
      ..reset()
      ..start();
    setState(() => _accepting = true);
    unawaited(ReactAudio.play(ReactSoundCue.command));
  }

  ReactCommand get _expectedCommand {
    if ((_prismRule == 1 && mode == ReactVariantMode.prism) ||
        _shuffleFlipped ||
        _tempestReverse ||
        _nexusReverse) {
      return _opposite(_command);
    }
    return _command;
  }

  void _handleCommand(ReactCommand performed) {
    if (!_accepting || _paused || _finished) return;

    if ((mode == ReactVariantMode.pulse ||
            _nexusPulse ||
            _tempestPulse ||
            mode == ReactVariantMode.lockstep) &&
        !_beatOpen) {
      _fail('OFF BEAT');
      return;
    }

    if (performed != _expectedCommand) {
      _fail('WRONG INPUT');
      return;
    }
    _completeCommand();
  }

  void _completeCommand() {
    if (!_accepting) return;
    final responseMs = _roundClock.elapsedMilliseconds;
    _roundClock.stop();
    _accepting = false;

    if (mode == ReactVariantMode.echo && _repeatRemaining > 1) {
      _repeatRemaining -= 1;
      setState(() => _feedback = 'REPEAT ×$_repeatRemaining');
      _phaseTimer = Timer(const Duration(milliseconds: 110), () {
        if (mounted && !_paused && !_finished) _startCommandRound();
      });
      return;
    }

    if (_isBoss && _bossHitsRemaining > 1) {
      _bossHitsRemaining -= 1;
      setState(() => _feedback = 'BOSS  •  $_bossHitsRemaining HITS');
      _phaseTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted && !_paused && !_finished) _startCommandRound();
      });
      return;
    }
    if (_isBoss) _bossHitsRemaining = 0;

    _score += mode == ReactVariantMode.zenith && _score >= 16 ? 2 : 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);

    if (mode == ReactVariantMode.checkpoint && _score % 5 == 0) {
      _checkpoint = _score;
      _feedback = 'CHECKPOINT BANKED  •  $_checkpoint';
    } else {
      _feedback = '+1  CLEAR';
    }

    if (mode == ReactVariantMode.reactor) {
      final addedHeat = responseMs <= 700 ? 23.0 : 12.0;
      _heat = min(100.0, _heat + addedHeat);
      if (_heat >= 100) {
        _game.triggerMiss();
        _finish('REACTOR OVERHEATED');
        return;
      }
    }

    if (mode == ReactVariantMode.timedrop && _streak % 5 == 0) {
      _timeDropMs += 3000;
      _feedback = '+3 SEC  •  STREAK BONUS';
    }

    if (mode == ReactVariantMode.fuse) {
      _fuseMs = min(6000.0, _fuseMs + 1250);
      _feedback = '+1.25 SEC  •  FUSE RESET';
    }

    _game.triggerSuccess();
    unawaited(ReactAudio.play(ReactSoundCue.success));

    if (mode == ReactVariantMode.snap) {
      _burstPosition = (_burstPosition + 1) % 5;
      final delay = _burstPosition == 0 ? 720 : 90;
      _phaseTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted && !_paused && !_finished) _startRound();
      });
      setState(() {});
      return;
    }

    if (mode == ReactVariantMode.reactor && _score % 5 == 0) {
      setState(() => _feedback = 'COOLING  •  HOLD');
      _phaseTimer = Timer(const Duration(milliseconds: 1100), () {
        if (!mounted || _paused || _finished) return;
        _heat = max(0.0, _heat - 28);
        _startRound();
      });
      return;
    }

    _phaseTimer = Timer(Duration(milliseconds: _successDelayMs), () {
      if (mounted && !_paused && !_finished) _startRound();
    });
    setState(() {});
  }

  int get _successDelayMs => switch (mode) {
        ReactVariantMode.accel ||
        ReactVariantMode.chain ||
        ReactVariantMode.survivor ||
        ReactVariantMode.zenith => 90,
        ReactVariantMode.snap => 70,
        ReactVariantMode.fuse || ReactVariantMode.timedrop => 120,
        _ => 190,
      };

  void _startTargetRound() {
    _target = _randomPoint(.14);
    _decoys = switch (mode) {
      ReactVariantMode.beacon => List<Offset>.generate(4, (_) => _randomPoint(.10)),
      ReactVariantMode.hunter => List<Offset>.generate(5, (_) => _randomPoint(.08)),
      _ => const <Offset>[],
    };
    final duration = switch (mode) {
      ReactVariantMode.beacon => max(850, 2100 - _score * 25),
      ReactVariantMode.collapse => max(900, 2300 - _score * 22),
      ReactVariantMode.hunter => max(800, 1900 - _score * 28),
      ReactVariantMode.vortex => 2500,
      ReactVariantMode.orbit => 2200,
      ReactVariantMode.ricochet => 2300,
      _ => 2200,
    };
    _feedback = mode == ReactVariantMode.hunter ? 'FIND LIVE TARGET' : null;
    _armRound(duration);
  }

  void _hitTarget() {
    if (!_accepting || _paused || _finished) return;
    _roundClock.stop();
    _accepting = false;
    _score += 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);
    _feedback = '+1  LOCKED';
    _game.triggerSuccess();
    unawaited(ReactAudio.play(ReactSoundCue.success));
    _phaseTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_paused && !_finished) _startRound();
    });
    setState(() {});
  }

  void _hitDecoy() {
    if (_accepting) _fail('FALSE TARGET');
  }

  void _startGridRound() {
    _gridActive = _random.nextInt(mode == ReactVariantMode.mosaic ? 9 : 4);
    _feedback = mode == ReactVariantMode.mosaic ? 'SCAN THE GRID' : 'ACTIVE ZONE';
    _armRound(mode == ReactVariantMode.mosaic ? 1800 : 2000);
  }

  void _tapGrid(int index) {
    if (!_accepting || _paused || _finished) return;
    if (index != _gridActive) {
      _fail('WRONG ZONE');
      return;
    }
    _roundClock.stop();
    _accepting = false;
    _score += 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);
    _game.triggerSuccess();
    unawaited(ReactAudio.play(ReactSoundCue.success));
    _phaseTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted && !_paused && !_finished) _startGridRound();
    });
    setState(() => _feedback = '+1  CLEAR');
  }

  void _startMemoryPlayback() {
    if (_memorySequence.isEmpty) {
      _memorySequence = <int>[_random.nextInt(4)];
    }
    _phaseTimer?.cancel();
    _roundClock.stop();
    setState(() {
      _memoryPlaying = true;
      _accepting = false;
      _memoryInput = 0;
      _memoryFlash = -1;
      _feedback = 'WATCH  •  ${_memorySequence.length} STEPS';
    });
    _playMemoryStep(0);
  }

  void _playMemoryStep(int index) {
    if (!mounted || _paused || _finished) return;
    if (index >= _memorySequence.length) {
      setState(() {
        _memoryPlaying = false;
        _memoryFlash = -1;
        _feedback = 'YOUR TURN';
      });
      _armRound(max(3200, _memorySequence.length * 1150));
      return;
    }
    setState(() => _memoryFlash = _memorySequence[index]);
    unawaited(ReactAudio.play(ReactSoundCue.command));
    _phaseTimer = Timer(const Duration(milliseconds: 330), () {
      if (!mounted || _paused || _finished) return;
      setState(() => _memoryFlash = -1);
      _phaseTimer = Timer(const Duration(milliseconds: 170), () {
        _playMemoryStep(index + 1);
      });
    });
  }

  void _tapMemoryPad(int index) {
    if (_memoryPlaying || !_accepting || _paused || _finished) return;
    if (index != _memorySequence[_memoryInput]) {
      _fail('SEQUENCE BROKEN');
      return;
    }
    _memoryInput += 1;
    unawaited(ReactAudio.play(ReactSoundCue.success));
    if (_memoryInput < _memorySequence.length) {
      setState(() => _feedback = '${_memoryInput}/${_memorySequence.length}');
      return;
    }

    _roundClock.stop();
    _accepting = false;
    _score += 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);
    _game.triggerSuccess();
    _memorySequence.add(_random.nextInt(4));
    setState(() => _feedback = 'CHAIN +1');
    _phaseTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted && !_paused && !_finished) _startMemoryPlayback();
    });
  }

  void _startOverloadRound() {
    final positions = <Offset>[
      _randomPoint(.12),
      _randomPoint(.12),
      _randomPoint(.12),
    ];
    final priorities = <int>[1, 2, 3]..shuffle(_random);
    _overloadTargets = List<(Offset, int)>.generate(
      3,
      (index) => (positions[index], priorities[index]),
    );
    _overloadExpected = 1;
    _feedback = 'CLEAR PRIORITY 1 → 2 → 3';
    _armRound(3300);
  }

  void _tapOverload(int priority) {
    if (!_accepting || _paused || _finished) return;
    if (priority != _overloadExpected) {
      _fail('WRONG PRIORITY');
      return;
    }
    if (_overloadExpected < 3) {
      _overloadExpected += 1;
      setState(() => _feedback = 'NEXT PRIORITY  •  $_overloadExpected');
      return;
    }
    _roundClock.stop();
    _accepting = false;
    _score += 1;
    _streak += 1;
    _maxStreak = max(_maxStreak, _streak);
    _game.triggerSuccess();
    unawaited(ReactAudio.play(ReactSoundCue.success));
    setState(() => _feedback = 'OVERLOAD CLEARED');
    _phaseTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && !_paused && !_finished) _startOverloadRound();
    });
  }

  void _startTetherRound() {
    _target = _randomPoint(.18);
    _feedback = _tetherHeld ? 'TETHERED  •  HIT TARGET' : 'HOLD ANCHOR + HIT TARGET';
    _armRound(3000);
  }

  void _onTetherPointerDown(PointerDownEvent event, double size) {
    if (!_running || _paused || _finished) return;
    _tetherPointers[event.pointer] = event.localPosition;
    final anchor = Offset(size * .26, size * .74);
    final target = Offset(size * _target.dx, size * _target.dy);

    if (_tetherPointer == null &&
        (event.localPosition - anchor).distance <= size * .13) {
      _tetherPointer = event.pointer;
      setState(() {
        _tetherHeld = true;
        _feedback = 'TETHERED  •  USE SECOND FINGER';
      });
      return;
    }

    if (_tetherHeld &&
        event.pointer != _tetherPointer &&
        (event.localPosition - target).distance <= size * .11 &&
        _accepting) {
      _roundClock.stop();
      _score += 1;
      _streak += 1;
      _maxStreak = max(_maxStreak, _streak);
      _target = _randomPoint(.18);
      _game.triggerSuccess();
      unawaited(ReactAudio.play(ReactSoundCue.success));
      _feedback = '+1  TETHER HELD';
      _armRound(3000);
      setState(() {});
    }
  }

  void _onTetherPointerUp(PointerEvent event) {
    _tetherPointers.remove(event.pointer);
    if (event.pointer == _tetherPointer) {
      _tetherPointer = null;
      final wasHeld = _tetherHeld;
      _tetherHeld = false;
      if (wasHeld && _accepting && !_paused && !_finished) {
        _fail('TETHER RELEASED');
      }
    }
  }

  void _fail(String reason) {
    if (_finished || !_running) return;
    _roundClock.stop();
    _accepting = false;
    _hidden = false;
    _streak = 0;
    _game.triggerMiss();
    unawaited(ReactAudio.play(ReactSoundCue.miss));

    if (mode == ReactVariantMode.fuse) {
      _fuseMs = max(0.0, _fuseMs - 1200);
      setState(() => _feedback = '$reason  •  -1.2 SEC');
      if (_fuseMs <= 0) {
        _finish('FUSE BURNED');
        return;
      }
      _phaseTimer = Timer(const Duration(milliseconds: 360), () {
        if (mounted && !_paused && !_finished) _startRound();
      });
      return;
    }

    if (mode == ReactVariantMode.timedrop) {
      _timeDropMs = max(0.0, _timeDropMs - 1200);
    }

    if (mode == ReactVariantMode.checkpoint) {
      _score = _checkpoint;
    }

    _lives -= 1;
    setState(() {
      _feedback = mode == ReactVariantMode.checkpoint
          ? '$reason  •  BACK TO $_checkpoint'
          : '$reason  •  $_lives ${_lives == 1 ? 'LIFE' : 'LIVES'}';
    });

    if (_lives <= 0) {
      _finish(reason);
      return;
    }

    if (mode == ReactVariantMode.memory) {
      _memorySequence = <int>[_random.nextInt(4)];
    }
    if (mode == ReactVariantMode.tether) {
      _tetherPointer = null;
      _tetherHeld = false;
      _tetherPointers.clear();
    }

    _phaseTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted || _paused || _finished) return;
      if (mode == ReactVariantMode.memory) {
        _startMemoryPlayback();
      } else if (mode == ReactVariantMode.tether) {
        _startTetherRound();
      } else {
        _startRound();
      }
    });
  }

  Future<void> _finish(String reason) async {
    if (_finished || !mounted) return;
    _finished = true;
    _finishReason = reason;
    _accepting = false;
    _ticker?.cancel();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _roundClock.stop();
    _game.pauseEngine();
    final newBest = await LocalVariantModeStats.record(mode, _score);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VariantResultsScreen(
          mode: mode,
          score: _score,
          maxStreak: _maxStreak,
          reason: _finishReason,
          newBest: newBest,
        ),
      ),
    );
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;
    if (value) {
      _pausedRemainingMs = _accepting ? max(1, _remainingMs) : 0;
      _roundClock.stop();
      _phaseTimer?.cancel();
      _game.pauseEngine();
      setState(() => _paused = true);
      return;
    }

    _game.resumeEngine();
    setState(() => _paused = false);
    if (!_running) return;

    if (mode == ReactVariantMode.memory && _memoryPlaying) {
      _startMemoryPlayback();
      return;
    }
    if (_pausedRemainingMs > 0 && _accepting) {
      final remaining = _pausedRemainingMs;
      _pausedRemainingMs = 0;
      _armRound(remaining);
      return;
    }
    if (!_accepting) _startRound();
  }

  void _quit() {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker?.cancel();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _game.pauseEngine();
    Navigator.of(context).pop();
  }

  Offset _randomPoint(double margin) => Offset(
        margin + _random.nextDouble() * (1 - margin * 2),
        margin + _random.nextDouble() * (1 - margin * 2),
      );

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_paused && !_finished) _setPaused(true);
      },
      child: Scaffold(
        backgroundColor: _palette.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(game: _game),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final arenaSize = min(
                    constraints.maxWidth - 28,
                    constraints.maxHeight * .58,
                  ).clamp(280.0, 390.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      children: [
                        _RunHeader(
                          mode: mode,
                          score: _score,
                          lives: _lives,
                          accent: _accent,
                          onPause: () => _setPaused(true),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Center(
                            child: _buildArena(arenaSize),
                          ),
                        ),
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              _feedback ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: (_feedback ?? '').contains('WRONG') ||
                                        (_feedback ?? '').contains('FALSE') ||
                                        (_feedback ?? '').contains('SLOW') ||
                                        (_feedback ?? '').contains('RELEASED')
                                    ? _palette.failure
                                    : _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        _StatusBar(
                          mode: mode,
                          accent: _accent,
                          heat: _heat,
                          fuseMs: _fuseMs,
                          timeDropMs: _timeDropMs,
                          progress: _progress,
                          checkpoint: _checkpoint,
                          streak: _streak,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (!_running)
              _CountdownOverlay(
                mode: mode,
                count: _countdown,
                go: _go,
                accent: _accent,
              ),
            if (_paused)
              _PauseOverlay(
                accent: _accent,
                onResume: () => _setPaused(false),
                onQuit: _quit,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArena(double size) {
    if (!_running) return SizedBox.square(dimension: size);
    return switch (mode.mechanic) {
      ReactVariantMechanic.command => _buildCommandArena(size),
      ReactVariantMechanic.target => _buildTargetArena(size),
      ReactVariantMechanic.grid => _buildGridArena(size),
      ReactVariantMechanic.memory => _buildMemoryArena(size),
      ReactVariantMechanic.tether => _buildTetherArena(size),
      ReactVariantMechanic.overload => _buildOverloadArena(size),
    };
  }

  Widget _buildCommandArena(double size) {
    final blackoutHidden = mode == ReactVariantMode.blackout &&
        _roundClock.isRunning &&
        (_roundClock.elapsedMilliseconds % 700) > 280;
    final tempestHidden = _tempestBlackout &&
        _roundClock.isRunning &&
        (_roundClock.elapsedMilliseconds % 650) > 260;
    final hidden = _hidden || blackoutHidden || tempestHidden;
    final shownCommand = _decoy ? _decoyCommand : _command;
    final iconOnly = mode == ReactVariantMode.decoder;
    final stealth = mode == ReactVariantMode.stealth;
    final beatMode = mode == ReactVariantMode.pulse ||
        mode == ReactVariantMode.lockstep ||
        _nexusPulse ||
        _tempestPulse;

    Widget content = _CommandFace(
      command: shownCommand,
      hidden: hidden,
      iconOnly: iconOnly,
      stealth: stealth,
      decoy: _decoy,
      accent: _decoy ? _palette.failure : _accent,
      progress: _progress,
      beatOpen: beatMode && _beatOpen,
      bossHits: _isBoss ? _bossHitsRemaining : 0,
    );

    if (mode == ReactVariantMode.illusion) {
      final t = _roundClock.elapsedMilliseconds / 1000;
      content = Transform.rotate(
        angle: sin(t * 8) * .11,
        child: Transform.scale(
          scale: 1 + sin(t * 11) * .06,
          child: Transform.translate(
            offset: Offset(sin(t * 6) * 14, cos(t * 7) * 10),
            child: content,
          ),
        ),
      );
    }

    if (mode == ReactVariantMode.magnet) {
      final p = 1 - _progress;
      final direction = (_score % 4) * pi / 2 - pi / 4;
      content = Transform.translate(
        offset: Offset(cos(direction), sin(direction)) * (size * .18 * p),
        child: content,
      );
    }

    return SizedBox.square(
      dimension: size,
      child: ReactGestureSurface(
        enabled: _accepting && !_decoy && !_paused,
        expectedCommand: _expectedCommand,
        onCommand: _handleCommand,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _palette.background.withValues(alpha: .90),
            border: Border.all(
              color: beatMode && _beatOpen
                  ? _accent
                  : _accent.withValues(alpha: .50),
              width: beatMode && _beatOpen ? 4 : 2,
            ),
            boxShadow: beatMode && _beatOpen
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: .26),
                      blurRadius: 30,
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildTargetArena(double size) {
    final target = _movingTarget(size);
    final targetSize = mode == ReactVariantMode.collapse
        ? max(34.0, 72.0 - _score * 2.5)
        : 58.0;
    final ringScale = mode == ReactVariantMode.collapse
        ? max(.42, 1 - _score * .035)
        : 1.0;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: size * .88 * ringScale,
              height: size * .88 * ringScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _palette.background.withValues(alpha: .82),
                border: Border.all(
                  color: _accent.withValues(alpha: .42),
                  width: 2,
                ),
              ),
            ),
          ),
          for (final decoy in _decoys)
            Positioned(
              left: decoy.dx * size - 24,
              top: decoy.dy * size - 24,
              child: GestureDetector(
                onTap: _hitDecoy,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ReactColors.textSecondary.withValues(alpha: .45),
                    ),
                  ),
                  child: Icon(
                    Icons.adjust_rounded,
                    color: ReactColors.textSecondary.withValues(alpha: .55),
                    size: 22,
                  ),
                ),
              ),
            ),
          Positioned(
            left: target.dx - targetSize / 2,
            top: target.dy - targetSize / 2,
            child: GestureDetector(
              onTap: _hitTarget,
              child: Container(
                width: targetSize,
                height: targetSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: .12),
                  border: Border.all(color: _accent, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: .25),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(
                  mode.icon,
                  color: _accent,
                  size: targetSize * .45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset _movingTarget(double size) {
    final elapsed = _roundClock.elapsedMilliseconds / 1000;
    if (mode == ReactVariantMode.orbit) {
      final angle = elapsed * 3.4;
      return Offset(
        size / 2 + cos(angle) * size * .34,
        size / 2 + sin(angle) * size * .34,
      );
    }
    if (mode == ReactVariantMode.vortex) {
      final angle = elapsed * 5.0;
      final radius =
          size * (.36 * _progress.clamp(.18, 1.0).toDouble());
      return Offset(
        size / 2 + cos(angle) * radius,
        size / 2 + sin(angle) * radius,
      );
    }
    if (mode == ReactVariantMode.ricochet) {
      double bounce(double value) {
        final x = value % 2;
        return x <= 1 ? x : 2 - x;
      }

      final x = .12 + bounce(elapsed * .82 + _score * .17) * .76;
      final y = .12 + bounce(elapsed * 1.07 + _score * .31) * .76;
      return Offset(x * size, y * size);
    }
    return Offset(_target.dx * size, _target.dy * size);
  }

  Widget _buildGridArena(double size) {
    final count = mode == ReactVariantMode.mosaic ? 9 : 4;
    final columns = mode == ReactVariantMode.mosaic ? 3 : 2;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _palette.background.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _accent.withValues(alpha: .40), width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
        ),
        itemBuilder: (context, index) {
          final active = index == _gridActive;
          return GestureDetector(
            onTap: () => _tapGrid(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: active
                    ? _accent.withValues(alpha: .18)
                    : _accent.withValues(alpha: .025),
                border: Border.all(
                  color: active ? _accent : _accent.withValues(alpha: .18),
                  width: active ? 2.2 : 1,
                ),
              ),
              child: Icon(
                active ? mode.icon : Icons.circle_outlined,
                color: active
                    ? _accent
                    : ReactColors.textSecondary.withValues(alpha: .25),
                size: active ? 34 : 18,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemoryArena(double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _palette.background.withValues(alpha: .90),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _accent.withValues(alpha: .45), width: 2),
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
          return GestureDetector(
            onTap: () => _tapMemoryPad(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: lit
                    ? _accent.withValues(alpha: .36)
                    : _accent.withValues(alpha: .05),
                border: Border.all(
                  color: lit ? _accent : _accent.withValues(alpha: .25),
                  width: lit ? 3 : 1.5,
                ),
                boxShadow: lit
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: .28),
                          blurRadius: 26,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: lit ? Colors.white : _accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTetherArena(double size) {
    final anchor = Offset(size * .26, size * .74);
    final target = Offset(size * _target.dx, size * _target.dy);
    return Listener(
      onPointerDown: (event) => _onTetherPointerDown(event, size),
      onPointerUp: _onTetherPointerUp,
      onPointerCancel: _onTetherPointerUp,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _palette.background.withValues(alpha: .90),
          border: Border.all(color: _accent.withValues(alpha: .45), width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: anchor.dx - 45,
              top: anchor.dy - 45,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tetherHeld
                      ? _accent.withValues(alpha: .22)
                      : _accent.withValues(alpha: .07),
                  border: Border.all(
                    color: _accent,
                    width: _tetherHeld ? 4 : 2,
                  ),
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  color: _accent,
                  size: 36,
                ),
              ),
            ),
            Positioned(
              left: target.dx - 34,
              top: target.dy - 34,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: .13),
                  border: Border.all(color: _accent, width: 2.5),
                ),
                child: Icon(
                  Icons.ads_click_rounded,
                  color: _accent,
                  size: 30,
                ),
              ),
            ),
            if (_tetherHeld)
              CustomPaint(
                size: Size.square(size),
                painter: _TetherLinePainter(
                  anchor: anchor,
                  target: target,
                  color: _accent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverloadArena(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _palette.background.withValues(alpha: .90),
        border: Border.all(color: _accent.withValues(alpha: .48), width: 2),
      ),
      child: Stack(
        children: [
          for (final target in _overloadTargets)
            Positioned(
              left: target.$1.dx * size - 34,
              top: target.$1.dy * size - 34,
              child: GestureDetector(
                onTap: () => _tapOverload(target.$2),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: target.$2 == _overloadExpected
                        ? _accent.withValues(alpha: .20)
                        : _accent.withValues(alpha: .07),
                    border: Border.all(
                      color: target.$2 == _overloadExpected
                          ? _accent
                          : _accent.withValues(alpha: .45),
                      width: target.$2 == _overloadExpected ? 3 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${target.$2}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
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
    required this.lives,
    required this.accent,
    required this.onPause,
  });

  final ReactVariantMode mode;
  final int score;
  final int lives;
  final Color accent;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPause,
          style: IconButton.styleFrom(
            backgroundColor: accent.withValues(alpha: .07),
            foregroundColor: ReactColors.textPrimary,
            side: BorderSide(color: accent.withValues(alpha: .30)),
          ),
          icon: const Icon(Icons.pause_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode.title,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
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
        _HeaderMetric(
          label: 'SCORE',
          value: '$score',
          color: accent,
        ),
        const SizedBox(width: 8),
        _HeaderMetric(
          label: 'LIVES',
          value: List<String>.filled(lives, '♥').join(),
          color: ReactCosmetics.palette.failure,
        ),
      ],
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.color,
  });
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
            const SizedBox(height: 2),
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
    required this.hidden,
    required this.iconOnly,
    required this.stealth,
    required this.decoy,
    required this.accent,
    required this.progress,
    required this.beatOpen,
    required this.bossHits,
  });

  final ReactCommand command;
  final bool hidden;
  final bool iconOnly;
  final bool stealth;
  final bool decoy;
  final Color accent;
  final double progress;
  final bool beatOpen;
  final int bossHits;

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return Center(
        child: Icon(
          Icons.visibility_off_rounded,
          color: accent.withValues(alpha: .22),
          size: 54,
        ),
      );
    }

    final titleSize = stealth ? 16.0 : 31.0;
    final iconSize = stealth ? 38.0 : 90.0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (decoy)
            Text(
              'DECOY',
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          if (!iconOnly) ...[
            Text(
              command.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            SizedBox(height: stealth ? 10 : 18),
          ],
          Icon(command.icon, color: accent, size: iconSize),
          if (!iconOnly && !stealth) ...[
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
          ],
          if (bossHits > 0) ...[
            const SizedBox(height: 12),
            Text(
              'BOSS HITS LEFT  $bossHits',
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (beatOpen) ...[
            const SizedBox(height: 12),
            Text(
              'NOW',
              style: TextStyle(
                color: accent,
                fontSize: 17,
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

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.mode,
    required this.accent,
    required this.heat,
    required this.fuseMs,
    required this.timeDropMs,
    required this.progress,
    required this.checkpoint,
    required this.streak,
  });

  final ReactVariantMode mode;
  final Color accent;
  final double heat;
  final double fuseMs;
  final double timeDropMs;
  final double progress;
  final int checkpoint;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final (label, value, meter) = switch (mode) {
      ReactVariantMode.reactor => ('HEAT', '${heat.round()}%', heat / 100),
      ReactVariantMode.fuse => (
          'FUSE',
          '${(fuseMs / 1000).toStringAsFixed(1)}s',
          fuseMs / 6000,
        ),
      ReactVariantMode.timedrop => (
          'RUN CLOCK',
          '${(timeDropMs / 1000).toStringAsFixed(1)}s',
          timeDropMs / 30000,
        ),
      ReactVariantMode.checkpoint => ('BANKED', '$checkpoint', progress),
      ReactVariantMode.chain => ('CHAIN', '$streak', progress),
      _ => ('ROUND', '${(progress * 100).round()}%', progress),
    };
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: meter.clamp(0.0, 1.0).toDouble(),
                minHeight: 7,
                backgroundColor: accent.withValues(alpha: .10),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({
    required this.mode,
    required this.count,
    required this.go,
    required this.accent,
  });
  final ReactVariantMode mode;
  final int count;
  final bool go;
  final Color accent;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: ReactCosmetics.palette.background.withValues(alpha: .94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mode.title,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                go ? 'GO' : '$count',
                style: TextStyle(
                  color: go ? accent : ReactColors.textPrimary,
                  fontSize: go ? 88 : 116,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                mode.badge,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.accent,
    required this.onResume,
    required this.onQuit,
  });
  final Color accent;
  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black.withValues(alpha: .88),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ReactCosmetics.palette.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: .55)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onResume,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'RESUME',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onQuit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ReactColors.textPrimary,
                      side: BorderSide(color: accent.withValues(alpha: .45)),
                    ),
                    child: const Text('QUIT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TetherLinePainter extends CustomPainter {
  const _TetherLinePainter({
    required this.anchor,
    required this.target,
    required this.color,
  });
  final Offset anchor;
  final Offset target;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      anchor,
      target,
      Paint()
        ..color = color.withValues(alpha: .35)
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TetherLinePainter oldDelegate) =>
      anchor != oldDelegate.anchor ||
      target != oldDelegate.target ||
      color != oldDelegate.color;
}

class VariantResultsScreen extends StatefulWidget {
  const VariantResultsScreen({
    required this.mode,
    required this.score,
    required this.maxStreak,
    required this.reason,
    required this.newBest,
    super.key,
  });

  final ReactVariantMode mode;
  final int score;
  final int maxStreak;
  final String reason;
  final bool newBest;

  @override
  State<VariantResultsScreen> createState() => _VariantResultsScreenState();
}

class _VariantResultsScreenState extends State<VariantResultsScreen> {
  late Future<int> _best;

  @override
  void initState() {
    super.initState();
    _best = LocalVariantModeStats.best(widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    final accent = ReactCosmetics.effectAccentFor(widget.mode.color);
    final palette = ReactCosmetics.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              Icon(widget.mode.icon, color: accent, size: 64),
              const SizedBox(height: 14),
              Text(
                widget.mode.title,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '${widget.score}',
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 92,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.newBest ? 'NEW BEST' : 'FINAL SCORE',
                style: TextStyle(
                  color: widget.newBest
                      ? palette.secondary
                      : ReactColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<int>(
                future: _best,
                builder: (context, snapshot) => Row(
                  children: [
                    Expanded(
                      child: _ResultMetric(
                        label: 'BEST',
                        value: '${snapshot.data ?? widget.score}',
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResultMetric(
                        label: 'MAX STREAK',
                        value: '${widget.maxStreak}',
                        color: palette.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => VariantRunScreen(mode: widget.mode),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ReactColors.textPrimary,
                    side: BorderSide(color: accent.withValues(alpha: .40)),
                  ),
                  child: const Text(
                    'BACK TO MODE',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 76,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .24)),
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
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}
