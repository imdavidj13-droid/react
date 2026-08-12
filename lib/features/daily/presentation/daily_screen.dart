import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../classic/presentation/classic_screen.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

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
                  const SizedBox(height: 20),
                  const Text('DAILY RUN', style: TextStyle(color: ReactColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 5),
                  const Text('ONE GLOBAL CHALLENGE EVERY DAY', style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 18),
                  _ChallengeCard(onTap: () => _start(context)),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, label: 'CURRENT STREAK', value: '7 DAYS', color: ReactColors.coral)),
                      SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.history_rounded, label: 'YESTERDAY', value: '38', color: ReactColors.electricBlueBright)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.public_rounded, label: 'GLOBAL PLACE', value: 'TOP 12%', color: ReactColors.lime)),
                      SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.workspace_premium_outlined, label: 'DAILY BEST', value: '54', color: ReactColors.purple)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('FIRST PASS USES THE CORE RUN • FIXED DAILY SEED NEXT', style: TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: .7)),
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
          style: IconButton.styleFrom(backgroundColor: const Color(0xFF07101E), foregroundColor: ReactColors.textPrimary, side: const BorderSide(color: Color(0xFF1E3552))),
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

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A506E)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TODAY'S SEED", style: TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    SizedBox(height: 6),
                    Text('ION PULSE', style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                    SizedBox(height: 12),
                    Row(children: [Icon(Icons.schedule_rounded, color: ReactColors.textSecondary, size: 17), SizedBox(width: 7), Text('RESETS IN 14:37:25', style: TextStyle(color: ReactColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w800))]),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ReactColors.electricBlueBright, width: 2.2)),
                child: const Icon(Icons.wb_sunny_outlined, color: ReactColors.electricBlueBright, size: 42),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(color: Color(0xFF233850)),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _Metric(label: 'YOUR BEST', value: '42', color: ReactColors.lime)),
              _Divider(),
              Expanded(child: _Metric(label: 'GLOBAL BEST', value: '54', color: ReactColors.purple)),
              _Divider(),
              Expanded(child: _Metric(label: 'ATTEMPTS', value: '1', color: ReactColors.coral)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF168CFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29), side: const BorderSide(color: Color(0xFF5FE5FF)))),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('PLAY DAILY', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
    return Column(children: [Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900))]);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: const Color(0xFF233850));
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF07111D), borderRadius: BorderRadius.circular(19), border: Border.all(color: color.withValues(alpha: .28))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: .8)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
