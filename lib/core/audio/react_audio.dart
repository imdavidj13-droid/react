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
/// Final sound assets are intentionally not bundled yet. Gameplay code should
/// call this controller rather than loading audio directly, so the persisted
/// Sound setting and future asset implementation remain centralized.
abstract final class ReactAudio {
  static bool get enabled => ReactSettings.soundEnabled;

  static Future<void> play(ReactSoundCue cue) async {
    if (!enabled) return;

    // Audio assets will be wired here once the final sound set is chosen.
    // Keeping this intentionally silent prevents placeholder system sounds
    // from becoming part of the game's feel during development.
  }
}
