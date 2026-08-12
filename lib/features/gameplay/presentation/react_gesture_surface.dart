import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../domain/react_command.dart';

class ReactGestureSurface extends StatefulWidget {
  const ReactGestureSurface({
    required this.enabled,
    required this.onCommand,
    required this.child,
    super.key,
  });

  final bool enabled;
  final ValueChanged<ReactCommand> onCommand;
  final Widget child;

  @override
  State<ReactGestureSurface> createState() => _ReactGestureSurfaceState();
}

class _ReactGestureSurfaceState extends State<ReactGestureSurface> {
  static const _minimumSwipeDistance = 48.0;

  // Pinch/spread now uses the actual distance between two pointers rather than
  // GestureDetector's scale ratio. Both an absolute and proportional movement
  // are required, which keeps it responsive without making small finger jitter
  // count as a completed command.
  static const _minimumPinchSpreadDelta = 22.0;
  static const _pinchRatio = 0.84;
  static const _spreadRatio = 1.16;

  final Map<int, Offset> _pointers = <int, Offset>{};

  Offset _dragDelta = Offset.zero;
  double? _twoFingerStartDistance;
  bool _multiTouchSeen = false;
  bool _multiTouchResolved = false;

  void _emit(ReactCommand command) {
    if (!widget.enabled || _multiTouchSeen || _multiTouchResolved) return;
    widget.onCommand(command);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length >= 2) {
      _multiTouchSeen = true;
      _multiTouchResolved = false;
      _twoFingerStartDistance = _currentTwoFingerDistance();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enabled || !_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length < 2 || _multiTouchResolved) return;

    final startDistance = _twoFingerStartDistance;
    final currentDistance = _currentTwoFingerDistance();
    if (startDistance == null ||
        currentDistance == null ||
        startDistance < 24) {
      return;
    }

    final distanceDelta = currentDistance - startDistance;
    final ratio = currentDistance / startDistance;

    if (distanceDelta <= -_minimumPinchSpreadDelta && ratio <= _pinchRatio) {
      _multiTouchResolved = true;
      widget.onCommand(ReactCommand.pinch);
      return;
    }

    if (distanceDelta >= _minimumPinchSpreadDelta && ratio >= _spreadRatio) {
      _multiTouchResolved = true;
      widget.onCommand(ReactCommand.spread);
    }
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      _twoFingerStartDistance = null;
    }

    // Keep _multiTouchSeen true until every finger has left the surface. This
    // prevents a completed pinch/spread from subsequently being interpreted as
    // a single tap by GestureDetector.
    if (_pointers.isEmpty) {
      Future<void>.microtask(() {
        if (!mounted || _pointers.isNotEmpty) return;
        _multiTouchSeen = false;
        _multiTouchResolved = false;
      });
    }
  }

  double? _currentTwoFingerDistance() {
    if (_pointers.length < 2) return null;
    final positions = _pointers.values.take(2).toList(growable: false);
    return (positions[0] - positions[1]).distance;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled || _multiTouchSeen) return;
    _dragDelta = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _multiTouchSeen) return;
    _dragDelta += details.delta;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled || _multiTouchSeen) return;

    final dx = _dragDelta.dx;
    final dy = _dragDelta.dy;
    final horizontal = dx.abs() >= dy.abs();
    final distance = horizontal ? dx.abs() : dy.abs();
    if (distance < _minimumSwipeDistance) return;

    final command = horizontal
        ? (dx < 0 ? ReactCommand.swipeLeft : ReactCommand.swipeRight)
        : (dy < 0 ? ReactCommand.swipeUp : ReactCommand.swipeDown);
    widget.onCommand(command);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? () => _emit(ReactCommand.tap) : null,
        onDoubleTap:
            widget.enabled ? () => _emit(ReactCommand.doubleTap) : null,
        onLongPress: widget.enabled ? () => _emit(ReactCommand.hold) : null,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: widget.child,
      ),
    );
  }
}
