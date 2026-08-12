import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../blitz/presentation/blitz_screen.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../daily/presentation/daily_screen.dart';
import '../../endless/presentation/endless_screen.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../pass_it/presentation/pass_it_screen.dart';

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
                  const SizedBox(height: 22),
                  const _ModesHero(),
                  const SizedBox(height: 20),
                  _ModePanel(
                    title: 'CLASSIC',
                    subtitle: 'Survive as long as you can.',
                    detail: '9 COMMANDS  •  RANDOM ORDER',
                    icon: Icons.bolt_rounded,
                    color: ReactColors.electricBlueBright,
                    badge: 'CORE MODE',
                    onTap: () => open(const ClassicScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ModePanel(
                    title: 'BLITZ',
                    subtitle: '60 seconds. Maximum pace.',
                    detail: 'FAST TIMER  •  SCORE ATTACK',
                    icon: Icons.timer_rounded,
                    color: ReactColors.coral,
                    badge: '60 SEC',
                    onTap: () => open(const BlitzScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ModePanel(
                    title: 'ENDLESS',
                    subtitle: 'Keep going until you miss.',
                    detail: 'NO LIMIT  •  BUILD YOUR STREAK',
                    icon: Icons.all_inclusive_rounded,
                    color: ReactColors.lime,
                    badge: 'NO LIMIT',
                    onTap: () => open(const EndlessScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ModePanel(
                    title: 'PASS IT',
                    subtitle: 'Local multiplayer reaction rounds.',
                    detail: '2+ PLAYERS  •  ONE DEVICE',
                    icon: Icons.groups_2_outlined,
                    color: ReactColors.purple,
                    badge: 'MULTIPLAYER',
                    onTap: () => open(const PassItScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ModePanel(
                    title: 'DAILY',
                    subtitle: 'One shared challenge each day.',
                    detail: '1 ATTEMPT  •  GLOBAL SCORE',
                    icon: Icons.calendar_month_rounded,
                    color: ReactColors.lime,
                    badge: 'DAILY RUN',
                    onTap: () => open(const DailyScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ModePanel(
                    title: 'LEADERBOARD',
                    subtitle: 'Compare Classic scores and rank.',
                    detail: 'GLOBAL RANK  •  SEASON SCORE',
                    icon: Icons.leaderboard_rounded,
                    color: ReactColors.purple,
                    badge: 'RANKINGS',
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

class _ModesHero extends StatelessWidget {
  const _ModesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF25425F)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHOOSE YOUR MODE',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'DIFFERENT RULES.\nSAME REFLEXES.',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 10,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ReactColors.electricBlueBright,
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ReactColors.purple.withValues(alpha: .8),
                    ),
                  ),
                ),
                const Icon(
                  Icons.view_in_ar_rounded,
                  color: ReactColors.electricBlueBright,
                  size: 39,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(15, 15, 14, 15),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .5)),
        ),
        child: Row(
          children: [
            _ModeEmblem(icon: icon, color: color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                      _Badge(label: badge, color: color),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          detail,
                          style: TextStyle(
                            color: color.withValues(alpha: .9),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .95,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: .55)),
              ),
              child: Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeEmblem extends StatelessWidget {
  const _ModeEmblem({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(
                color: color.withValues(alpha: .85),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .28)),
            ),
          ),
          Icon(icon, color: color, size: 31),
        ],
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
          fontSize: 6.7,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}
