import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<_ModeStats>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  Future<List<_ModeStats>> _loadStats() async {
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
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<List<_ModeStats>>(
          future: _stats,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? const <_ModeStats>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 20),
                  _RecordsBanner(stats: stats),
                  const SizedBox(height: 20),
                  const _SectionLabel('YOUR MODE STATS'),
                  const SizedBox(height: 10),
                  for (final item in stats) ...[
                    _ModeStatsCard(stats: item),
                    const SizedBox(height: 10),
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

  Color get color => switch (stats.mode) {
        ReactGameMode.classic => ReactColors.electricBlueBright,
        ReactGameMode.blitz => ReactColors.coral,
        ReactGameMode.endless => ReactColors.lime,
        ReactGameMode.daily => ReactColors.purple,
        ReactGameMode.passIt => const Color(0xFFFFB85A),
      };

  IconData get icon => switch (stats.mode) {
        ReactGameMode.classic => Icons.bolt_rounded,
        ReactGameMode.blitz => Icons.timer_rounded,
        ReactGameMode.endless => Icons.all_inclusive_rounded,
        ReactGameMode.daily => Icons.calendar_month_rounded,
        ReactGameMode.passIt => Icons.groups_2_rounded,
      };

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
                child: _CardMetric(
                  label: 'RUNS',
                  value: '${stats.runs}',
                ),
              ),
              const _BannerDivider(),
              Expanded(
                child: _CardMetric(
                  label: 'COMMANDS',
                  value: '${stats.commands}',
                ),
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
