import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class PassItScreen extends StatelessWidget {
  const PassItScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF07101E),
                      foregroundColor: ReactColors.textPrimary,
                      side: const BorderSide(color: Color(0xFF1E3552)),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const Spacer(),
                  const Text('RE△CT', style: TextStyle(color: ReactColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 3)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 26),
              const Icon(Icons.groups_2_outlined, color: ReactColors.electricBlueBright, size: 36),
              const SizedBox(height: 8),
              const Text('PASS IT', style: TextStyle(color: ReactColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
              const SizedBox(height: 6),
              const Text("FAIL A COMMAND AND YOU'RE OUT", style: TextStyle(color: ReactColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              const SizedBox(height: 22),
              const _SectionTitle('PLAYERS'),
              const SizedBox(height: 12),
              const _PlayerRow(index: 1, color: ReactColors.electricBlueBright, enabled: true),
              const SizedBox(height: 10),
              const _PlayerRow(index: 2, color: ReactColors.lime, enabled: true),
              const SizedBox(height: 10),
              const _PlayerRow(index: 3, color: ReactColors.coral, enabled: true),
              const SizedBox(height: 10),
              const _PlayerRow(index: 4, color: Color(0xFF52627A), enabled: false),
              const SizedBox(height: 22),
              const _SectionTitle('RULES'),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _RuleCard(icon: Icons.favorite_border_rounded, title: '3 LIVES', subtitle: 'Each player has 3 lives', color: ReactColors.coral)),
                  SizedBox(width: 10),
                  Expanded(child: _RuleCard(icon: Icons.bolt_rounded, title: 'FAST SPEED', subtitle: 'Commands come faster', color: ReactColors.lime)),
                  SizedBox(width: 10),
                  Expanded(child: _RuleCard(icon: Icons.shuffle_rounded, title: 'RANDOM', subtitle: 'True random order', color: ReactColors.purple)),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionTitle('COMMAND PREVIEW'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF07111D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF293B54)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.touch_app_rounded, color: ReactColors.electricBlueBright),
                    Icon(Icons.double_arrow_rounded, color: ReactColors.electricBlue),
                    Icon(Icons.close_fullscreen_rounded, color: ReactColors.lime),
                    Icon(Icons.open_in_full_rounded, color: ReactColors.purple),
                    Icon(Icons.ac_unit_rounded, color: ReactColors.coral),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C3462),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF235B8E)),
                ),
                child: const Center(
                  child: Text('START GAME', style: TextStyle(color: Color(0xFF7EA3C8), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('PASS IT GAMEPLAY COMING NEXT', style: TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF263851))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
        ),
        const Expanded(child: Divider(color: Color(0xFF263851))),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.index, required this.color, required this.enabled});
  final int index;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: enabled && index == 1 ? ReactColors.electricBlue : const Color(0xFF293B54)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF0A1525),
            child: Icon(Icons.person_rounded, color: enabled ? color : const Color(0xFF52627A), size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Player $index',
              style: TextStyle(color: enabled ? ReactColors.textPrimary : const Color(0xFF52627A), fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Icon(enabled ? Icons.edit_outlined : Icons.lock_outline_rounded, color: enabled ? ReactColors.textSecondary : const Color(0xFF52627A), size: 20),
          const SizedBox(width: 14),
          Text('$index', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.icon, required this.title, required this.subtitle, required this.color});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 9, height: 1.25, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
