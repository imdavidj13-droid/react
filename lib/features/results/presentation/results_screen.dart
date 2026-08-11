import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../core/widgets/glow_panel.dart';
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
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 58,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ReactColors.coral.withValues(alpha: 0.10),
                        border: Border.all(
                          color: ReactColors.coral.withValues(alpha: 0.42),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ReactColors.coral.withValues(alpha: 0.16),
                            blurRadius: 36,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: ReactColors.coral,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'RUN OVER',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '42',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: ReactColors.lime,
                            fontSize: 76,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'NEW BEST',
                      style: TextStyle(
                        color: ReactColors.lime,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const GlowPanel(
                      child: Row(
                        children: [
                          Expanded(
                            child: _ResultStat(
                              label: 'REACTIONS',
                              value: '42',
                              color: ReactColors.electricBlueBright,
                            ),
                          ),
                          _Divider(),
                          Expanded(
                            child: _ResultStat(
                              label: 'BEST COMBO',
                              value: 'x9',
                              color: ReactColors.purple,
                            ),
                          ),
                          _Divider(),
                          Expanded(
                            child: _ResultStat(
                              label: 'AVG TIME',
                              value: '0.64s',
                              color: ReactColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlowPanel(
                      borderColor: ReactColors.coral,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: ReactColors.coral.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.swipe_left_rounded,
                              color: ReactColors.coral,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'SWIPE LEFT',
                                  style: TextStyle(
                                    color: ReactColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (_) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'BACK TO HOME',
                          style: TextStyle(
                            color: ReactColors.textSecondary,
                            fontWeight: FontWeight.w800,
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: ReactColors.border,
    );
  }
}
