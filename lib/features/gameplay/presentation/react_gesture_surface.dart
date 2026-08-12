import 'dart:async';

import 'package:flutter/gestures.dart';
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
  static const _maximumTapMovement = 18.0;
  static const _minimumPinchSpreadDelta = 22.0;
  static const _pinchRatio = 0.84;
  static const _spreadRatio = 1.16;
  static const _holdDuration = Duration(milliseconds: 420);
  static const _doubleTapWindow = Duration(milliseconds: 300);
  static const _maximumDoubleTapDistance = 42.0;

  final Map<int, Offset> _pointers = <int, Offset>{};

  int? _primaryPointer;
  Offset? _primaryStart;
  Offset? _primaryLast;
  double? _twoFingerStartDistance;
  bool _resolved = false;
  bool _multiTouchSeen = false;

  int _tapCount = 0;
  Offset? _firstTapPosition;
  Timer? _holdTimer;
  Timer? _doubleTapTimer;

  @override
  void didUpdateWidget(covariant ReactGestureSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled ||
        oldWidget.expectedCommand != widget.expectedCommand ||
        oldWidget.enabled != widget.enabled) {
      _resetGestureState();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _resetGestureState() {
    _holdTimer?.cancel();
    _doubleTapTimer?.cancel();
    _pointers.clear();
    _primaryPointer = null;
    _primaryStart = null;
    _primaryLast = null;
    _twoFingerStartDistance = null;
    _resolved = false;
    _multiTouchSeen = false;
    _tapCount = 0;
    _firstTapPosition = null;
  }

  void _resolve(ReactCommand command) {
    if (!widget.enabled || _resolved) return;
    _resolved = true;
    _holdTimer?.cancel();
    _doubleTapTimer?.cancel();
    widget.onCommand(command);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled || _resolved) return;

    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length == 1) {
      _primaryPointer = event.pointer;
      _primaryStart = event.localPosition;
      _primaryLast = event.localPosition;
      _scheduleHold();
      return;
    }

    if (_pointers.length == 2) {
      _multiTouchSeen = true;
      _holdTimer?.cancel();
      _twoFingerStartDistance = _currentTwoFingerDistance();
    }
  }

  void _scheduleHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDuration, () {
      if (!mounted || _resolved || _multiTouchSeen || _pointers.length != 1) {
        return;
      }
      final start = _primaryStart;
      final last = _primaryLast;
      if (start == null || last == null) return;
      if ((last - start).distance <= _maximumTapMovement) {
        _resolve(ReactCommand.hold);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enabled || _resolved || !_pointers.containsKey(event.pointer)) {
      return;
    }

    _pointers[event.pointer] = event.localPosition;
    if (event.pointer == _primaryPointer) {
      _primaryLast = event.localPosition;
      final start = _primaryStart;
      if (start != null &&
          (event.localPosition - start).distance > _maximumTapMovement) {
        _holdTimer?.cancel();
      }
    }

    if (_pointers.length < 2) return;

    final startDistance = _twoFingerStartDistance;
    final currentDistance = _currentTwoFingerDistance();
    if (startDistance == null || currentDistance == null || startDistance < 24) {
      return;
    }

    final delta = currentDistance - startDistance;
    final ratio = currentDistance / startDistance;

    if (delta <= -_minimumPinchSpreadDelta && ratio <= _pinchRatio) {
      _resolve(ReactCommand.pinch);
      return;
    }

    if (delta >= _minimumPinchSpreadDelta && ratio >= _spreadRatio) {
      _resolve(ReactCommand.spread);
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (!widget.enabled) return;

    final wasPrimary = event.pointer == _primaryPointer;
    final start = _primaryStart;
    final end = event.localPosition;
    _pointers.remove(event.pointer);

    if (_resolved) {
      if (_pointers.isEmpty) _clearPointersOnly();
      return;
    }

    if (_multiTouchSeen) {
      if (_pointers.isEmpty) {
        // Two fingers were used but no valid pinch/spread threshold was met.
        // Treat that as a wrong two-finger gesture by resolving the opposite
        // multi-touch command to the expected one when possible.
        final fallback = widget.expectedCommand == ReactCommand.pinch
            ? ReactCommand.spread
            : ReactCommand.pinch;
        _resolve(fallback);
        _clearPointersOnly();
      }
      return;
    }

    if (!wasPrimary || start == null) return;
    _holdTimer?.cancel();

    final delta = end - start;
    if (delta.distance >= _minimumSwipeDistance) {
      final horizontal = delta.dx.abs() >= delta.dy.abs();
      _resolve(
        horizontal
            ? (delta.dx < 0 ? ReactCommand.swipeLeft : ReactCommand.swipeRight)
            : (delta.dy < 0 ? ReactCommand.swipeUp : ReactCommand.swipeDown),
      );
      _clearPointersOnly();
      return;
    }

    if (delta.distance <= _maximumTapMovement) {
      _handleTap(end);
    }

    if (_pointers.isEmpty) _clearPointersOnly(preserveTapSequence: true);
  }

  void _handleTap(Offset position) {
    if (widget.expectedCommand != ReactCommand.doubleTap) {
      _resolve(ReactCommand.tap);
      return;
    }

    if (_tapCount == 0) {
      _tapCount = 1;
      _firstTapPosition = position;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(_doubleTapWindow, () {
        if (!mounted || _resolved) return;
        _resolve(ReactCommand.tap);
      });
      return;
    }

    final first = _firstTapPosition;
    if (first != null &&
        (position - first).distance <= _maximumDoubleTapDistance) {
      _resolve(ReactCommand.doubleTap);
    } else {
      _resolve(ReactCommand.tap);
    }
  }

  void _clearPointersOnly({bool preserveTapSequence = false}) {
    _pointers.clear();
    _primaryPointer = null;
    _primaryStart = null;
    _primaryLast = null;
    _twoFingerStartDistance = null;
    _multiTouchSeen = false;
    _holdTimer?.cancel();
    if (!preserveTapSequence) {
      _tapCount = 0;
      _firstTapPosition = null;
    }
  }

  double? _currentTwoFingerDistance() {
    if (_pointers.length < 2) return null;
    final positions = _pointers.values.take(2).toList(growable: false);
    return (positions[0] - positions[1]).distance;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: widget.child,
    );
  }
}
