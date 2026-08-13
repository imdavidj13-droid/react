import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/domain/react_command_performance.dart';

class CommandPerformanceScreen extends StatelessWidget {
  const CommandPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<List<ReactCommandPerformance>>(
          future: LocalPlayerStats.commandPerformance(),
          builder: (context, snapshot) {
            final stats = snapshot.data ??
                [
                  for (final command in ReactCommand.values)
                    ReactCommandPerformance(command: command),
                ];
            final attempted = stats.where((item) => item.attempts > 0).toList();
            final weakest = attempted.isEmpty
                ? null
                : (attempted.toList()
                      ..sort((a, b) => a.accuracy.compareTo(b.accuracy)))
                    .first;
            final fastestCandidates =
                stats.where((item) => item.successes > 0).toList();
            final fastest = fastestCandidates.isEmpty
                ? null
                : (fastestCandidates.toList()
                      ..sort((a, b) => a.averageReactionSeconds
                          .compareTo(b.averageReactionSeconds)))
                    .first;

            return LayoutBuilder(
              builder: (context, constraints) {
                final pad = constraints.maxWidth < 360 ? 12.0 : 20.0;
                return ListView(
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
                  children: [
                    _Header(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 20),
                    const Text(
                      'COMMAND PERFORMANCE',
                      style: TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'ACCURACY AND REACTION TIME ACROSS EVERY ACTIVE COMMAND',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'WEAKEST',
                            value: weakest?.command.title ?? '--',
                            detail: weakest == null
                                ? 'PLAY TO BUILD DATA'
                                : '${(weakest.accuracy * 100).round()}% ACCURACY',
                            color: ReactColors.coral,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryCard(
                            label: 'FASTEST',
                            value: fastest?.command.title ?? '--',
                            detail: fastest == null
                                ? 'PLAY TO BUILD DATA'
                                : '${fastest.averageReactionSeconds.toStringAsFixed(2)}s AVG',
                            color: ReactColors.lime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...stats.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CommandCard(stats: item),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
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
          const Text(
            'RE△CT',
            style: TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 116,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({required this.stats});
  final ReactCommandPerformance stats;

  @override
  Widget build(BuildContext context) {
    final accuracy = stats.attempts == 0 ? 0 : (stats.accuracy * 100).round();
    final avg = stats.successes == 0
        ? '--'
        : '${stats.averageReactionSeconds.toStringAsFixed(2)}s';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF263851)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(
                color: ReactColors.electricBlueBright.withValues(alpha: .55),
              ),
            ),
            child: Icon(
              stats.command.icon,
              color: ReactColors.electricBlueBright,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.command.title,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.attempts} ATTEMPTS • ${stats.misses} MISSES',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniMetric(label: 'ACC', value: '$accuracy%', color: ReactColors.lime),
          const SizedBox(width: 12),
          _MiniMetric(
            label: 'AVG',
            value: avg,
            color: ReactColors.electricBlueBright,
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 48,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
}
