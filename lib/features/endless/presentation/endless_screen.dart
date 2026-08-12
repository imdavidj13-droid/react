import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../classic/presentation/classic_screen.dart';

class EndlessScreen extends StatelessWidget {
  const EndlessScreen({super.key});

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ClassicScreen()),
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
                      Expanded(child: _RuleCard(icon: Icons.all_inclusive_rounded, label: 'NO LIMIT', detail: 'Keep reacting')),
                      SizedBox(width: 9),
                      Expanded(child: _RuleCard(icon: Icons.trending_up_rounded, label: 'RAMP', detail: 'Gets faster')),
                      SizedBox(width: 9),
                      Expanded(child: _RuleCard(icon: Icons.close_rounded, label: '1 MISS', detail: 'Run ends')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _BestPanel(),
                  const SizedBox(height: 16),
                  _StartButton(onTap: () => _start(context)),
                  const SizedBox(height: 8),
                  const Text(
                    'FIRST PASS USES CLASSIC PACE • SPEED RAMP NEXT',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: .8),
                  ),
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
        const Text('RE△CT', style: TextStyle(color: ReactColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 3)),
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
        border: Border.all(color: ReactColors.lime.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(color: ReactColors.lime, width: 2.4),
            ),
            child: const Icon(Icons.all_inclusive_rounded, color: ReactColors.lime, size: 48),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ENDLESS', style: TextStyle(color: ReactColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: 5),
                Text('NO FINISH LINE.', style: TextStyle(color: ReactColors.lime, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
                SizedBox(height: 9),
                Text('Keep the streak alive for as long as you can. One mistake ends the run.', style: TextStyle(color: ReactColors.textSecondary, fontSize: 10.5, height: 1.35, fontWeight: FontWeight.w600)),
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
        border: Border.all(color: ReactColors.lime.withValues(alpha: .3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ReactColors.lime, size: 24),
          const SizedBox(height: 7),
          FittedBox(child: Text(label, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900))),
          const SizedBox(height: 3),
          Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BestPanel extends StatelessWidget {
  const _BestPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF32461F)),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: ReactColors.lime, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR BEST RUN', style: TextStyle(color: ReactColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .8)),
                SizedBox(height: 4),
                Text('42 COMMANDS', style: TextStyle(color: ReactColors.lime, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Text('1 POINT EACH', style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .7)),
        ],
      ),
    );
  }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29), side: const BorderSide(color: Color(0xFF5FE5FF))),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('START ENDLESS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
    );
  }
}
