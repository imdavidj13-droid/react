import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 24),
              const Text('DAILY RUN', style: TextStyle(color: ReactColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 5),
              const Text('ONE GLOBAL CHALLENGE EVERY DAY', style: TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF07111D), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF29405D))),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TODAY'S SEED", style: TextStyle(color: ReactColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    SizedBox(height: 8),
                    Text('ION PULSE', style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    SizedBox(height: 16),
                    Row(children: [Icon(Icons.schedule_rounded, color: ReactColors.textSecondary, size: 18), SizedBox(width: 8), Text('RESETS IN 14:37:25', style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 15, fontWeight: FontWeight.w800))]),
                    SizedBox(height: 22),
                    Divider(color: Color(0xFF263851)),
                    SizedBox(height: 18),
                    Row(children: [Expanded(child: _DailyMetric(label: 'REWARD TIER', value: 'EPIC', color: ReactColors.purple)), Expanded(child: _DailyMetric(label: 'BEST ATTEMPT', value: '23,450', color: ReactColors.lime)), Expanded(child: _DailyMetric(label: 'STREAK', value: '7 DAYS', color: ReactColors.coral))]),
                    SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 56, child: _DisabledDailyButton()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(children: [Expanded(child: _MiniCard(title: 'CURRENT STREAK', value: '7 DAYS')), SizedBox(width: 12), Expanded(child: _MiniCard(title: "YESTERDAY'S SCORE", value: '18,920'))]),
              const SizedBox(height: 12),
              const _MiniCard(title: 'GLOBAL PLACEMENT', value: 'TOP 3.4%'),
              const SizedBox(height: 16),
              const Text('DAILY GAMEPLAY COMING NEXT', style: TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
            ],
          ),
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
    return Row(children: [IconButton(onPressed: onBack, style: IconButton.styleFrom(backgroundColor: const Color(0xFF07101E), foregroundColor: ReactColors.textPrimary, side: const BorderSide(color: Color(0xFF1E3552))), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)), const Spacer(), const Text('RE△CT', style: TextStyle(color: ReactColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 3)), const Spacer(), const SizedBox(width: 40)]);
  }
}

class _DailyMetric extends StatelessWidget {
  const _DailyMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(label, textAlign: TextAlign.center, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(value, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900))]);
  }
}

class _DisabledDailyButton extends StatelessWidget {
  const _DisabledDailyButton();
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: const Color(0xFF0C3462), border: Border.all(color: const Color(0xFF235B8E))), child: const Center(child: Text('PLAY DAILY', style: TextStyle(color: Color(0xFF7EA3C8), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.8))));
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF07111D), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF293B54))), child: Column(children: [Text(title, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(height: 8), Text(value, style: const TextStyle(color: ReactColors.electricBlueBright, fontSize: 20, fontWeight: FontWeight.w900))]));
  }
}
