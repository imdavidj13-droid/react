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

  static Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
    if (value) await soundPreview?.call();
  }

  static Future<void> setVisualEffectsEnabled(bool value) async {
    visualEffectsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visualEffectsKey, value);
  }

  static Future<void> setPassItPlayerCount(int value) async {
    final safeValue = value.clamp(2, 4).toInt();
    passItPlayerCount = safeValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_passItPlayerCountKey, safeValue);
  }

  static Future<void> setDailyDevOverrideEnabled(bool value) async {
    dailyDevOverrideEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyDevOverrideKey, value);
  }

  static Future<void> setDailyDevModifier(String value) async {
    dailyDevModifier = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyDevModifierKey, value);
  }

  static Future<void> setHowToPlayCompleted(bool value) async {
    howToPlayCompleted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_howToPlayCompletedKey, value);
  }
}
