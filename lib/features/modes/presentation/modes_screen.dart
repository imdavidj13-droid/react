import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../blitz/presentation/blitz_screen.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../daily/presentation/daily_screen.dart';
import '../../endless/presentation/endless_screen.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../pass_it/presentation/pass_it_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    final modes = <_ModeData>[
      _ModeData(
        title: 'CLASSIC',
        subtitle: 'Survive as long as you can.',
        detail: '3 LIVES  •  SPEED RAMPS',
        icon: Icons.bolt_rounded,
        color: ReactColors.electricBlueBright,
        badge: 'CORE MODE',
        onTap: () => open(const ClassicScreen()),
      ),
      _ModeData(
        title: 'BLITZ',
        subtitle: '60 seconds. Maximum pace.',
        detail: 'FAST TIMER  •  SCORE ATTACK',
        icon: Icons.timer_rounded,
        color: ReactColors.coral,
        badge: '60 SEC',
        onTap: () => open(const BlitzScreen()),
      ),
      _ModeData(
        title: 'ENDLESS',
        subtitle: 'Keep going until you miss.',
        detail: 'NO LIMIT  •  INTENSITY RAMPS FAST',
        icon: Icons.all_inclusive_rounded,
        color: ReactColors.lime,
        badge: 'NO LIMIT',
        onTap: () => open(const EndlessScreen()),
      ),
      _ModeData(
        title: 'SEQUENCE',
        subtitle: 'Tap numbered dots in the exact order.',
        detail: '2–5 DOTS  •  RANDOM POSITIONS  •  3 LIVES',
        icon: Icons.blur_circular_rounded,
        color: ReactColors.electricBlueBright,
        badge: 'NEW MODE',
        onTap: () => open(
          const ReactRunLaunchScreen(mode: ReactGameMode.sequence),
        ),
      ),
      _ModeData(
        title: 'PASS IT',
        subtitle: 'Local multiplayer reaction rounds.',
        detail: '2–4 PLAYERS  •  ONE DEVICE',
        icon: Icons.groups_2_outlined,
        color: ReactColors.purple,
        badge: 'MULTIPLAYER',
        onTap: () => open(const PassItScreen()),
      ),
      _ModeData(
        title: 'DAILY',
        subtitle: 'A different rule every day.',
        detail: 'NO COMMAND CAP  •  7 ROTATING MODIFIERS',
        icon: Icons.calendar_month_rounded,
        color: ReactColors.lime,
        badge: 'DAILY RUN',
        onTap: () => open(const DailyScreen()),
      ),
      _ModeData(
        title: 'SCORES',
        subtitle: 'See your best runs on this device.',
        detail: 'LOCAL RECORDS  •  EVERY MODE',
        icon: Icons.leaderboard_rounded,
        color: ReactColors.purple,
        badge: 'RECORDS',
        onTap: () => open(const LeaderboardScreen()),
      ),
      _ModeData(
        title: 'PROFILE',
        subtitle: 'Local stats and game preferences.',
        detail: 'PERFORMANCE  •  VISUAL EFFECTS  •  RECORDS',
        icon: Icons.person_outline_rounded,
        color: ReactColors.electricBlueBright,
        badge: 'SETTINGS',
        onTap: () => open(const SettingsScreen()),
      ),
    ];

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final pad = constraints.maxWidth < 380 ? 16.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 22),
                  const _ModesHero(),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: compact ? .64 : .76,
                    ),
                    itemBuilder: (context, index) => _ModePanel(data: modes[index]),
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

class _ModeData {
  const _ModeData({
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
        const Row(
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
        ),
        const Spacer(),
        const SizedBox(width: 40),
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
      padding: const EdgeInsets.all(18),
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
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ReactColors.electricBlueBright, width: 2),
            ),
            child: const Icon(
              Icons.view_in_ar_rounded,
              color: ReactColors.electricBlueBright,
              size: 39,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({required this.data});
  final _ModeData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: data.color.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF050A13),
                    border: Border.all(
                      color: data.color.withValues(alpha: .85),
                      width: 1.6,
                    ),
                  ),
                  child: Icon(data.icon, color: data.color, size: 21),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _Badge(label: data.badge, color: data.color),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.title,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 9.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              data.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.color.withValues(alpha: .9),
                fontSize: 7,
                height: 1.25,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.chevron_right_rounded, color: data.color, size: 20),
            ),
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
      constraints: const BoxConstraints(maxWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 6.4,
            fontWeight: FontWeight.w900,
            letterSpacing: .65,
          ),
        ),
      ),
    );
  }
}
