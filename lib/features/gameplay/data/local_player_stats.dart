import 'package:shared_preferences/shared_preferences.dart';

import '../domain/react_run_history_entry.dart';
import '../domain/react_run_result.dart';

class LocalPlayerStats {
  LocalPlayerStats._();

  static String _bestKey(ReactGameMode mode) => 'best_${mode.name}';
  static String _modeRunsKey(ReactGameMode mode) => 'mode_runs_${mode.name}';
  static String _modeCommandsKey(ReactGameMode mode) => 'mode_commands_${mode.name}';
  static String _modeResponseMsKey(ReactGameMode mode) => 'mode_response_ms_${mode.name}';

  static const _runsKey = 'runs_played';
  static const _dailyLastPlayedKey = 'daily_last_played';
  static const _dailyStreakKey = 'daily_streak';
  static const _historyKey = 'recent_run_history';
  static const _historyLimit = 12;

  static Future<int> bestFor(ReactGameMode mode) async {
    if (mode == ReactGameMode.passIt) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey(mode)) ?? 0;
  }

  static Future<int> runsPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_runsKey) ?? 0;
  }

  static Future<int> runsFor(ReactGameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_modeRunsKey(mode)) ?? 0;
  }

  static Future<int> successfulCommandsFor(ReactGameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_modeCommandsKey(mode)) ?? 0;
  }

  static Future<double> averageReactionSecondsFor(ReactGameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final commands = prefs.getInt(_modeCommandsKey(mode)) ?? 0;
    if (commands <= 0) return 0;

    final totalResponseMs = prefs.getInt(_modeResponseMsKey(mode)) ?? 0;
    return (totalResponseMs / commands) / 1000;
  }

  static Future<int> totalSuccessfulCommands() async {
    final prefs = await SharedPreferences.getInstance();
    var total = 0;
    for (final mode in ReactGameMode.values) {
      total += prefs.getInt(_modeCommandsKey(mode)) ?? 0;
    }
    return total;
  }

  static Future<List<ReactRunHistoryEntry>> recentRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_historyKey) ?? const <String>[];

    return rawEntries
        .map(ReactRunHistoryEntry.tryDecode)
        .whereType<ReactRunHistoryEntry>()
        .take(_historyLimit)
        .toList(growable: false);
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

  static Future<bool> recordResult(ReactRunResult result) async {
    final prefs = await SharedPreferences.getInstance();
    var isNewBest = false;

    if (result.mode != ReactGameMode.passIt) {
      final currentBest = prefs.getInt(_bestKey(result.mode)) ?? 0;
      if (result.score > currentBest) {
        await prefs.setInt(_bestKey(result.mode), result.score);
        isNewBest = true;
      }
    }

    await prefs.setInt(_runsKey, (prefs.getInt(_runsKey) ?? 0) + 1);
    await prefs.setInt(
      _modeRunsKey(result.mode),
      (prefs.getInt(_modeRunsKey(result.mode)) ?? 0) + 1,
    );

    if (result.successfulCommands > 0) {
      final previousCommands = prefs.getInt(_modeCommandsKey(result.mode)) ?? 0;
      final previousResponseMs = prefs.getInt(_modeResponseMsKey(result.mode)) ?? 0;
      final runResponseMs =
          (result.averageTimeSeconds * 1000 * result.successfulCommands).round();

      await prefs.setInt(
        _modeCommandsKey(result.mode),
        previousCommands + result.successfulCommands,
      );
      await prefs.setInt(
        _modeResponseMsKey(result.mode),
        previousResponseMs + runResponseMs,
      );
    }

    await _recordHistory(prefs, result);

    if (result.mode == ReactGameMode.daily) {
      await _recordDaily(prefs);
    }

    return isNewBest;
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (final mode in ReactGameMode.values) {
      await prefs.remove(_bestKey(mode));
      await prefs.remove(_modeRunsKey(mode));
      await prefs.remove(_modeCommandsKey(mode));
      await prefs.remove(_modeResponseMsKey(mode));
    }

    await prefs.remove(_runsKey);
    await prefs.remove(_dailyLastPlayedKey);
    await prefs.remove(_dailyStreakKey);
    await prefs.remove(_historyKey);
  }

  static Future<void> _recordHistory(
    SharedPreferences prefs,
    ReactRunResult result,
  ) async {
    final current = prefs.getStringList(_historyKey) ?? const <String>[];
    final next = <String>[
      ReactRunHistoryEntry.fromResult(result).encode(),
      ...current,
    ].take(_historyLimit).toList(growable: false);

    await prefs.setStringList(_historyKey, next);
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
