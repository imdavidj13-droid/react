import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class BlitzScreen extends StatelessWidget {
  const BlitzScreen({super.key});

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
                'BLITZ',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'FAST. SHORT. BRUTAL.',
                style: TextStyle(
                  color: ReactColors.coral,
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
                      icon: Icons.timer_outlined,
                      label: '60 SEC',
                      detail: 'One minute run',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.speed_rounded,
                      label: 'FAST',
                      detail: 'Shorter timers',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.bolt_rounded,
                      label: '10',
                      detail: 'All commands',
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
                  border: Border.all(color: const Color(0xFF3B2A3F)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: ReactColors.coral),
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
        border: Border.all(color: ReactColors.coral, width: 4),
      ),
      child: const Center(
        child: Icon(Icons.timer_rounded, color: ReactColors.coral, size: 76),
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
          Icon(icon, color: ReactColors.coral, size: 25),
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
