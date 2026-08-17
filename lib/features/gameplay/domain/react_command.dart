import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/cosmetics/react_cosmetics.dart';

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
    ReactCommand.doubleTap => 'TAP TWICE',
    ReactCommand.hold => 'PRESS AND HOLD',
    ReactCommand.swipeLeft => 'SWIPE TO THE LEFT',
    ReactCommand.swipeRight => 'SWIPE TO THE RIGHT',
    ReactCommand.swipeUp => 'SWIPE UPWARD',
    ReactCommand.swipeDown => 'SWIPE DOWNWARD',
    ReactCommand.pinch => 'MOVE TWO FINGERS TOGETHER',
    ReactCommand.spread => 'MOVE TWO FINGERS APART',
  };

  /// Glitch remains a cosmetic treatment only. Command wording and meaning
  /// stay identical to CORE so players never have to decode a skin while
  /// reacting under time pressure.
  bool get usesGlitchVisuals =>
      ReactCosmetics.currentCommandStyle == ReactCommandStyle.glitch;

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

  double get timingMultiplier => switch (this) {
    ReactCommand.tap => 1.0,
    ReactCommand.doubleTap => 1.10,
    ReactCommand.hold => 1.22,
    ReactCommand.swipeLeft ||
    ReactCommand.swipeRight ||
    ReactCommand.swipeUp ||
    ReactCommand.swipeDown => 1.0,
    ReactCommand.pinch || ReactCommand.spread => 1.18,
  };

  int get minimumReactionWindowMs => switch (this) {
    ReactCommand.tap => 650,
    ReactCommand.doubleTap => 900,
    ReactCommand.hold => 1000,
    ReactCommand.swipeLeft ||
    ReactCommand.swipeRight ||
    ReactCommand.swipeUp ||
    ReactCommand.swipeDown => 750,
    ReactCommand.pinch || ReactCommand.spread => 1050,
  };

  int reactionWindowMs(int baseMs) =>
      max(minimumReactionWindowMs, (baseMs * timingMultiplier).round());
}
