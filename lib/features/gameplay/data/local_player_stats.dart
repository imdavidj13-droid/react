import 'package:shared_preferences/shared_preferences.dart';

import '../domain/react_run_result.dart';

class LocalPlayerStats {
  LocalPlayerStats._();

  static String _bestKey(ReactGameMode mode) => 'best_${mode.name}';
  static const _runsKey = 'runs_played';
  static const _dailyLastPlayedKey = 'daily_last_played';
  static const _dailyStreakKey = 'daily_streak';

  static Future<int> bestFor(ReactGameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey(mode)) ?? 0;
  }

  static Future<int> runsPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_runsKey) ?? 0;
  }

  static Future<int> dailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyStreakKey) ?? 0;
  }

  static Future<bool> hasPlayedDailyToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dailyLastPlayedKey) == _dateKey(DateTime.now());
  }

  static Future<void> markDailyAttemptStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await _recordDaily(prefs);
  }

  static Future<void> recordResult(ReactRunResult result) async {
    final prefs = await SharedPreferences.getInstance();

    final currentBest = prefs.getInt(_bestKey(result.mode)) ?? 0;
    if (result.score > currentBest) {
      await prefs.setInt(_bestKey(result.mode), result.score);
    }

    await prefs.setInt(_runsKey, (prefs.getInt(_runsKey) ?? 0) + 1);

    if (result.mode == ReactGameMode.daily) {
      await _recordDaily(prefs);
    }
  }

  static Future<void> _recordDaily(SharedPreferences prefs) async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final previous = prefs.getString(_dailyLastPlayedKey);

    if (previous == todayKey) return;

    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    final currentStreak = prefs.getInt(_dailyStreakKey) ?? 0;
    final nextStreak = previous == yesterdayKey ? currentStreak + 1 : 1;

    await prefs.setString(_dailyLastPlayedKey, todayKey);
    await prefs.setInt(_dailyStreakKey, nextStreak);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
