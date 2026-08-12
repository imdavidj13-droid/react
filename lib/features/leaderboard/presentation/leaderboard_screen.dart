import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_history_entry.dart';
import '../../gameplay/domain/react_run_result.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<_ScoresData> _data;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_ScoresData> _loadData() async {
    final items = <_ModeStats>[];
    for (final mode in ReactGameMode.values) {
      items.add(
        _ModeStats(
          mode: mode,
          best: await LocalPlayerStats.bestFor(mode),
          runs: await LocalPlayerStats.runsFor(mode),
          commands: await LocalPlayerStats.successfulCommandsFor(mode),
          averageReactionSeconds:
              await LocalPlayerStats.averageReactionSecondsFor(mode),
        ),
      );
    }

    return _ScoresData(
      stats: items,
      recentRuns: await LocalPlayerStats.recentRuns(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<_ScoresData>(
          future: _data,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const _ScoresData();
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 20),
                  _RecordsBanner(stats: data.stats),
                  const SizedBox(height: 20),
                  const _SectionLabel('YOUR MODE STATS'),
                  const SizedBox(height: 10),
                  for (final item in data.stats) ...[
                    _ModeStatsCard(stats: item),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  const _SectionLabel('RECENT RUNS'),
                  const SizedBox(height: 10),
                  if (data.recentRuns.isEmpty)
                    const _EmptyHistory()
                  else
                    for (final run in data.recentRuns) ...[
                      _RecentRunCard(entry: run),
                      const SizedBox(height: 9),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScoresData {
  const _ScoresData({
    this.stats = const <_ModeStats>[],
    this.recentRuns = const <ReactRunHistoryEntry>[],
  });

  final List<_ModeStats> stats;
  final List<ReactRunHistoryEntry> recentRuns;
}

class _ModeStats {
  const _ModeStats({
    required this.mode,
    required this.best,
    required this.runs,
    required this.commands,
    required this.averageReactionSeconds,
  });

  final ReactGameMode mode;
  final int best;
  final int runs;
  final int commands;
  final double averageReactionSeconds;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

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
        const SizedBox(width: 40),
      ],
    );
  }
}

class _RecordsBanner extends StatelessWidget {
  const _RecordsBanner({required this.stats});

  final List<_ModeStats> stats;

  @override
  Widget build(BuildContext context) {
    final totalRuns = stats.fold<int>(0, (sum, item) => sum + item.runs);
    final totalCommands = stats.fold<int>(0, (sum, item) => sum + item.commands);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF29405D)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: ReactColors.lime,
                size: 30,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR REACTION RECORD',
                      style: TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'REAL STATS FROM RUNS PLAYED ON THIS DEVICE',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 8,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF213650)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BannerMetric(
                  label: 'TOTAL RUNS',
                  value: '$totalRuns',
                  color: ReactColors.electricBlueBright,
                ),
              ),
              const _BannerDivider(),
              Expanded(
                child: _BannerMetric(
                  label: 'COMMANDS',
                  value: '$totalCommands',
                  color: ReactColors.lime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFF263851))),
      ],
    );
  }
}

class _ModeStatsCard extends StatelessWidget {
  const _ModeStatsCard({required this.stats});

  final _ModeStats stats;

  Color get color => _modeColor(stats.mode);
  IconData get icon => _modeIcon(stats.mode);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF050A13),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.mode.label,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stats.mode == ReactGameMode.passIt
                          ? 'LOCAL MATCH STATS'
                          : 'PERSONAL PERFORMANCE',
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.mode != ReactGameMode.passIt)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'BEST',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${stats.best}',
                      style: TextStyle(
                        color: color,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(color: Color(0xFF1D314A)),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _CardMetric(label: 'RUNS', value: '${stats.runs}'),
              ),
              const _BannerDivider(),
              Expanded(
                child: _CardMetric(label: 'COMMANDS', value: '${stats.commands}'),
              ),
              const _BannerDivider(),
              Expanded(
                child: _CardMetric(
                  label: 'AVG REACTION',
                  value: stats.averageReactionSeconds == 0
                      ? '--'
                      : '${stats.averageReactionSeconds.toStringAsFixed(2)}s',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentRunCard extends StatelessWidget {
  const _RecentRunCard({required this.entry});

  final ReactRunHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(entry.mode);
    final date = entry.playedAt.toLocal();
    final timestamp =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
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
                    Text(
                      entry.mode.label,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${entry.successfulCommands} cleared  •  ${entry.misses} misses  •  '
                  '${entry.averageTimeSeconds == 0 ? '--' : '${entry.averageTimeSeconds.toStringAsFixed(2)}s avg'}',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.mode == ReactGameMode.passIt ? 'MATCH' : 'SCORE',
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.score}',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF263851)),
      ),
      child: const Row(
        children: [
          Icon(Icons.history_rounded, color: ReactColors.textSecondary, size: 24),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'PLAY A RUN TO START BUILDING YOUR RECENT HISTORY',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerDivider extends StatelessWidget {
  const _BannerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFF213650),
    );
  }
}

Color _modeColor(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => ReactColors.electricBlueBright,
      ReactGameMode.blitz => ReactColors.coral,
      ReactGameMode.endless => ReactColors.lime,
      ReactGameMode.daily => ReactColors.purple,
      ReactGameMode.passIt => const Color(0xFFFFB85A),
    };

IconData _modeIcon(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => Icons.bolt_rounded,
      ReactGameMode.blitz => Icons.timer_rounded,
      ReactGameMode.endless => Icons.all_inclusive_rounded,
      ReactGameMode.daily => Icons.calendar_month_rounded,
      ReactGameMode.passIt => Icons.groups_2_rounded,
    };
