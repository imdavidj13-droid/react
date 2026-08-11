import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../core/widgets/glow_panel.dart';
import '../../../core/widgets/neon_button.dart';
import '../../classic/presentation/classic_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 26.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ReactColors.electricBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ReactColors.electricBlue.withValues(alpha: 0.42),
                            ),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: ReactColors.electricBlueBright,
                          ),
                        ),
                        const Spacer(),
                        const _MiniStat(label: 'BEST', value: '0'),
                      ],
                    ),
                    const SizedBox(height: 46),
                    Text(
                      'REACT',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: constraints.maxWidth < 380 ? 42 : 50,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Think fast. Move faster.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 34),
                    GlowPanel(
                      borderColor: ReactColors.electricBlue,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: ReactColors.electricBlue.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ReactColors.electricBlue.withValues(alpha: 0.18),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flash_on_rounded,
                              color: ReactColors.electricBlueBright,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'CLASSIC',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'React to each command before the timer runs out. One mistake ends the run.',
                          ),
                          const SizedBox(height: 24),
                          NeonButton(
                            label: 'PLAY CLASSIC',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ClassicScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(
                          child: _ModePlaceholder(
                            icon: Icons.timer_outlined,
                            title: 'BLITZ',
                            subtitle: 'Coming later',
                            accent: ReactColors.purple,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _ModePlaceholder(
                            icon: Icons.all_inclusive_rounded,
                            title: 'ENDLESS',
                            subtitle: 'Coming later',
                            accent: ReactColors.lime,
                          ),
                        ),
                      ],
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: ReactColors.lime,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ModePlaceholder extends StatelessWidget {
  const _ModePlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlowPanel(
      borderColor: accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
