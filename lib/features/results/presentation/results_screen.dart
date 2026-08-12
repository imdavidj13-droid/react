import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../core/widgets/neon_button.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_screen.dart';
import '../../home/presentation/home_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({required this.result, super.key});

  final ReactRunResult result;

  Color get _modeColor => switch (result.mode) {
        ReactGameMode.classic => ReactColors.electricBlueBright,
        ReactGameMode.blitz => ReactColors.coral,
        ReactGameMode.endless => ReactColors.lime,
        ReactGameMode.daily => ReactColors.electricBlueBright,
        ReactGameMode.passIt => ReactColors.purple,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
                child: Column(
                  children: [
                    _ResultsHeader(result: result, color: _modeColor),
                    SizedBox(height: compact ? 24 : 34),
                    _ScoreHero(score: result.score, color: _modeColor),
                    SizedBox(height: compact ? 22 : 30),
                    _StatsStrip(result: result),
                    const SizedBox(height: 16),
                    _OutcomeCard(result: result, color: _modeColor),
                    SizedBox(height: compact ? 24 : 32),
                    NeonButton(
                      label: 'PLAY AGAIN',
                      icon: Icons.replay_rounded,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => ReactRunScreen(mode: result.mode),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home_outlined, size: 17),
                        label: const Text('BACK TO HOME'),
                        style: TextButton.styleFrom(
                          foregroundColor: ReactColors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          result.mode.label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const Spacer(),
        Text(
          result.outcomeLabel,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A101D),
            border: Border.all(color: color.withValues(alpha: .62)),
          ),
          child: Icon(Icons.bolt_rounded, color: color, size: 34),
        ),
        const SizedBox(height: 18),
        const Text(
          'FINAL SCORE',
          style: TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$score',
          style: const TextStyle(
            color: ReactColors.lime,
            fontSize: 82,
            height: .95,
            fontWeight: FontWeight.w900,
            letterSpacing: -3.2,
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.result});

  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF17304E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResultStat(
              label: 'SUCCESS',
              value: '${result.successfulCommands}',
              color: ReactColors.electricBlueBright,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: 'MISSES',
              value: '${result.misses}',
              color: ReactColors.coral,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: 'AVG TIME',
              value: result.averageTimeSeconds == 0
                  ? '--'
                  : '${result.averageTimeSeconds.toStringAsFixed(2)}s',
              color: ReactColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final title = switch (result.outcome) {
      ReactRunOutcome.missedCommand => 'MISSED COMMAND',
      ReactRunOutcome.timeUp => 'CLOCK EXPIRED',
      ReactRunOutcome.completed => 'CHALLENGE COMPLETE',
      ReactRunOutcome.winner => 'MATCH WINNER',
      ReactRunOutcome.quit => 'RUN ENDED',
    };

    final value = switch (result.outcome) {
      ReactRunOutcome.missedCommand => result.failedCommand?.title ?? 'MISS',
      ReactRunOutcome.timeUp => '60 SECONDS COMPLETE',
      ReactRunOutcome.completed => '${result.successfulCommands} COMMANDS CLEARED',
      ReactRunOutcome.winner => 'PLAYER ${result.winnerPlayer ?? '-'}',
      ReactRunOutcome.quit => result.mode.label,
    };

    final icon = switch (result.outcome) {
      ReactRunOutcome.missedCommand => result.failedCommand?.icon ?? Icons.close_rounded,
      ReactRunOutcome.timeUp => Icons.timer_rounded,
      ReactRunOutcome.completed => Icons.emoji_events_rounded,
      ReactRunOutcome.winner => Icons.emoji_events_rounded,
      ReactRunOutcome.quit => Icons.stop_circle_outlined,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .62)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .08),
              border: Border.all(color: color.withValues(alpha: .28)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value, required this.color});

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
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0xFF1A2B45));
  }
}
