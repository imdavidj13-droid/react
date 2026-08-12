import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class EndlessScreen extends StatelessWidget {
  const EndlessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const Spacer(),
              const _ModeOrb(),
              const SizedBox(height: 26),
              const Text(
                'ENDLESS',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'NO FINISH LINE.',
                style: TextStyle(
                  color: ReactColors.lime,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.all_inclusive_rounded,
                      label: '∞',
                      detail: 'Keep reacting',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.trending_up_rounded,
                      label: 'RAMP',
                      detail: 'Gets faster',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.workspace_premium_outlined,
                      label: 'BEST',
                      detail: 'Chase records',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF07111D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF32461F)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: ReactColors.lime),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'GAMEPLAY COMING NEXT',
                        style: TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ModeOrb extends StatelessWidget {
  const _ModeOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 174,
      height: 174,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF07111D),
        border: Border.all(color: ReactColors.lime, width: 4),
      ),
      child: const Center(
        child: Icon(Icons.all_inclusive_rounded, color: ReactColors.lime, size: 82),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF293B54)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ReactColors.lime, size: 25),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
