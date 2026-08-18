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
import '../domain/react_variant_mode.dart';
import 'variant_mode_screen.dart';

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    final coreModes = <_ModeData>[
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
        subtitle: 'Tap numbered dots in exact order.',
        detail: '2–5 DOTS  •  RANDOM POSITIONS  •  3 LIVES',
        icon: Icons.blur_circular_rounded,
        color: ReactColors.electricBlueBright,
        badge: 'SEQUENCE',
        onTap: () => open(const ReactRunLaunchScreen(mode: ReactGameMode.sequence)),
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
        detail: '7 ROTATING MODIFIERS  •  BEST COUNTS',
        icon: Icons.calendar_month_rounded,
        color: ReactColors.lime,
        badge: 'DAILY RUN',
        onTap: () => open(const DailyScreen()),
      ),
      _ModeData(
        title: 'SCORES',
        subtitle: 'See your established records.',
        detail: 'LOCAL RECORDS  •  CORE MODES',
        icon: Icons.leaderboard_rounded,
        color: ReactColors.purple,
        badge: 'RECORDS',
        onTap: () => open(const LeaderboardScreen()),
      ),
      _ModeData(
        title: 'PROFILE',
        subtitle: 'Stats and game preferences.',
        detail: 'PERFORMANCE  •  EFFECTS  •  SETTINGS',
        icon: Icons.person_outline_rounded,
        color: ReactColors.electricBlueBright,
        badge: 'SETTINGS',
        onTap: () => open(const SettingsScreen()),
      ),
    ];

    final labModes = ReactVariantMode.values
        .where(
          (mode) =>
              mode != ReactVariantMode.tether &&
              mode != ReactVariantMode.overload &&
              mode != ReactVariantMode.lockstep &&
              mode != ReactVariantMode.zenith &&
              mode != ReactVariantMode.pulse &&
              mode != ReactVariantMode.shuffle &&
              mode != ReactVariantMode.fuse &&
              mode != ReactVariantMode.orbit &&
              mode != ReactVariantMode.echo,
        )
        .map(
          (mode) => _ModeData(
            title: mode.title,
            subtitle: mode.subtitle,
            detail: mode.detail,
            icon: mode.icon,
            color: mode.color,
            badge: mode.badge,
            onTap: () => open(VariantModeScreen(mode: mode)),
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 380 ? 12.0 : 16.0;
            return CustomScrollView(
              key: const ValueKey('modes_catalogue_scroll'),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Header(onBack: () => Navigator.of(context).pop()),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                  sliver: const SliverToBoxAdapter(child: _ModesHero()),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 18, pad, 9),
                  sliver: const SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'CORE & UTILITIES',
                      subtitle: 'ESTABLISHED MODES, RECORDS AND SETTINGS',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ModePanel(data: coreModes[index]),
                      childCount: coreModes.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      mainAxisExtent: 190,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 24, pad, 9),
                  sliver: SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'MODE LAB',
                      subtitle: '${labModes.length} PLAYABLE VARIANTS  •  TEST WHAT EARNS A PERMANENT SLOT',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 28),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ModePanel(data: labModes[index]),
                      childCount: labModes.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      mainAxisExtent: 190,
                    ),
                  ),
                ),
              ],
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
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ModesHero extends StatelessWidget {
  const _ModesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
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
                    'MODES',
                    maxLines: 1,
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DIFFERENT RULES.  SAME REFLEXES.',
                    maxLines: 1,
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ReactColors.electricBlueBright,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: ReactColors.electricBlueBright,
                  blurRadius: 18,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const Icon(
              Icons.change_history_rounded,
              color: ReactColors.electricBlueBright,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
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
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .75,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({required this.data});
  final _ModeData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF07111D),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: data.color.withValues(alpha: .62)),
            boxShadow: [
              BoxShadow(
                color: data.color.withValues(alpha: .05),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF050A13),
                      border: Border.all(color: data.color, width: 1.6),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22),
                  ),
                  const Spacer(),
                  Flexible(child: _Badge(label: data.badge, color: data.color)),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.title,
                  maxLines: 1,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 10,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        data.detail,
                        maxLines: 1,
                        style: TextStyle(
                          color: data.color,
                          fontSize: 7.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: data.color, size: 19),
                ],
              ),
            ],
          ),
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
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .48)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ),
      );
}
