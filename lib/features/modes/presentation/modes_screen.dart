import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../blitz/presentation/blitz_screen.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../daily/presentation/daily_screen.dart';
import '../../endless/presentation/endless_screen.dart';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 380 ? 16.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 24),
                  const Text(
                    'CHOOSE YOUR MODE',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'DIFFERENT RULES. SAME REFLEXES.',
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FeaturedModeCard(
                    title: 'CLASSIC',
                    subtitle: 'Survive as long as you can.',
                    detail: '10 COMMANDS  •  RANDOM ORDER',
                    icon: Icons.bolt_rounded,
                    color: ReactColors.electricBlueBright,
                    badge: 'CORE MODE',
                    onTap: () => open(const ClassicScreen()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactModeCard(
                          title: 'BLITZ',
                          subtitle: '60 seconds. Maximum pace.',
                          icon: Icons.timer_rounded,
                          color: ReactColors.coral,
                          badge: '60 SEC',
                          onTap: () => open(const BlitzScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactModeCard(
                          title: 'ENDLESS',
                          subtitle: 'Keep going until you miss.',
                          icon: Icons.all_inclusive_rounded,
                          color: ReactColors.lime,
                          badge: 'NO LIMIT',
                          onTap: () => open(const EndlessScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactModeCard(
                          title: 'PASS IT',
                          subtitle: 'Local multiplayer reaction rounds.',
                          icon: Icons.groups_2_outlined,
                          color: ReactColors.purple,
                          badge: '2+ PLAYERS',
                          onTap: () => open(const PassItScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactModeCard(
                          title: 'DAILY',
                          subtitle: 'One shared challenge each day.',
                          icon: Icons.calendar_month_rounded,
                          color: ReactColors.lime,
                          badge: '1 RUN',
                          onTap: () => open(const DailyScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _WideModeCard(
                    title: 'TRAINING',
                    subtitle: 'Practise each command individually.',
                    icon: Icons.school_outlined,
                    color: ReactColors.electricBlue,
                    onTap: () => open(const TrainingScreen()),
                  ),
                  const SizedBox(height: 12),
                  _WideModeCard(
                    title: 'LEADERBOARD',
                    subtitle: 'Compare Classic scores and rank.',
                    icon: Icons.leaderboard_rounded,
                    color: ReactColors.purple,
                    onTap: () => open(const LeaderboardScreen()),
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
            side: const BorderSide(color: Color(0xFF1E3552)),
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Spacer(),
        const _ReactLogo(),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _ReactLogo extends StatelessWidget {
  const _ReactLogo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RE',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
          ),
        ),
        Icon(
          Icons.change_history_rounded,
          color: ReactColors.electricBlueBright,
          size: 27,
        ),
        Text(
          'CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

class _FeaturedModeCard extends StatelessWidget {
  const _FeaturedModeCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.color,
    required this.badge,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color color;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: .8), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF050A13),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 38),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Badge(label: badge, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    detail,
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}

class _CompactModeCard extends StatelessWidget {
  const _CompactModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badge,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 166,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .48)),
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
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: .85)),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: color, size: 20),
              ],
            ),
            const Spacer(),
            _Badge(label: badge, color: color),
            const SizedBox(height: 7),
            Text(
              title,
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 9.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideModeCard extends StatelessWidget {
  const _WideModeCard({
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF263B58)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: .8)),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 10,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: .9,
        ),
      ),
    );
  }
}
