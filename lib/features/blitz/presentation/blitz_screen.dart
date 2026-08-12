import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_screen.dart';

class BlitzScreen extends StatefulWidget {
  const BlitzScreen({super.key});

  @override
  State<BlitzScreen> createState() => _BlitzScreenState();
}

class _BlitzScreenState extends State<BlitzScreen> {
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final best = await LocalPlayerStats.bestFor(ReactGameMode.blitz);
    if (mounted) setState(() => _best = best);
  }

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReactRunScreen(mode: ReactGameMode.blitz),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 380 ? 16.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 22),
                  const _Hero(),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: _RuleCard(
                          icon: Icons.timer_outlined,
                          label: '60 SEC',
                          detail: 'One minute run',
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _RuleCard(
                          icon: Icons.speed_rounded,
                          label: 'FAST',
                          detail: 'Rapid commands',
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _RuleCard(
                          icon: Icons.remove_circle_outline_rounded,
                          label: '-3 SEC',
                          detail: 'Every miss',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ScorePreview(best: _best),
                  const SizedBox(height: 16),
                  _StartButton(onTap: () => _start(context)),
                ],
              ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
            side: const BorderSide(color: Color(0xFF213A57)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Spacer(),
        const Text(
          'RE△CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ReactColors.coral.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(color: ReactColors.coral, width: 2.4),
            ),
            child: const Icon(Icons.timer_rounded, color: ReactColors.coral, size: 44),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLITZ',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'FAST. SHORT. BRUTAL.',
                  style: TextStyle(
                    color: ReactColors.coral,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Score as many successful commands as you can in 60 seconds. A miss costs 3 seconds, but the run continues.',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.icon, required this.label, required this.detail});
  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ReactColors.coral.withValues(alpha: .3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ReactColors.coral, size: 24),
          const SizedBox(height: 7),
          FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePreview extends StatelessWidget {
  const _ScorePreview({required this.best});
  final int best;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B2A3F)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'YOUR BEST',
              value: '$best',
              color: ReactColors.coral,
            ),
          ),
          const _Divider(),
          const Expanded(
            child: _Metric(
              label: 'MISS PENALTY',
              value: '-3 SEC',
              color: ReactColors.lime,
            ),
          ),
          const _Divider(),
          const Expanded(
            child: _Metric(
              label: 'POINTS',
              value: '1 / CMD',
              color: ReactColors.electricBlueBright,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFF263851));
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF168CFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
            side: const BorderSide(color: Color(0xFF5FE5FF)),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text(
          'START BLITZ',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
