import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../daily/presentation/daily_screen.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../pass_it/presentation/pass_it_screen.dart';
import '../../training/presentation/training_screen.dart';

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
    }

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 22),
              const Text(
                'CHOOSE YOUR MODE',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'DIFFERENT RULES. SAME REFLEXES.',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              _ModeCard(
                title: 'CLASSIC',
                subtitle: 'Survive as long as you can.',
                icon: Icons.bolt_rounded,
                color: ReactColors.electricBlueBright,
                onTap: () => open(const ClassicScreen()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SmallModeCard(
                      title: 'BLITZ',
                      subtitle: 'Fast. Short. Brutal.',
                      icon: Icons.timer_rounded,
                      color: ReactColors.coral,
                      onTap: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallModeCard(
                      title: 'ENDLESS',
                      subtitle: 'No finish line.',
                      icon: Icons.all_inclusive_rounded,
                      color: ReactColors.lime,
                      onTap: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SmallModeCard(
                      title: 'PASS IT',
                      subtitle: 'Local multiplayer.',
                      icon: Icons.groups_2_outlined,
                      color: ReactColors.purple,
                      onTap: () => open(const PassItScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallModeCard(
                      title: 'DAILY',
                      subtitle: 'One global challenge.',
                      icon: Icons.calendar_month_rounded,
                      color: ReactColors.lime,
                      onTap: () => open(const DailyScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ModeCard(
                title: 'TRAINING',
                subtitle: 'Learn every command before you compete.',
                icon: Icons.school_outlined,
                color: ReactColors.electricBlue,
                onTap: () => open(const TrainingScreen()),
              ),
              const SizedBox(height: 12),
              _ModeCard(
                title: 'LEADERBOARD',
                subtitle: 'Compare scores and seasonal rank.',
                icon: Icons.leaderboard_rounded,
                color: ReactColors.purple,
                onTap: () => open(const LeaderboardScreen()),
              ),
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
            side: const BorderSide(color: Color(0xFF1E3552)),
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Spacer(),
        const Text(
          'RE△CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 30,
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .7)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _SmallModeCard extends StatelessWidget {
  const _SmallModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: onTap == null
                ? const Color(0xFF293B54)
                : color.withValues(alpha: .55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 10,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
