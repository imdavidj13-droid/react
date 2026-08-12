import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/react_command.dart';

class ReactGestureSurface extends StatefulWidget {
  const ReactGestureSurface({
    required this.enabled,
    required this.expectedCommand,
    required this.onCommand,
    required this.child,
    super.key,
  });

  final bool enabled;
  final ReactCommand expectedCommand;
  final ValueChanged<ReactCommand> onCommand;
  final Widget child;

  @override
  State<ReactGestureSurface> createState() => _ReactGestureSurfaceState();
}

class _ReactGestureSurfaceState extends State<ReactGestureSurface> {
  static const _minimumSwipeDistance = 48.0;
  static const _minimumPinchSpreadDelta = 22.0;
  static const _pinchRatio = 0.84;
  static const _spreadRatio = 1.16;
  static const _doubleTapWindow = Duration(milliseconds: 285);
  static const _holdDuration = Duration(milliseconds: 360);

  final Map<int, Offset> _pointers = <int, Offset>{};

  Offset? _primaryStart;
  Offset _primaryDelta = Offset.zero;
  double? _twoFingerStartDistance;
  DateTime? _primaryDownAt;
  DateTime? _firstTapAt;
  Timer? _doubleTapTimer;
  Timer? _holdTimer;
  int? _primaryPointer;
  bool _multiTouchSeen = false;
  bool _resolved = false;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _emit(ReactCommand command) {
    if (!widget.enabled || _resolved) return;
    _resolved = true;
    _doubleTapTimer?.cancel();
    _holdTimer?.cancel();
    widget.onCommand(command);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;

    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length == 1) {
      _primaryPointer = event.pointer;
      _primaryStart = event.localPosition;
      _primaryDelta = Offset.zero;
      _primaryDownAt = DateTime.now();
      _resolved = false;

      if (widget.expectedCommand == ReactCommand.hold) {
        _holdTimer?.cancel();
        _holdTimer = Timer(_holdDuration, () {
          if (!mounted || !widget.enabled || _resolved || _multiTouchSeen) {
            return;
          }
          if (_pointers.containsKey(_primaryPointer)) {
            _emit(ReactCommand.hold);
          }
        });
      }
      return;
    }

    if (_pointers.length >= 2) {
      _multiTouchSeen = true;
      _holdTimer?.cancel();
      _doubleTapTimer?.cancel();
      _twoFingerStartDistance = _currentTwoFingerDistance();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enabled || !_pointers.containsKey(event.pointer) || _resolved) {
      return;
    }

    final previous = _pointers[event.pointer]!;
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length >= 2) {
      final startDistance = _twoFingerStartDistance;
      final currentDistance = _currentTwoFingerDistance();
      if (startDistance == null || currentDistance == null || startDistance < 24) {
        return;
      }

      final distanceDelta = currentDistance - startDistance;
      final ratio = currentDistance / startDistance;

      if (distanceDelta <= -_minimumPinchSpreadDelta && ratio <= _pinchRatio) {
        _emit(ReactCommand.pinch);
        return;
      }

      if (distanceDelta >= _minimumPinchSpreadDelta && ratio >= _spreadRatio) {
        _emit(ReactCommand.spread);
      }
      return;
    }

    if (event.pointer == _primaryPointer) {
      _primaryDelta += event.localPosition - previous;
      if (_primaryDelta.distance > 12) {
        _holdTimer?.cancel();
      }
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (!widget.enabled) {
      _pointers.remove(event.pointer);
      return;
    }

    final wasPrimary = event.pointer == _primaryPointer;
    _pointers.remove(event.pointer);

    if (_pointers.length < 2) {
      _twoFingerStartDistance = null;
    }

    if (!wasPrimary || _resolved || _multiTouchSeen) {
      if (_pointers.isEmpty) _resetGestureState();
      return;
    }

    _holdTimer?.cancel();

    final dx = _primaryDelta.dx;
    final dy = _primaryDelta.dy;
    final horizontal = dx.abs() >= dy.abs();
    final distance = horizontal ? dx.abs() : dy.abs();

    if (distance >= _minimumSwipeDistance) {
      final command = horizontal
          ? (dx < 0 ? ReactCommand.swipeLeft : ReactCommand.swipeRight)
          : (dy < 0 ? ReactCommand.swipeUp : ReactCommand.swipeDown);
      _emit(command);
      _resetGestureState();
      return;
    }

    final downAt = _primaryDownAt;
    if (downAt == null) {
      _resetGestureState();
      return;
    }

    if (widget.expectedCommand == ReactCommand.tap) {
      _emit(ReactCommand.tap);
      _resetGestureState();
      return;
    }

    if (widget.expectedCommand == ReactCommand.doubleTap) {
      final now = DateTime.now();
      final firstTapAt = _firstTapAt;

      if (firstTapAt != null && now.difference(firstTapAt) <= _doubleTapWindow) {
        _firstTapAt = null;
        _emit(ReactCommand.doubleTap);
        _resetGestureState();
        return;
      }

      _firstTapAt = now;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(_doubleTapWindow, () {
        if (!mounted || _resolved || !widget.enabled) return;
        _firstTapAt = null;
        _emit(ReactCommand.tap);
      });
      _resetGestureState(preserveDoubleTap: true);
      return;
    }

    if (DateTime.now().difference(downAt) >= _holdDuration) {
      _emit(ReactCommand.hold);
    } else {
      _emit(ReactCommand.tap);
    }
    _resetGestureState();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) _resetGestureState();
  }

  double? _currentTwoFingerDistance() {
    if (_pointers.length < 2) return null;
    final positions = _pointers.values.take(2).toList(growable: false);
    return (positions[0] - positions[1]).distance;
  }

  void _resetGestureState({bool preserveDoubleTap = false}) {
    _primaryPointer = null;
    _primaryStart = null;
    _primaryDelta = Offset.zero;
    _primaryDownAt = null;
    _multiTouchSeen = false;
    _holdTimer?.cancel();
    if (!preserveDoubleTap) {
      _firstTapAt = null;
      _doubleTapTimer?.cancel();
    }
    if (_pointers.isEmpty) {
      _resolved = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
