import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/react_settings.dart';
import '../../daily/domain/daily_challenge.dart';
import '../../daily/domain/daily_history_entry.dart';
import '../domain/react_command.dart';
import '../domain/react_command_performance.dart';
import '../domain/react_run_history_entry.dart';
import '../domain/react_run_result.dart';

class LocalPlayerStats {
  LocalPlayerStats._();

  static String _bestKey(ReactGameMode mode) => 'best_${mode.name}';
  static String _modeRunsKey(ReactGameMode mode) => 'mode_runs_${mode.name}';
  static String _modeCommandsKey(ReactGameMode mode) => 'mode_commands_${mode.name}';
  static String _modeResponseMsKey(ReactGameMode mode) => 'mode_response_ms_${mode.name}';
  static String _commandAttemptsKey(ReactCommand command) =>
      'command_attempts_${command.name}';
  static String _commandSuccessesKey(ReactCommand command) =>
      'command_successes_${command.name}';
  static String _commandResponseMsKey(ReactCommand command) =>
      'command_response_ms_${command.name}';
  static String _dailyModifierBestKey(DailyModifier modifier) =>
      'daily_best_${modifier.name}';

  static const _runsKey = 'runs_played';
  static const _dailyLastPlayedKey = 'daily_last_played';
  static const _dailyStreakKey = 'daily_streak';
  static const _historyKey = 'recent_run_history';
  static const _dailyHistoryKey = 'daily_history';
  static const _historyLimit = 12;
  static const _dailyHistoryLimit = 14;

  static Future<int> bestFor(ReactGameMode mode) async {
    if (mode == ReactGameMode.passIt) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey(mode)) ?? 0;
  }

  static Future<int> dailyBestForModifier(DailyModifier modifier) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyModifierBestKey(modifier)) ?? 0;
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

  static Future<List<ReactCommandPerformance>> commandPerformance() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final command in ReactCommand.values)
        ReactCommandPerformance(
          command: command,
          attempts: prefs.getInt(_commandAttemptsKey(command)) ?? 0,
          successes: prefs.getInt(_commandSuccessesKey(command)) ?? 0,
          totalResponseMs: prefs.getInt(_commandResponseMsKey(command)) ?? 0,
        ),
    ];
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

  static Future<List<DailyHistoryEntry>> dailyHistoryThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _decodeDailyHistory(prefs);
    final today = _normalizedToday();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return [
      for (var offset = 0; offset < 7; offset++)
        _dailyHistoryForDate(monday.add(Duration(days: offset)), saved),
    ];
  }

  static Future<List<DailyHistoryEntry>> dailyHistoryLast7() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _decodeDailyHistory(prefs);
    final today = _normalizedToday();

    return [
      for (var offset = 6; offset >= 0; offset--)
        _dailyHistoryForDate(today.subtract(Duration(days: offset)), saved),
    ];
  }

  static Map<String, DailyHistoryEntry> _decodeDailyHistory(
    SharedPreferences prefs,
  ) {
    final saved = <String, DailyHistoryEntry>{};
    for (final raw in prefs.getStringList(_dailyHistoryKey) ?? const <String>[]) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final entry = DailyHistoryEntry.tryFromJson(decoded);
        if (entry != null) saved[entry.dateKey] = entry;
      } catch (_) {
        // Ignore corrupt local history rows individually.
      }
    }
    return saved;
  }

  static DailyHistoryEntry _dailyHistoryForDate(
    DateTime date,
    Map<String, DailyHistoryEntry> saved,
  ) {
    final key = _dateKey(date);
    final existing = saved[key];
    if (existing != null) return existing;
    return DailyHistoryEntry(
      date: date,
      modifier: DailyChallenge.forDate(date).modifier,
      attempted: false,
    );
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

    final today = _normalizedToday();
    final existing = _decodeDailyHistory(prefs)[_dateKey(today)];
    if (existing?.score != null || existing?.outcome != null) return;

    await _upsertDailyHistory(
      prefs,
      DailyHistoryEntry(
        date: today,
        modifier: DailyChallenge.forDate(today).modifier,
        attempted: true,
      ),
    );
  }

  static Future<bool> recordResult(ReactRunResult result) async {
    if (result.mode == ReactGameMode.daily && ReactSettings.dailyDevRunActive) {
      return false;
    }

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

    for (final performance in result.commandPerformance.values) {
      if (performance.attempts <= 0) continue;
      final command = performance.command;
      await prefs.setInt(
        _commandAttemptsKey(command),
        (prefs.getInt(_commandAttemptsKey(command)) ?? 0) + performance.attempts,
      );
      await prefs.setInt(
        _commandSuccessesKey(command),
        (prefs.getInt(_commandSuccessesKey(command)) ?? 0) + performance.successes,
      );
      await prefs.setInt(
        _commandResponseMsKey(command),
        (prefs.getInt(_commandResponseMsKey(command)) ?? 0) +
            performance.totalResponseMs,
      );
    }

    await _recordHistory(prefs, result);

    if (result.mode == ReactGameMode.daily) {
      await _recordDaily(prefs);
      final today = _normalizedToday();
      final modifier = DailyChallenge.forDate(today).modifier;
      final currentModifierBest =
          prefs.getInt(_dailyModifierBestKey(modifier)) ?? 0;
      if (result.score > currentModifierBest) {
        await prefs.setInt(_dailyModifierBestKey(modifier), result.score);
      }

      final existing = _decodeDailyHistory(prefs)[_dateKey(today)];
      final shouldReplaceDailyHistory =
          existing?.score == null || result.score > existing!.score!;
      if (shouldReplaceDailyHistory) {
        await _upsertDailyHistory(
          prefs,
          DailyHistoryEntry(
            date: today,
            modifier: modifier,
            attempted: true,
            score: result.score,
            outcome: result.outcome,
          ),
        );
      }
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
    for (final command in ReactCommand.values) {
      await prefs.remove(_commandAttemptsKey(command));
      await prefs.remove(_commandSuccessesKey(command));
      await prefs.remove(_commandResponseMsKey(command));
    }
    for (final modifier in DailyModifier.values) {
      await prefs.remove(_dailyModifierBestKey(modifier));
    }

    await prefs.remove(_runsKey);
    await prefs.remove(_dailyLastPlayedKey);
    await prefs.remove(_dailyStreakKey);
    await prefs.remove(_historyKey);
    await prefs.remove(_dailyHistoryKey);
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

  static Future<void> _upsertDailyHistory(
    SharedPreferences prefs,
    DailyHistoryEntry entry,
  ) async {
    final decoded = <DailyHistoryEntry>[];
    for (final raw in prefs.getStringList(_dailyHistoryKey) ?? const <String>[]) {
      try {
        final item = DailyHistoryEntry.tryFromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (item != null && item.dateKey != entry.dateKey) decoded.add(item);
      } catch (_) {
        // Ignore corrupt rows instead of invalidating the complete history.
      }
    }

    final next = <DailyHistoryEntry>[entry, ...decoded]
      ..sort((a, b) => b.date.compareTo(a.date));
    await prefs.setStringList(
      _dailyHistoryKey,
      next
          .take(_dailyHistoryLimit)
          .map((item) => jsonEncode(item.toJson()))
          .toList(growable: false),
    );
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

  static DateTime _normalizedToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
