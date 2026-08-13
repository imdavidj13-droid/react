import 'dart:async';

import 'package:flutter/services.dart';

import '../settings/react_settings.dart';

enum ReactSoundCue {
  command,
  success,
  miss,
  lifeLost,
  blitzWarning,
  handoff,
  completed,
}

/// Single audio entry point for the game.
///
/// These are deliberately temporary development sounds. They use Flutter's
/// built-in platform system sounds so the game has audible feedback without
/// committing any final audio assets or adding an audio package dependency.
/// When the real sound pack is chosen, only this controller needs replacing.
abstract final class ReactAudio {
  static bool get enabled => ReactSettings.soundEnabled;

  static Future<void> play(ReactSoundCue cue) async {
    if (!enabled) return;

    switch (cue) {
      case ReactSoundCue.command:
        await _click();
        return;
      case ReactSoundCue.success:
        await _click();
        await _delay(45);
        if (enabled) await _click();
        return;
      case ReactSoundCue.miss:
        await _alert();
        return;
      case ReactSoundCue.lifeLost:
        await _alert();
        await _delay(85);
        if (enabled) await _click();
        return;
      case ReactSoundCue.blitzWarning:
        await _alert();
        await _delay(110);
        if (enabled) await _alert();
        return;
      case ReactSoundCue.handoff:
        await _click();
        await _delay(75);
        if (enabled) await _click();
        return;
      case ReactSoundCue.completed:
        await _alert();
        await _delay(90);
        if (enabled) await _click();
        await _delay(70);
        if (enabled) await _click();
        return;
    }
  }

  static Future<void> _click() => SystemSound.play(SystemSoundType.click);

  static Future<void> _alert() => SystemSound.play(SystemSoundType.alert);

  static Future<void> _delay(int milliseconds) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));
}
