import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../core/widgets/neon_button.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../home/presentation/home_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 46,
                ),
                child: Column(
                  children: [
                    const _ResultsHeader(),
                    SizedBox(height: compact ? 24 : 34),
                    const _ScoreHero(),
                    SizedBox(height: compact ? 22 : 30),
                    const _StatsStrip(),
                    const SizedBox(height: 16),
                    const _MissedCommandCard(),
                    SizedBox(height: compact ? 24 : 32),
                    NeonButton(
                      label: 'PLAY AGAIN',
                      icon: Icons.replay_rounded,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const ClassicScreen(),
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
                            MaterialPageRoute<void>(
                              builder: (_) => const HomeScreen(),
                            ),
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
  const _ResultsHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'CLASSIC',
          style: TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        Spacer(),
        Text(
          'RUN COMPLETE',
          style: TextStyle(
            color: ReactColors.coral,
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
  const _ScoreHero();

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
            border: Border.all(
              color: ReactColors.coral.withValues(alpha: .62),
            ),
            boxShadow: [
              BoxShadow(
                color: ReactColors.coral.withValues(alpha: .14),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: ReactColors.coral,
            size: 34,
          ),
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
        const Text(
          '42',
          style: TextStyle(
            color: ReactColors.lime,
            fontSize: 82,
            height: .95,
            fontWeight: FontWeight.w900,
            letterSpacing: -3.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: ReactColors.lime.withValues(alpha: .08),
            border: Border.all(
              color: ReactColors.lime.withValues(alpha: .34),
            ),
          ),
          child: const Text(
            'NEW PERSONAL BEST',
            style: TextStyle(
              color: ReactColors.lime,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF17304E)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _ResultStat(
              label: 'REACTIONS',
              value: '42',
              color: ReactColors.electricBlueBright,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: 'BEST COMBO',
              value: '×9',
              color: ReactColors.purple,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: 'AVG TIME',
              value: '0.64s',
              color: ReactColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedCommandCard extends StatelessWidget {
  const _MissedCommandCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ReactColors.coral.withValues(alpha: .62),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ReactColors.coral.withValues(alpha: .08),
              border: Border.all(
                color: ReactColors.coral.withValues(alpha: .28),
              ),
            ),
            child: const Icon(
              Icons.swipe_left_rounded,
              color: ReactColors.coral,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSED COMMAND',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'SWIPE LEFT',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.close_rounded,
            color: ReactColors.coral,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
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
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFF1A2B45),
    );
  }
}
