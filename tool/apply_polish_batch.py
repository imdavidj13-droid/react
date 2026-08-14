from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if old not in text:
        raise RuntimeError(f'Missing expected block in {path}: {old[:80]!r}')
    file.write_text(text.replace(old, new, 1))


def replace_between(path: str, start: str, end: str, new_block: str) -> None:
    file = Path(path)
    text = file.read_text()
    start_i = text.index(start)
    end_i = text.index(end, start_i)
    file.write_text(text[:start_i] + new_block + text[end_i:])


# Core gameplay: real streak tracking, per-player Pass It clears and a short
# post-miss beat for Endless before Results.
path = 'lib/features/gameplay/presentation/react_run_screen.dart'
replace_once(
    path,
    "  late final List<int> _playerLives;\n",
    "  late final List<int> _playerLives;\n  late final List<int> _playerClears;\n",
)
replace_once(
    path,
    "  int _misses = 0;\n  int _totalResponseMs = 0;\n",
    "  int _misses = 0;\n  int _currentStreak = 0;\n  int _maxStreak = 0;\n  int _totalResponseMs = 0;\n",
)
replace_once(
    path,
    "    _playerLives = List<int>.filled(\n      widget.mode == ReactGameMode.passIt ? passItPlayers : 3,\n      3,\n    );\n",
    "    _playerLives = List<int>.filled(\n      widget.mode == ReactGameMode.passIt ? passItPlayers : 3,\n      3,\n    );\n    _playerClears = List<int>.filled(_playerLives.length, 0);\n",
)
replace_once(
    path,
    "      _score += 1;\n      _successfulCommands += 1;\n      _totalResponseMs += responseMs;\n      if (widget.mode == ReactGameMode.passIt) {\n        _passItTurnClears += 1;\n      }\n",
    "      _score += 1;\n      _successfulCommands += 1;\n      _currentStreak += 1;\n      _maxStreak = max(_maxStreak, _currentStreak);\n      _totalResponseMs += responseMs;\n      if (widget.mode == ReactGameMode.passIt) {\n        _passItTurnClears += 1;\n        _playerClears[_currentPlayer] += 1;\n      }\n",
)
replace_once(
    path,
    "    _commandTracker.recordMiss(_command);\n    _game.triggerMiss();\n\n    switch (widget.mode) {\n",
    "    _commandTracker.recordMiss(_command);\n    _game.triggerMiss();\n    _currentStreak = 0;\n\n    switch (widget.mode) {\n",
)
replace_once(
    path,
    "        _finish(ReactRunOutcome.missedCommand);\n        return;\n\n      case ReactGameMode.daily:",
    "        _scheduleTransition(320, () => _finish(ReactRunOutcome.missedCommand));\n        return;\n\n      case ReactGameMode.daily:",
)
replace_once(
    path,
    "            misses: _misses,\n            failedCommand: outcome == ReactRunOutcome.missedCommand\n",
    "            misses: _misses,\n            maxStreak: _maxStreak,\n            failedCommand: outcome == ReactRunOutcome.missedCommand\n",
)
replace_once(
    path,
    "            playerLives: widget.mode == ReactGameMode.passIt\n                ? List<int>.unmodifiable(_playerLives)\n                : null,\n            commandPerformance: _commandTracker.snapshot(),\n",
    "            playerLives: widget.mode == ReactGameMode.passIt\n                ? List<int>.unmodifiable(_playerLives)\n                : null,\n            playerClears: widget.mode == ReactGameMode.passIt\n                ? List<int>.unmodifiable(_playerClears)\n                : null,\n            commandPerformance: _commandTracker.snapshot(),\n",
)

# Daily: snapshot the exact challenge metadata onto the run and track streak.
path = 'lib/features/daily/presentation/daily_run_screen.dart'
replace_once(
    path,
    "  int _score = 0;\n  int _misses = 0;\n  int _totalResponseMs = 0;\n",
    "  int _score = 0;\n  int _misses = 0;\n  int _currentStreak = 0;\n  int _maxStreak = 0;\n  int _totalResponseMs = 0;\n",
)
replace_once(
    path,
    "      _acceptingInput = false;\n      _score += 1;\n      _totalResponseMs += responseMs;\n",
    "      _acceptingInput = false;\n      _score += 1;\n      _currentStreak += 1;\n      _maxStreak = max(_maxStreak, _currentStreak);\n      _totalResponseMs += responseMs;\n",
)
replace_once(
    path,
    "    _commandTracker.recordMiss(_command);\n    _game.triggerMiss();\n",
    "    _commandTracker.recordMiss(_command);\n    _game.triggerMiss();\n    _currentStreak = 0;\n",
)
replace_once(
    path,
    "            misses: _misses,\n            failedCommand:\n                outcome == ReactRunOutcome.missedCommand ? _command : null,\n            commandPerformance: _commandTracker.snapshot(),\n",
    "            misses: _misses,\n            maxStreak: _maxStreak,\n            failedCommand:\n                outcome == ReactRunOutcome.missedCommand ? _command : null,\n            dailyDate: _challenge.date,\n            dailyModifierLabel: _modifier.label,\n            dailyModifierRule: _modifier.shortRule,\n            commandPerformance: _commandTracker.snapshot(),\n",
)

# Persistence: global best streak and Today Best on the Daily landing page.
path = 'lib/features/gameplay/data/local_player_stats.dart'
replace_once(
    path,
    "  static const _runsKey = 'runs_played';\n",
    "  static const _runsKey = 'runs_played';\n  static const _bestStreakKey = 'best_command_streak';\n",
)
replace_once(
    path,
    "  static Future<int> runsPlayed() async {\n",
    "  static Future<int> bestCommandStreak() async {\n    final prefs = await SharedPreferences.getInstance();\n    return prefs.getInt(_bestStreakKey) ?? 0;\n  }\n\n  static Future<int> runsPlayed() async {\n",
)
replace_once(
    path,
    "    await prefs.setInt(_runsKey, (prefs.getInt(_runsKey) ?? 0) + 1);\n",
    "    final currentBestStreak = prefs.getInt(_bestStreakKey) ?? 0;\n    if (result.maxStreak > currentBestStreak) {\n      await prefs.setInt(_bestStreakKey, result.maxStreak);\n    }\n\n    await prefs.setInt(_runsKey, (prefs.getInt(_runsKey) ?? 0) + 1);\n",
)
replace_once(
    path,
    "    await prefs.remove(_runsKey);\n",
    "    await prefs.remove(_runsKey);\n    await prefs.remove(_bestStreakKey);\n",
)

path = 'lib/features/daily/presentation/daily_screen.dart'
replace_once(
    path,
    "    final best = await LocalPlayerStats.bestFor(ReactGameMode.daily);\n",
    "    final best = await LocalPlayerStats.dailyBestToday();\n",
)
replace_once(path, "                  label: 'YOUR BEST',\n", "                  label: 'TODAY BEST',\n")

# Results: purpose-built mode labels, run streak, medals and Daily snapshot.
path = 'lib/features/results/presentation/results_screen.dart'
replace_once(
    path,
    "        Text(\n          isPassIt ? 'COMMANDS CLEARED' : 'FINAL SCORE',\n",
    "        Text(\n          switch (result.mode) {\n            ReactGameMode.classic => 'FINAL SCORE',\n            ReactGameMode.blitz => '60 SECOND SCORE',\n            ReactGameMode.endless => 'COMMANDS SURVIVED',\n            ReactGameMode.daily => 'DAILY SCORE',\n            ReactGameMode.passIt => 'MATCH COMMANDS',\n          },\n",
)
replace_once(
    path,
    "                Text(\n                  'NEW BEST',\n",
    "                Text(\n                  result.mode == ReactGameMode.daily ? 'NEW RULE BEST' : 'NEW BEST',\n",
)
replace_once(path, "              label: 'SUCCESS',\n", "              label: 'CLEARS',\n")
replace_once(
    path,
    "                    _StatsStrip(result: result),\n                    if (_comparison != null) ...[\n",
    "                    _StatsStrip(result: result),\n                    if (result.maxStreak > 0 || _runMedals(result).isNotEmpty) ...[\n                      const SizedBox(height: 14),\n                      _RunHighlights(result: result, color: _modeColor),\n                    ],\n                    if (_comparison != null) ...[\n",
)
replace_once(
    path,
    "                    _OutcomeCard(result: result, color: _modeColor),\n                    if (result.mode == ReactGameMode.passIt &&\n",
    "                    _OutcomeCard(result: result, color: _modeColor),\n                    if (result.mode == ReactGameMode.daily &&\n                        result.dailyModifierLabel != null) ...[\n                      const SizedBox(height: 14),\n                      _DailyResultSummary(result: result),\n                    ],\n                    if (result.mode == ReactGameMode.passIt &&\n",
)
replace_between(
    path,
    'class _PassItPlayerRow extends StatelessWidget {',
    'class _ResultStat extends StatelessWidget {',
    '''class _PassItPlayerRow extends StatelessWidget {
  const _PassItPlayerRow({
    required this.player,
    required this.lives,
    required this.winner,
    this.clears,
  });

  final int player;
  final int lives;
  final bool winner;
  final int? clears;

  @override
  Widget build(BuildContext context) {
    final color = winner ? ReactColors.lime : ReactColors.textSecondary;
    final hearts = lives == 0 ? 'OUT' : List.filled(lives, '♥').join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090F1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: winner
              ? ReactColors.lime.withValues(alpha: .48)
              : const Color(0xFF24364E),
        ),
      ),
      child: Row(
        children: [
          Icon(
            winner ? Icons.emoji_events_rounded : Icons.person_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER $player',
                  style: TextStyle(
                    color: winner ? ReactColors.textPrimary : ReactColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (clears != null)
                  Text(
                    '$clears CLEARS',
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            winner ? 'WINNER  •  $hearts' : hearts,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyResultSummary extends StatelessWidget {
  const _DailyResultSummary({required this.result});
  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    final date = result.dailyDate;
    final dateLabel = date == null
        ? 'TODAY'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .42)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: ReactColors.purple),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.dailyModifierLabel}  •  $dateLabel',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (result.dailyModifierRule != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.dailyModifierRule!,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunHighlights extends StatelessWidget {
  const _RunHighlights({required this.result, required this.color});
  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final medals = _runMedals(result);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (result.maxStreak > 0)
            _HighlightChip(
              icon: Icons.local_fire_department_rounded,
              label: 'STREAK ${result.maxStreak}',
              color: ReactColors.coral,
            ),
          for (final medal in medals)
            _HighlightChip(
              icon: medal.icon,
              label: medal.label,
              color: medal.color,
            ),
        ],
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .36)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      );
}

class _RunMedal {
  const _RunMedal(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

List<_RunMedal> _runMedals(ReactRunResult result) {
  final medals = <_RunMedal>[];
  if (result.successfulCommands > 0 && result.misses == 0) {
    medals.add(const _RunMedal('PERFECT RUN', Icons.check_circle_rounded, ReactColors.lime));
  }
  if (result.averageTimeSeconds > 0 && result.averageTimeSeconds <= .65) {
    medals.add(const _RunMedal('LIGHTNING', Icons.bolt_rounded, ReactColors.electricBlueBright));
  }
  if (result.mode == ReactGameMode.endless && result.score >= 25) {
    medals.add(const _RunMedal('SURVIVOR', Icons.all_inclusive_rounded, ReactColors.lime));
  }
  if (result.mode == ReactGameMode.daily && result.outcome == ReactRunOutcome.completed) {
    medals.add(const _RunMedal('DAILY MASTER', Icons.emoji_events_rounded, ReactColors.purple));
  }
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null && result.playerLives != null) {
    final winnerIndex = result.winnerPlayer! - 1;
    if (winnerIndex >= 0 && winnerIndex < result.playerLives!.length && result.playerLives![winnerIndex] == 1) {
      medals.add(const _RunMedal('CLUTCH', Icons.favorite_rounded, ReactColors.coral));
    }
  }
  return medals;
}

class _ResultStat extends StatelessWidget {''',
)
replace_once(
    path,
    "            _PassItPlayerRow(\n              player: i + 1,\n              lives: lives[i],\n              winner: result.winnerPlayer == i + 1,\n            ),\n",
    "            _PassItPlayerRow(\n              player: i + 1,\n              lives: lives[i],\n              winner: result.winnerPlayer == i + 1,\n              clears: result.playerClears != null && i < result.playerClears!.length\n                  ? result.playerClears![i]\n                  : null,\n            ),\n",
)

# Share card: use snapshotted Daily metadata and more meaningful hero labels.
path = 'lib/features/results/presentation/result_share_screen.dart'
replace_once(path, "import '../../daily/domain/daily_challenge.dart';\n", '')
replace_once(
    path,
    "    final isDaily = result.mode == ReactGameMode.daily;\n    final daily = isDaily ? DailyChallenge.today() : null;\n",
    "    final isDaily = result.mode == ReactGameMode.daily;\n",
)
replace_once(
    path,
    "                      isPassIt ? 'COMMANDS CLEARED' : 'FINAL SCORE',\n",
    "                      _scoreLabel(result.mode),\n",
)
replace_once(
    path,
    "                    if (daily != null) ...[\n                      _DailySummary(challenge: daily, color: color),\n",
    "                    if (isDaily && result.dailyModifierLabel != null) ...[\n                      _DailySummary(result: result, color: color),\n",
)
replace_between(
    path,
    'class _DailySummary extends StatelessWidget {',
    'class _PassItSummary extends StatelessWidget {',
    '''class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final date = result.dailyDate;
    final dateLabel = date == null
        ? 'DAILY CHALLENGE'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return _InfoStrip(
      icon: Icons.calendar_today_rounded,
      color: color,
      title: result.dailyModifierLabel ?? 'DAILY',
      subtitle: '$dateLabel  •  ${result.dailyModifierRule ?? '60 COMMAND TARGET'}',
    );
  }
}

class _PassItSummary extends StatelessWidget {''',
)
replace_once(
    path,
    "String _heroEyebrow(ReactRunResult result) => switch (result.mode) {\n",
    "String _scoreLabel(ReactGameMode mode) => switch (mode) {\n      ReactGameMode.classic => 'FINAL SCORE',\n      ReactGameMode.blitz => '60 SECOND SCORE',\n      ReactGameMode.endless => 'COMMANDS SURVIVED',\n      ReactGameMode.daily => 'DAILY SCORE',\n      ReactGameMode.passIt => 'MATCH COMMANDS',\n    };\n\nString _heroEyebrow(ReactRunResult result) => switch (result.mode) {\n",
)

# Milestones: surface the new best command streak.
path = 'lib/features/settings/presentation/milestones_screen.dart'
replace_once(
    path,
    "    this.passItRuns = 0,\n",
    "    this.passItRuns = 0,\n    this.bestStreak = 0,\n",
)
replace_once(
    path,
    "  final int passItRuns;\n",
    "  final int passItRuns;\n  final int bestStreak;\n",
)
replace_once(
    path,
    "      LocalPlayerStats.runsFor(ReactGameMode.passIt),\n",
    "      LocalPlayerStats.runsFor(ReactGameMode.passIt),\n      LocalPlayerStats.bestCommandStreak(),\n",
)
replace_once(
    path,
    "      passItRuns: values[6],\n",
    "      passItRuns: values[6],\n      bestStreak: values[7],\n",
)
replace_once(
    path,
    "        _Milestone(\n          group: _MilestoneGroup.consistency,\n          title: 'THREE DAY RUN',\n",
    "        _Milestone(\n          group: _MilestoneGroup.consistency,\n          title: 'STREAK 25',\n          description: 'Clear 25 commands in a row without a miss.',\n          icon: Icons.local_fire_department_rounded,\n          color: ReactColors.lime,\n          current: bestStreak,\n          target: 25,\n        ),\n        _Milestone(\n          group: _MilestoneGroup.consistency,\n          title: 'THREE DAY RUN',\n",
)

# Clean an import made unnecessary by richer history inference.
replace_once(
    'lib/features/gameplay/domain/react_run_history_entry.dart',
    "import 'react_command_performance.dart';\n",
    '',
)

# New personal-records screen.
Path('lib/features/leaderboard/presentation/personal_records_screen.dart').write_text(r'''import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../daily/domain/daily_challenge.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';

class PersonalRecordsScreen extends StatelessWidget {
  const PersonalRecordsScreen({super.key});

  Future<_RecordData> _load() async {
    final modifierRecords = <String, int>{};
    for (final modifier in DailyModifier.values) {
      modifierRecords[modifier.label] =
          await LocalPlayerStats.dailyBestForModifier(modifier);
    }
    return _RecordData(
      classic: await LocalPlayerStats.bestFor(ReactGameMode.classic),
      blitz: await LocalPlayerStats.bestFor(ReactGameMode.blitz),
      endless: await LocalPlayerStats.bestFor(ReactGameMode.endless),
      todayDaily: await LocalPlayerStats.dailyBestToday(),
      dailyStreak: await LocalPlayerStats.dailyStreak(),
      bestCommandStreak: await LocalPlayerStats.bestCommandStreak(),
      modifierRecords: modifierRecords,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ReactColors.background,
        body: SafeArea(
          child: FutureBuilder<_RecordData>(
            future: _load(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? const _RecordData();
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'PERSONAL RECORDS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ReactColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _RecordGrid(data: data),
                    const SizedBox(height: 18),
                    const Text(
                      'DAILY RULE RECORDS',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final entry in data.modifierRecords.entries) ...[
                      _RuleRecord(label: entry.key, score: entry.value),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _RecordData {
  const _RecordData({
    this.classic = 0,
    this.blitz = 0,
    this.endless = 0,
    this.todayDaily = 0,
    this.dailyStreak = 0,
    this.bestCommandStreak = 0,
    this.modifierRecords = const <String, int>{},
  });
  final int classic;
  final int blitz;
  final int endless;
  final int todayDaily;
  final int dailyStreak;
  final int bestCommandStreak;
  final Map<String, int> modifierRecords;
}

class _RecordGrid extends StatelessWidget {
  const _RecordGrid({required this.data});
  final _RecordData data;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.55,
        children: [
          _RecordCard('CLASSIC', '${data.classic}', ReactColors.electricBlueBright),
          _RecordCard('BLITZ', '${data.blitz}', ReactColors.coral),
          _RecordCard('ENDLESS', '${data.endless}', ReactColors.lime),
          _RecordCard('TODAY DAILY', '${data.todayDaily}', ReactColors.purple),
          _RecordCard('BEST STREAK', '${data.bestCommandStreak}', ReactColors.lime),
          _RecordCard('DAILY STREAK', '${data.dailyStreak} DAYS', ReactColors.coral),
        ],
      );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: .7)),
          ],
        ),
      );
}

class _RuleRecord extends StatelessWidget {
  const _RuleRecord({required this.label, required this.score});
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF293B54)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: ReactColors.purple, size: 19),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w900))),
            Text('$score', style: const TextStyle(color: ReactColors.lime, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
''')

# Scores: records entry point + tap-through run detail.
path = 'lib/features/leaderboard/presentation/leaderboard_screen.dart'
replace_once(
    path,
    "import '../../gameplay/domain/react_run_result.dart';\n",
    "import '../../gameplay/domain/react_run_result.dart';\nimport 'personal_records_screen.dart';\n",
)
replace_once(
    path,
    "                  _Header(onBack: () => Navigator.of(context).pop()),\n",
    "                  _Header(\n                    onBack: () => Navigator.of(context).pop(),\n                    onRecords: () => Navigator.of(context).push(\n                      MaterialPageRoute<void>(\n                        builder: (_) => const PersonalRecordsScreen(),\n                      ),\n                    ),\n                  ),\n",
)
replace_between(
    path,
    'class _Header extends StatelessWidget {',
    'class _RecordsBanner extends StatelessWidget {',
    '''class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onRecords});
  final VoidCallback onBack;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
            side: const BorderSide(color: Color(0xFF1E3552)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Spacer(),
        const Column(
          children: [
            Text(
              'SCORES',
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'LOCAL DEVICE RECORDS',
              style: TextStyle(
                color: ReactColors.purple,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Personal records',
          onPressed: onRecords,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.lime,
            side: const BorderSide(color: Color(0xFF1E3552)),
          ),
          icon: const Icon(Icons.workspace_premium_outlined, size: 19),
        ),
      ],
    );
  }
}

class _RecordsBanner extends StatelessWidget {''',
)
replace_between(
    path,
    'class _RecentRunCard extends StatelessWidget {',
    'class _EmptyHistory extends StatelessWidget {',
    '''class _RecentRunCard extends StatelessWidget {
  const _RecentRunCard({required this.entry});

  final ReactRunHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(entry.mode);
    final date = entry.playedAt.toLocal();
    final timestamp =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => _showRunDetail(context, entry),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .30)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF050A13),
                border: Border.all(color: color.withValues(alpha: .8)),
              ),
              child: Icon(_modeIcon(entry.mode), color: color, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.mode.label, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .7)),
                      const SizedBox(width: 8),
                      Text(timestamp, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.successfulCommands} cleared  •  ${entry.misses} misses  •  ${entry.averageTimeSeconds == 0 ? '--' : '${entry.averageTimeSeconds.toStringAsFixed(2)}s avg'}',
                    style: const TextStyle(color: ReactColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

void _showRunDetail(BuildContext context, ReactRunHistoryEntry entry) {
  final color = _modeColor(entry.mode);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF07111D),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: const Color(0xFF32445D), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text('${entry.mode.label} RUN', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(entry.playedAt.toLocal().toString().substring(0, 16), style: const TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailChip('SCORE', '${entry.score}', color),
                _DetailChip('CLEARS', '${entry.successfulCommands}', ReactColors.electricBlueBright),
                _DetailChip('MISSES', '${entry.misses}', ReactColors.coral),
                _DetailChip('AVG', entry.averageTimeSeconds == 0 ? '--' : '${entry.averageTimeSeconds.toStringAsFixed(2)}s', ReactColors.textPrimary),
                if (entry.maxStreak > 0) _DetailChip('BEST STREAK', '${entry.maxStreak}', ReactColors.lime),
              ],
            ),
            if (entry.dailyModifierLabel != null) ...[
              const SizedBox(height: 16),
              Text('DAILY RULE  •  ${entry.dailyModifierLabel}', style: const TextStyle(color: ReactColors.purple, fontSize: 10, fontWeight: FontWeight.w900)),
            ],
            if (entry.winnerPlayer != null) ...[
              const SizedBox(height: 16),
              Text('WINNER  •  PLAYER ${entry.winnerPlayer}', style: const TextStyle(color: ReactColors.lime, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
            if (entry.strongestCommand != null || entry.weakestCommand != null) ...[
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF213650)),
              const SizedBox(height: 12),
              if (entry.strongestCommand != null) Text('STRONGEST  •  ${entry.strongestCommand}', style: const TextStyle(color: ReactColors.lime, fontSize: 10, fontWeight: FontWeight.w900)),
              if (entry.weakestCommand != null) ...[
                const SizedBox(height: 8),
                Text('TO WORK ON  •  ${entry.weakestCommand}', style: const TextStyle(color: ReactColors.coral, fontSize: 10, fontWeight: FontWeight.w900)),
              ],
            ],
            if (entry.failedCommand != null) ...[
              const SizedBox(height: 14),
              Text('RUN ENDED ON  •  ${entry.failedCommand}', style: const TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ],
        ),
      ),
    ),
  );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 94,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF090F1B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 6.5, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _EmptyHistory extends StatelessWidget {''',
)

# Tests: lifecycle pausing, result metadata, richer history and compact records.
Path('test/polish_batch_test.dart').write_text(r'''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_history_entry.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/gameplay/presentation/react_run_screen.dart';
import 'package:react/features/leaderboard/presentation/personal_records_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReactSettings.load();
  });

  test('rich run history stays backward compatible and stores streak metadata', () {
    final entry = ReactRunHistoryEntry.fromResult(
      ReactRunResult(
        mode: ReactGameMode.daily,
        score: 19,
        successfulCommands: 19,
        averageTimeSeconds: .61,
        outcome: ReactRunOutcome.missedCommand,
        misses: 1,
        maxStreak: 19,
        dailyDate: DateTime(2026, 8, 14),
        dailyModifierLabel: 'CHAIN',
      ),
    );
    final decoded = ReactRunHistoryEntry.tryDecode(entry.encode());
    expect(decoded?.maxStreak, 19);
    expect(decoded?.dailyModifierLabel, 'CHAIN');
  });

  test('recording results retains the best command streak', () async {
    await LocalPlayerStats.recordResult(const ReactRunResult(
      mode: ReactGameMode.endless,
      score: 12,
      successfulCommands: 12,
      averageTimeSeconds: .7,
      outcome: ReactRunOutcome.missedCommand,
      maxStreak: 12,
    ));
    await LocalPlayerStats.recordResult(const ReactRunResult(
      mode: ReactGameMode.classic,
      score: 20,
      successfulCommands: 20,
      averageTimeSeconds: .8,
      outcome: ReactRunOutcome.missedCommand,
      maxStreak: 8,
    ));
    expect(await LocalPlayerStats.bestCommandStreak(), 12);
  });

  testWidgets('backgrounding an active run freezes it behind pause UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReactRunScreen(mode: ReactGameMode.classic)));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('THE CURRENT COMMAND IS FROZEN'), findsOneWidget);
  });

  testWidgets('personal records remains usable on a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: PersonalRecordsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('PERSONAL RECORDS'), findsOneWidget);
    expect(find.text('TODAY DAILY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
''')

print('REACT polish batch patches applied.')
