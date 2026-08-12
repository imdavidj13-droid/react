import 'package:flutter/material.dart';

enum ReactCommand {
  tap,
  doubleTap,
  hold,
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  pinch,
  spread,
}

extension ReactCommandUi on ReactCommand {
  String get title => switch (this) {
        ReactCommand.tap => 'TAP IT',
        ReactCommand.doubleTap => 'DOUBLE TAP',
        ReactCommand.hold => 'HOLD IT',
        ReactCommand.swipeLeft => 'SWIPE LEFT',
        ReactCommand.swipeRight => 'SWIPE RIGHT',
        ReactCommand.swipeUp => 'SWIPE UP',
        ReactCommand.swipeDown => 'SWIPE DOWN',
        ReactCommand.pinch => 'PINCH IT',
        ReactCommand.spread => 'SPREAD IT',
      };

  String get hint => switch (this) {
        ReactCommand.tap => 'TAP ONCE',
        ReactCommand.doubleTap => 'TAP TWICE QUICKLY',
        ReactCommand.hold => 'PRESS AND HOLD',
        ReactCommand.swipeLeft => 'SWIPE TO THE LEFT',
        ReactCommand.swipeRight => 'SWIPE TO THE RIGHT',
        ReactCommand.swipeUp => 'SWIPE UPWARD',
        ReactCommand.swipeDown => 'SWIPE DOWNWARD',
        ReactCommand.pinch => 'MOVE TWO FINGERS TOGETHER',
        ReactCommand.spread => 'MOVE TWO FINGERS APART',
      };

  IconData get icon => switch (this) {
        ReactCommand.tap => Icons.touch_app_rounded,
        ReactCommand.doubleTap => Icons.ads_click_rounded,
        ReactCommand.hold => Icons.pan_tool_alt_rounded,
        ReactCommand.swipeLeft => Icons.arrow_back_rounded,
        ReactCommand.swipeRight => Icons.arrow_forward_rounded,
        ReactCommand.swipeUp => Icons.arrow_upward_rounded,
        ReactCommand.swipeDown => Icons.arrow_downward_rounded,
        ReactCommand.pinch => Icons.close_fullscreen_rounded,
        ReactCommand.spread => Icons.open_in_full_rounded,
      };
}
