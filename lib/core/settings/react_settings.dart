import 'package:shared_preferences/shared_preferences.dart';

class ReactSettings {
  ReactSettings._();

  static const _soundKey = 'settings_sound_enabled';
  static const _visualEffectsKey = 'settings_visual_effects_enabled';
  static const _passItPlayerCountKey = 'settings_pass_it_player_count';

  static bool soundEnabled = true;
  static bool visualEffectsEnabled = true;
  static int passItPlayerCount = 3;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool(_soundKey) ?? true;
    visualEffectsEnabled = prefs.getBool(_visualEffectsKey) ?? true;
    passItPlayerCount = (prefs.getInt(_passItPlayerCountKey) ?? 3).clamp(2, 4);
  }

  static Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  static Future<void> setVisualEffectsEnabled(bool value) async {
    visualEffectsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visualEffectsKey, value);
  }

  static Future<void> setPassItPlayerCount(int value) async {
    final safeValue = value.clamp(2, 4);
    passItPlayerCount = safeValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_passItPlayerCountKey, safeValue);
  }
}
