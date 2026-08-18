import 'package:shared_preferences/shared_preferences.dart';

import '../domain/react_variant_mode.dart';

abstract final class LocalVariantModeStats {
  static String _bestKey(ReactVariantMode mode) => 'variant_best_${mode.id}';
  static String _playsKey(ReactVariantMode mode) => 'variant_plays_${mode.id}';

  static Future<int> best(ReactVariantMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey(mode)) ?? 0;
  }

  static Future<int> plays(ReactVariantMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_playsKey(mode)) ?? 0;
  }

  static Future<bool> record(ReactVariantMode mode, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_bestKey(mode)) ?? 0;
    await prefs.setInt(_playsKey(mode), (prefs.getInt(_playsKey(mode)) ?? 0) + 1);
    if (score <= current) return false;
    await prefs.setInt(_bestKey(mode), score);
    return true;
  }
}
