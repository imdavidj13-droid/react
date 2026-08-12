import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

enum TrainingPracticeType { tap, doubleTap, hold, swipe, pinch, spread, freeze }

class TrainingPracticeScreen extends StatefulWidget {
  const TrainingPracticeScreen({required this.type, super.key});

  final TrainingPracticeType type;

  @override
  State<TrainingPracticeScreen> createState() => _TrainingPracticeScreenState();
}

class _TrainingPracticeScreenState extends State<TrainingPracticeScreen> {
  static const _freezeDuration = Duration(milliseconds: 1800);

  Timer? _freezeTimer;
  Offset _dragDelta = Offset.zero;
  bool _multiTouchSeen = false;
  bool _resolved = false;
  int _successes = 0;
  String _status = 'READY';

  @override
  void initState() {
    super.initState();
    if (widget.type == TrainingPracticeType.freeze) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startFreeze());
    }
  }

  @override
  void dispose() {
    _freezeTimer?.cancel();
    super.dispose();
  }

  String get _title => switch (widget.type) {
        TrainingPracticeType.tap => 'TAP',
        TrainingPracticeType.doubleTap => 'DOUBLE TAP',
        TrainingPracticeType.hold => 'HOLD',
        TrainingPracticeType.swipe => 'SWIPE',
        TrainingPracticeType.pinch => 'PINCH',
        TrainingPracticeType.spread => 'SPREAD',
        TrainingPracticeType.freeze => 'FREEZE',
      };

  String get _instruction => switch (widget.type) {
        TrainingPracticeType.tap => 'Tap the target once.',
        TrainingPracticeType.doubleTap => 'Tap the target twice quickly.',
        TrainingPracticeType.hold => 'Press and hold the target.',
        TrainingPracticeType.swipe => 'Swipe the target in any direction.',
        TrainingPracticeType.pinch => 'Move two fingers together on the target.',
        TrainingPracticeType.spread => 'Move two fingers apart on the target.',
        TrainingPracticeType.freeze => 'Do nothing until the timer completes.',
      };

  IconData get _icon => switch (widget.type) {
        TrainingPracticeType.tap => Icons.touch_app_rounded,
        TrainingPracticeType.doubleTap => Icons.ads_click_rounded,
        TrainingPracticeType.hold => Icons.pan_tool_alt_rounded,
        TrainingPracticeType.swipe => Icons.double_arrow_rounded,
        TrainingPracticeType.pinch => Icons.close_fullscreen_rounded,
        TrainingPracticeType.spread => Icons.open_in_full_rounded,
        TrainingPracticeType.freeze => Icons.ac_unit_rounded,
      };

  void _success() {
    if (_resolved) return;
    _resolved = true;
    _freezeTimer?.cancel();
    setState(() {
      _successes += 1;
      _status = 'PERFECT';
    });
    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _resolved = false;
        _dragDelta = Offset.zero;
        _multiTouchSeen = false;
        _status = 'READY';
      });
      if (widget.type == TrainingPracticeType.freeze) {
        _startFreeze();
      }
    });
  }

  void _wrongInput() {
    if (_resolved) return;
    _freezeTimer?.cancel();
    setState(() => _status = 'TRY AGAIN');
    Timer(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() => _status = 'READY');
      if (widget.type == TrainingPracticeType.freeze) {
        _startFreeze();
      }
    });
  }

  void _startFreeze() {
    _freezeTimer?.cancel();
    setState(() => _status = 'FREEZE...');
    _freezeTimer = Timer(_freezeDuration, _success);
  }

  void _handleTap() {
    if (widget.type == TrainingPracticeType.tap) {
      _success();
    } else if (widget.type == TrainingPracticeType.freeze) {
      _wrongInput();
    }
  }

  void _handleDoubleTap() {
    if (widget.type == TrainingPracticeType.doubleTap) {
      _success();
    } else if (widget.type == TrainingPracticeType.freeze) {
      _wrongInput();
    }
  }

  void _handleLongPress() {
    if (widget.type == TrainingPracticeType.hold) {
      _success();
    } else if (widget.type == TrainingPracticeType.freeze) {
      _wrongInput();
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _dragDelta = Offset.zero;
    _multiTouchSeen = details.pointerCount >= 2;
    if (widget.type == TrainingPracticeType.freeze) _wrongInput();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_resolved) return;
    if (details.pointerCount >= 2) {
      _multiTouchSeen = true;
      if (widget.type == TrainingPracticeType.pinch && details.scale <= .75) {
        _success();
      } else if (widget.type == TrainingPracticeType.spread && details.scale >= 1.25) {
        _success();
      }
      return;
    }
    if (!_multiTouchSeen) _dragDelta += details.focalPointDelta;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_resolved || _multiTouchSeen) return;
    if (widget.type == TrainingPracticeType.swipe && _dragDelta.distance >= 48) {
      _success();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF07101E),
                      foregroundColor: ReactColors.textPrimary,
                      side: const BorderSide(color: Color(0xFF1E3552)),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const Spacer(),
                  const Text(
                    'COMMAND TRAINING',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const Spacer(),
              Text(
                _title,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                onDoubleTap: _handleDoubleTap,
                onLongPress: _handleLongPress,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF07111D),
                    border: Border.all(color: ReactColors.electricBlueBright, width: 3),
                  ),
                  child: Icon(_icon, color: ReactColors.electricBlueBright, size: 92),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  _status,
                  key: ValueKey(_status),
                  style: TextStyle(
                    color: _status == 'TRY AGAIN' ? ReactColors.coral : ReactColors.lime,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_successes SUCCESSFUL REPS',
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              const Text(
                'Complete 3 clean reps to master this command.',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
