import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReactSettings {
  ReactSettings._();

  static const _soundKey = 'settings_sound_enabled';
  static const _visualEffectsKey = 'settings_visual_effects_enabled';
  static const _passItPlayerCountKey = 'settings_pass_it_player_count';
  static const _dailyDevOverrideKey = 'settings_daily_dev_override_enabled';
  static const _dailyDevModifierKey = 'settings_daily_dev_modifier';
  static const _howToPlayCompletedKey = 'settings_how_to_play_completed';

  static bool soundEnabled = true;
  static bool visualEffectsEnabled = true;
  static int passItPlayerCount = 3;
  static bool dailyDevOverrideEnabled = false;
  static String dailyDevModifier = 'lightsOut';
  static bool howToPlayCompleted = false;

  // Registered by the audio controller during app startup. Keeping this as a
  // callback avoids coupling persistent settings to a concrete audio package.
  static Future<void> Function()? soundPreview;

  // Runtime-only guard used to isolate developer Daily runs from the real
  // calendar challenge. This is deliberately never persisted: a debug choice
  // must not leak into normal Daily play or a later release build.
  static bool dailyDevRunActive = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool(_soundKey) ?? true;
    visualEffectsEnabled = prefs.getBool(_visualEffectsKey) ?? true;
    passItPlayerCount =
        (prefs.getInt(_passItPlayerCountKey) ?? 3).clamp(2, 4).toInt();
    dailyDevOverrideEnabled = prefs.getBool(_dailyDevOverrideKey) ?? false;
    dailyDevModifier = prefs.getString(_dailyDevModifierKey) ?? 'lightsOut';
    howToPlayCompleted = prefs.getBool(_howToPlayCompletedKey) ?? false;
    dailyDevRunActive = false;
  }

  static Future<void> _persist(
    String description,
    Future<void> Function(SharedPreferences prefs) write,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await write(prefs);
    } catch (error) {
      debugPrint('RE△CT could not persist $description: $error');
    }
  }

  static Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    await _persist(
      'sound setting',
      (prefs) async => prefs.setBool(_soundKey, value),
    );
    if (value) {
      try {
        await soundPreview?.call();
      } catch (error) {
        debugPrint('RE△CT sound preview failed: $error');
      }
    }
  }

  static Future<void> setVisualEffectsEnabled(bool value) async {
    visualEffectsEnabled = value;
    await _persist(
      'visual-effects setting',
      (prefs) async => prefs.setBool(_visualEffectsKey, value),
    );
  }

  static Future<void> setPassItPlayerCount(int value) async {
    final safeValue = value.clamp(2, 4).toInt();
    passItPlayerCount = safeValue;
    await _persist(
      'Pass It player count',
      (prefs) async => prefs.setInt(_passItPlayerCountKey, safeValue),
    );
  }

  static Future<void> setDailyDevOverrideEnabled(bool value) async {
    dailyDevOverrideEnabled = value;
    await _persist(
      'Daily developer override',
      (prefs) async => prefs.setBool(_dailyDevOverrideKey, value),
    );
  }

  static Future<void> setDailyDevModifier(String value) async {
    dailyDevModifier = value;
    await _persist(
      'Daily developer modifier',
      (prefs) async => prefs.setString(_dailyDevModifierKey, value),
    );
  }

  static Future<void> setHowToPlayCompleted(bool value) async {
    howToPlayCompleted = value;
    await _persist(
      'How To Play completion',
      (prefs) async => prefs.setBool(_howToPlayCompletedKey, value),
    );
  }
}
