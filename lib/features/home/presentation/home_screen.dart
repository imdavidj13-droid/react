import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../core/widgets/neon_button.dart';
import '../../classic/presentation/classic_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 760;
                final pad = constraints.maxWidth < 380 ? 20.0 : 26.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 18, pad, 26),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TopBar(),
                        SizedBox(height: compact ? 30 : 48),
                        const Text(
                          'REACT',
                          style: TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 52,
                            height: .88,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'THINK FAST  •  MOVE FASTER',
                          style: TextStyle(
                            color: ReactColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.7,
                          ),
                        ),
                        SizedBox(height: compact ? 28 : 42),
                        _ClassicModeCard(
                          onPlay: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ClassicScreen()),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(
                              child: _ModeTile(
                                number: '02',
                                icon: Icons.timer_rounded,
                                title: 'BLITZ',
                                accent: ReactColors.purple,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: _ModeTile(
                                number: '03',
                                icon: Icons.all_inclusive_rounded,
                                title: 'ENDLESS',
                                accent: ReactColors.lime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'MORE MODES UNLOCKING SOON',
                            style: TextStyle(
                              color: Color(0xFF52617E),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
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
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF071426),
            border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .65)),
            boxShadow: [
              BoxShadow(color: ReactColors.electricBlue.withValues(alpha: .16), blurRadius: 24),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: ReactColors.electricBlueBright, size: 26),
        ),
        const Spacer(),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('PERSONAL BEST', style: TextStyle(color: ReactColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
            SizedBox(height: 2),
            Text('0', style: TextStyle(color: ReactColors.lime, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
          ],
        ),
      ],
    );
  }
}

class _ClassicModeCard extends StatelessWidget {
  const _ClassicModeCard({required this.onPlay});
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [ReactColors.electricBlueBright, ReactColors.electricBlue, Color(0xFF17447B)]),
        boxShadow: [
          BoxShadow(color: ReactColors.electricBlue.withValues(alpha: .18), blurRadius: 34, spreadRadius: 2),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF09213A), Color(0xFF071323), Color(0xFF08101D)]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ReactColors.electricBlue.withValues(alpha: .12),
                    border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .35)),
                    boxShadow: [BoxShadow(color: ReactColors.electricBlue.withValues(alpha: .20), blurRadius: 30)],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: ReactColors.electricBlueBright, size: 34),
                ),
                const Spacer(),
                const Text('01', style: TextStyle(color: Color(0xFF244568), fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('CLASSIC', style: TextStyle(color: ReactColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.7)),
            const SizedBox(height: 7),
            const Text('One command. One chance.\nHow long can you survive?', style: TextStyle(color: ReactColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.45)),
            const SizedBox(height: 24),
            NeonButton(label: 'START RUN', icon: Icons.play_arrow_rounded, onPressed: onPlay),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.number, required this.icon, required this.title, required this.accent});
  final String number;
  final IconData icon;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF090D1B),
        border: Border.all(color: accent.withValues(alpha: .62)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: .08), blurRadius: 22)],
      ),
      child: Stack(
        children: [
          Align(alignment: Alignment.topRight, child: Text(number, style: TextStyle(color: accent.withValues(alpha: .18), fontSize: 28, fontWeight: FontWeight.w900))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, color: accent, size: 25),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              const Text('LOCKED', style: TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment(.7, -.75), radius: 1.15, colors: [Color(0xFF0B1C35), ReactColors.background, Color(0xFF02040C)]),
      ),
    );
  }
}
