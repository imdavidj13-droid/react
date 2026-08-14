import 'package:flutter/material.dart';

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

    final soloAverages = <double>[
      await LocalPlayerStats.averageReactionSecondsFor(ReactGameMode.classic),
      await LocalPlayerStats.averageReactionSecondsFor(ReactGameMode.blitz),
      await LocalPlayerStats.averageReactionSecondsFor(ReactGameMode.endless),
      await LocalPlayerStats.averageReactionSecondsFor(ReactGameMode.daily),
    ].where((value) => value > 0).toList(growable: false);

    var fastestAverageReaction = 0.0;
    if (soloAverages.isNotEmpty) {
      fastestAverageReaction = soloAverages.first;
      for (final value in soloAverages.skip(1)) {
        if (value < fastestAverageReaction) fastestAverageReaction = value;
      }
    }

    return _RecordData(
      classic: await LocalPlayerStats.bestFor(ReactGameMode.classic),
      blitz: await LocalPlayerStats.bestFor(ReactGameMode.blitz),
      endless: await LocalPlayerStats.bestFor(ReactGameMode.endless),
      todayDaily: await LocalPlayerStats.dailyBestToday(),
      dailyStreak: await LocalPlayerStats.dailyStreak(),
      bestCommandStreak: await LocalPlayerStats.bestCommandStreak(),
      fastestAverageReaction: fastestAverageReaction,
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
    this.fastestAverageReaction = 0,
    this.modifierRecords = const <String, int>{},
  });

  final int classic;
  final int blitz;
  final int endless;
  final int todayDaily;
  final int dailyStreak;
  final int bestCommandStreak;
  final double fastestAverageReaction;
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
    childAspectRatio: 1.10,
    children: [
      _RecordCard('CLASSIC', '${data.classic}', ReactColors.electricBlueBright),
      _RecordCard('BLITZ', '${data.blitz}', ReactColors.coral),
      _RecordCard('ENDLESS', '${data.endless}', ReactColors.lime),
      _RecordCard('TODAY DAILY', '${data.todayDaily}', ReactColors.purple),
      _RecordCard('BEST STREAK', '${data.bestCommandStreak}', ReactColors.lime),
      _RecordCard(
        'FASTEST AVG',
        data.fastestAverageReaction == 0
            ? '--'
            : '${data.fastestAverageReaction.toStringAsFixed(2)}s',
        ReactColors.electricBlueBright,
      ),
      _RecordCard(
        'DAILY STREAK',
        '${data.dailyStreak} DAYS',
        ReactColors.coral,
      ),
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
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
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
        const Icon(
          Icons.calendar_month_rounded,
          color: ReactColors.purple,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$score',
          style: const TextStyle(
            color: ReactColors.lime,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
