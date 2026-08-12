import 'package:shared_preferences/shared_preferences.dart';

class ReactSettings {
  ReactSettings._();

  static const _soundKey = 'settings_sound_enabled';
  static const _visualEffectsKey = 'settings_visual_effects_enabled';

  static bool soundEnabled = true;
  static bool visualEffectsEnabled = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool(_soundKey) ?? true;
    visualEffectsEnabled = prefs.getBool(_visualEffectsKey) ?? true;
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
}
