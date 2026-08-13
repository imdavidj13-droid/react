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
  static const _minimumPinchSpreadDelta = 18.0;
  static const _pinchRatio = 0.88;
  static const _spreadRatio = 1.12;
  static const _doubleTapWindow = Duration(milliseconds: 420);
  static const _holdDuration = Duration(milliseconds: 360);
  static const _holdMovementTolerance = 24.0;

  final Map<int, Offset> _pointers = <int, Offset>{};

  Offset _primaryDelta = Offset.zero;
  double? _twoFingerStartDistance;
  DateTime? _primaryDownAt;
  DateTime? _firstTapAt;
  Timer? _doubleTapTimer;
  Timer? _holdTimer;
  int? _primaryPointer;
  ReactCommand? _pendingMultiTouchCommand;
  bool _multiTouchSeen = false;
  bool _holdSatisfied = false;
  bool _secondTapStartedInWindow = false;
  bool _resolved = false;
  bool _cancelled = false;

  @override
  void didUpdateWidget(covariant ReactGestureSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expectedCommand != widget.expectedCommand) {
      _doubleTapTimer?.cancel();
      _firstTapAt = null;
      _secondTapStartedInWindow = false;
    }
    if (!widget.enabled) {
      _holdTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _emit(ReactCommand command) {
    if (!widget.enabled || _resolved || _cancelled) return;
    _resolved = true;
    _doubleTapTimer?.cancel();
    _holdTimer?.cancel();
    widget.onCommand(command);
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (!widget.enabled) return;

    if (_pointers.length == 1) {
      final now = DateTime.now();
      final firstTapAt = _firstTapAt;
      _secondTapStartedInWindow = widget.expectedCommand == ReactCommand.doubleTap &&
          firstTapAt != null &&
          now.difference(firstTapAt) <= _doubleTapWindow;
      if (_secondTapStartedInWindow) {
        _doubleTapTimer?.cancel();
      }

      _primaryPointer = event.pointer;
      _primaryDelta = Offset.zero;
      _primaryDownAt = now;
      _multiTouchSeen = false;
      _holdSatisfied = false;
      _pendingMultiTouchCommand = null;
      _resolved = false;
      _cancelled = false;

      if (widget.expectedCommand == ReactCommand.hold) {
        _holdTimer?.cancel();
        _holdTimer = Timer(_holdDuration, () {
          if (!mounted ||
              !widget.enabled ||
              _resolved ||
              _multiTouchSeen ||
              _cancelled) {
            return;
          }
          if (_pointers.containsKey(_primaryPointer) &&
              _primaryDelta.distance <= _holdMovementTolerance) {
            _holdSatisfied = true;
          }
        });
      }
      return;
    }

    if (_pointers.length >= 2) {
      _multiTouchSeen = true;
      _holdTimer?.cancel();
      _holdSatisfied = false;
      _doubleTapTimer?.cancel();
      _firstTapAt = null;
      _secondTapStartedInWindow = false;
      _twoFingerStartDistance = _currentTwoFingerDistance();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;

    final previous = _pointers[event.pointer]!;
    _pointers[event.pointer] = event.localPosition;

    if (!widget.enabled || _resolved || _cancelled) return;

    if (_pointers.length >= 2) {
      if (_pendingMultiTouchCommand != null) return;

      final startDistance = _twoFingerStartDistance;
      final currentDistance = _currentTwoFingerDistance();
      if (startDistance == null || currentDistance == null || startDistance < 24) {
        return;
      }

      final distanceDelta = currentDistance - startDistance;
      final ratio = currentDistance / startDistance;

      if (distanceDelta <= -_minimumPinchSpreadDelta && ratio <= _pinchRatio) {
        _pendingMultiTouchCommand = ReactCommand.pinch;
        return;
      }

      if (distanceDelta >= _minimumPinchSpreadDelta && ratio >= _spreadRatio) {
        _pendingMultiTouchCommand = ReactCommand.spread;
      }
      return;
    }

    if (event.pointer == _primaryPointer) {
      _primaryDelta += event.localPosition - previous;
      if (_primaryDelta.distance > _holdMovementTolerance) {
        _holdTimer?.cancel();
        _holdSatisfied = false;
      }
    }
  }

  void _onPointerUp(PointerEvent event) {
    final wasPrimary = event.pointer == _primaryPointer;
    _pointers.remove(event.pointer);

    if (_cancelled) {
      if (_pointers.isEmpty) _resetGestureState();
      return;
    }

    if (_multiTouchSeen) {
      if (_pointers.isEmpty) {
        final pending = _pendingMultiTouchCommand;
        if (pending != null) {
          _emit(pending);
        }
        _resetGestureState();
      }
      return;
    }

    if (!widget.enabled) {
      if (_pointers.isEmpty) _resetGestureState();
      return;
    }

    if (!wasPrimary || _resolved) {
      if (_pointers.isEmpty) _resetGestureState();
      return;
    }

    _holdTimer?.cancel();

    final downAt = _primaryDownAt;
    if (downAt == null) {
      _resetGestureState();
      return;
    }
    final pressDuration = DateTime.now().difference(downAt);

    if (_holdSatisfied) {
      _emit(ReactCommand.hold);
      _resetGestureState();
      return;
    }

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

    if (widget.expectedCommand == ReactCommand.hold) {
      if (pressDuration >= _holdDuration &&
          _primaryDelta.distance <= _holdMovementTolerance) {
        _emit(ReactCommand.hold);
      } else {
        _emit(ReactCommand.tap);
      }
      _resetGestureState();
      return;
    }

    if (pressDuration >= _holdDuration) {
      _emit(ReactCommand.hold);
      _resetGestureState();
      return;
    }

    if (widget.expectedCommand == ReactCommand.tap) {
      _emit(ReactCommand.tap);
      _resetGestureState();
      return;
    }

    if (widget.expectedCommand == ReactCommand.doubleTap) {
      if (_secondTapStartedInWindow) {
        _firstTapAt = null;
        _secondTapStartedInWindow = false;
        _emit(ReactCommand.doubleTap);
        _resetGestureState();
        return;
      }

      final now = DateTime.now();
      _firstTapAt = now;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(_doubleTapWindow, () {
        if (!mounted || _resolved || !widget.enabled || _cancelled) return;
        _firstTapAt = null;
        _emit(ReactCommand.tap);
      });
      _resetGestureState(preserveDoubleTap: true);
      return;
    }

    _emit(ReactCommand.tap);
    _resetGestureState();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    _cancelled = true;
    _pendingMultiTouchCommand = null;
    _holdSatisfied = false;
    _holdTimer?.cancel();
    _doubleTapTimer?.cancel();
    _firstTapAt = null;
    _secondTapStartedInWindow = false;
    if (_pointers.isEmpty) _resetGestureState();
  }

  double? _currentTwoFingerDistance() {
    if (_pointers.length < 2) return null;
    final positions = _pointers.values.take(2).toList(growable: false);
    return (positions[0] - positions[1]).distance;
  }

  void _resetGestureState({bool preserveDoubleTap = false}) {
    _primaryPointer = null;
    _primaryDelta = Offset.zero;
    _primaryDownAt = null;
    _multiTouchSeen = false;
    _holdSatisfied = false;
    _pendingMultiTouchCommand = null;
    _twoFingerStartDistance = null;
    _holdTimer?.cancel();
    _cancelled = false;
    if (!preserveDoubleTap) {
      _firstTapAt = null;
      _doubleTapTimer?.cancel();
      _secondTapStartedInWindow = false;
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
