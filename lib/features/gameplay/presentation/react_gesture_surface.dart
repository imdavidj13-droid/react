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

  // Require both a proportional and absolute distance change. This makes
  // pinch/spread much easier to trigger deliberately than the old 0.72/1.28
  // ScaleUpdateDetails thresholds, without accepting normal finger jitter.
  static const _minimumPinchSpreadDelta = 22.0;
  static const _pinchRatio = 0.84;
  static const _spreadRatio = 1.16;
  static const _multiTouchTapSuppression = Duration(milliseconds: 300);

  final Map<int, Offset> _pointers = <int, Offset>{};

  Offset _dragDelta = Offset.zero;
  double? _twoFingerStartDistance;
  bool _multiTouchSeen = false;
  bool _multiTouchResolved = false;
  DateTime _suppressTapUntil = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _tapSuppressed => DateTime.now().isBefore(_suppressTapUntil);

  void _emit(ReactCommand command) {
    if (!widget.enabled ||
        _multiTouchSeen ||
        _multiTouchResolved ||
        _tapSuppressed) {
      return;
    }
    widget.onCommand(command);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length >= 2) {
      _multiTouchSeen = true;
      _multiTouchResolved = false;
      _suppressTapUntil = DateTime.now().add(_multiTouchTapSuppression);
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
      _suppressTapUntil = DateTime.now().add(_multiTouchTapSuppression);
      widget.onCommand(ReactCommand.pinch);
      return;
    }

    if (distanceDelta >= _minimumPinchSpreadDelta && ratio >= _spreadRatio) {
      _multiTouchResolved = true;
      _suppressTapUntil = DateTime.now().add(_multiTouchTapSuppression);
      widget.onCommand(ReactCommand.spread);
    }
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      _twoFingerStartDistance = null;
    }

    if (_pointers.isEmpty && _multiTouchSeen) {
      _suppressTapUntil = DateTime.now().add(_multiTouchTapSuppression);
      _multiTouchSeen = false;
      _multiTouchResolved = false;
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
    if (!widget.enabled || _multiTouchSeen || _tapSuppressed) return;

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
