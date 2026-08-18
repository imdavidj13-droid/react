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
            final pad = constraints.maxWidth < 380 ? 12.0 : 16.0;
            final shortScreen = constraints.maxHeight < 700;
            final heroHeight = shortScreen ? 88.0 : 104.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(pad, 6, pad, 8),
              child: Column(
                children: [
                  _compactTextScale(
                    context,
                    _Header(onBack: () => Navigator.of(context).pop()),
                  ),
                  SizedBox(height: shortScreen ? 5 : 8),
                  SizedBox(
                    height: heroHeight,
                    child: _compactTextScale(context, const _ModesHero()),
                  ),
                  SizedBox(height: shortScreen ? 5 : 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        const rowCount = 4;
                        final spacing = shortScreen ? 5.0 : 7.0;
                        final rowHeight =
                            (gridConstraints.maxHeight - spacing * (rowCount - 1)) /
                                rowCount;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: modes.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            mainAxisExtent: rowHeight,
                          ),
                          itemBuilder: (context, index) => _compactTextScale(
                            context,
                            _ModePanel(data: modes[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _compactTextScale(BuildContext context, Widget child) {
    final media = MediaQuery.of(context);
    final currentScale = media.textScaler.scale(1);
    final clampedScale = currentScale > 1.1 ? 1.1 : currentScale;
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(clampedScale)),
      child: child,
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
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onBack,
              style: IconButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E3552)),
                backgroundColor: const Color(0xFF07101E),
                foregroundColor: ReactColors.textPrimary,
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            ),
          ),
          const Spacer(),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RE',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              Icon(
                Icons.change_history_rounded,
                color: ReactColors.electricBlueBright,
                size: 24,
              ),
              Text(
                'CT',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ModesHero extends StatelessWidget {
  const _ModesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF25425F)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CHOOSE YOUR MODE',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'DIFFERENT RULES.  SAME REFLEXES.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 72, maxHeight: 72),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ReactColors.electricBlueBright,
                  width: 1.7,
                ),
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                color: ReactColors.electricBlueBright,
                size: 30,
              ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final tiny = constraints.maxHeight < 78;
        final iconSize = tiny ? 22.0 : 26.0;

        return InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.fromLTRB(7, tiny ? 5 : 6, 7, tiny ? 4 : 5),
            decoration: BoxDecoration(
              color: const Color(0xFF07111D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: data.color.withValues(alpha: .5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF050A13),
                        border: Border.all(
                          color: data.color.withValues(alpha: .85),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        data.icon,
                        color: data.color,
                        size: tiny ? 12 : 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: _Badge(label: data.badge, color: data.color)),
                  ],
                ),
                SizedBox(height: tiny ? 2 : 3),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          data.title,
                          style: TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: tiny ? 11 : 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .45,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: data.color,
                      size: tiny ? 13 : 15,
                    ),
                  ],
                ),
                if (!tiny) ...[
                  const SizedBox(height: 1),
                  Expanded(
                    child: Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 7.4,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.detail,
                    maxLines: 1,
                    style: TextStyle(
                      color: data.color.withValues(alpha: .9),
                      fontSize: tiny ? 5.2 : 5.8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 66),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
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
              fontSize: 5.8,
              fontWeight: FontWeight.w900,
              letterSpacing: .45,
            ),
          ),
        ),
      ),
    );
  }
}
