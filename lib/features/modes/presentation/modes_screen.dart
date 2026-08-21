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
import '../../season/data/season_cosmetic_state.dart';
import '../../season/presentation/season_cosmetic_layers.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/react_variant_mode.dart';
import 'variant_mode_screen.dart';

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key});

  static final List<ReactVariantMode> retainedLabModes = ReactVariantMode.values
      .where((mode) => mode.enabled)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    final coreModes = <_ModeData>[
      _ModeData(title: 'CLASSIC', subtitle: 'Survive as long as you can.', detail: '3 LIVES  •  SPEED RAMPS', icon: Icons.bolt_rounded, color: ReactColors.electricBlueBright, badge: 'CORE MODE', onTap: () => open(const ClassicScreen())),
      _ModeData(title: 'BLITZ', subtitle: '60 seconds. Maximum pace.', detail: 'FAST TIMER  •  SCORE ATTACK', icon: Icons.timer_rounded, color: ReactColors.coral, badge: '60 SEC', onTap: () => open(const BlitzScreen())),
      _ModeData(title: 'ENDLESS', subtitle: 'Keep going until you miss.', detail: 'NO LIMIT  •  INTENSITY RAMPS FAST', icon: Icons.all_inclusive_rounded, color: ReactColors.lime, badge: 'NO LIMIT', onTap: () => open(const EndlessScreen())),
      _ModeData(title: 'SEQUENCE', subtitle: 'Tap numbered dots in exact order.', detail: '2–5 DOTS  •  RANDOM POSITIONS  •  3 LIVES', icon: Icons.blur_circular_rounded, color: ReactColors.electricBlueBright, badge: 'SEQUENCE', onTap: () => open(const ReactRunLaunchScreen(mode: ReactGameMode.sequence))),
      _ModeData(title: 'PASS IT', subtitle: 'Local multiplayer reaction rounds.', detail: '2–4 PLAYERS  •  ONE DEVICE', icon: Icons.groups_2_outlined, color: ReactColors.purple, badge: 'MULTIPLAYER', onTap: () => open(const PassItScreen())),
      _ModeData(title: 'DAILY', subtitle: 'A different rule every day.', detail: '7 ROTATING MODIFIERS  •  BEST COUNTS', icon: Icons.calendar_month_rounded, color: ReactColors.lime, badge: 'DAILY RUN', onTap: () => open(const DailyScreen())),
      _ModeData(title: 'SCORES', subtitle: 'See your established records.', detail: 'LOCAL RECORDS  •  CORE MODES', icon: Icons.leaderboard_rounded, color: ReactColors.purple, badge: 'RECORDS', onTap: () => open(const LeaderboardScreen())),
      _ModeData(title: 'SETTINGS', subtitle: 'Performance and game preferences.', detail: 'PERFORMANCE  •  EFFECTS  •  LOCAL DATA', icon: Icons.settings_outlined, color: ReactColors.electricBlueBright, badge: 'SETTINGS', onTap: () => open(const SettingsScreen())),
    ];

    final labModes = retainedLabModes
        .map((mode) => _ModeData(title: mode.title, subtitle: mode.subtitle, detail: mode.detail, icon: mode.icon, color: mode.color, badge: mode.badge, onTap: () => open(VariantModeScreen(mode: mode))))
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
                SliverPadding(padding: EdgeInsets.fromLTRB(pad, 8, pad, 0), sliver: SliverToBoxAdapter(child: _Header(onBack: () => Navigator.of(context).pop()))),
                SliverPadding(padding: EdgeInsets.fromLTRB(pad, 12, pad, 0), sliver: const SliverToBoxAdapter(child: _ModesHero())),
                SliverPadding(padding: EdgeInsets.fromLTRB(pad, 18, pad, 9), sliver: const SliverToBoxAdapter(child: _SectionTitle(title: 'CORE & UTILITIES', subtitle: 'ESTABLISHED MODES, RECORDS AND SETTINGS'))),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) => _ModePanel(data: coreModes[index]), childCount: coreModes.length),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 9, mainAxisSpacing: 9, mainAxisExtent: 190),
                  ),
                ),
                SliverPadding(padding: EdgeInsets.fromLTRB(pad, 24, pad, 9), sliver: SliverToBoxAdapter(child: _SectionTitle(title: 'MODE LAB', subtitle: '${labModes.length} ENABLED VARIANTS  •  EXPERIMENTAL LIBRARY'))),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 28),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) => _ModePanel(data: labModes[index]), childCount: labModes.length),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 9, mainAxisSpacing: 9, mainAxisExtent: 190),
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
  const _ModeData({required this.title, required this.subtitle, required this.detail, required this.icon, required this.color, required this.badge, required this.onTap});
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
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(onPressed: onBack, style: IconButton.styleFrom(side: const BorderSide(color: Color(0xFF1E3552)), backgroundColor: const Color(0xFF07101E), foregroundColor: ReactColors.textPrimary), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
          const Spacer(),
          const Row(mainAxisSize: MainAxisSize.min, children: [Text('RE', style: TextStyle(color: ReactColors.textPrimary, fontSize: 25, fontWeight: FontWeight.w600, letterSpacing: 2)), Icon(Icons.change_history_rounded, color: ReactColors.electricBlueBright, size: 24), Text('CT', style: TextStyle(color: ReactColors.textPrimary, fontSize: 25, fontWeight: FontWeight.w600, letterSpacing: 2))]),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      );
}

class _ModesHero extends StatelessWidget {
  const _ModesHero();

  @override
  Widget build(BuildContext context) => Container(
        height: 116,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF07111D), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF25425F))),
        child: Row(children: [
          const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('MODES', maxLines: 1, style: TextStyle(color: ReactColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.5))), SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('DIFFERENT RULES.  SAME REFLEXES.', maxLines: 1, style: TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)))])),
          Container(width: 82, height: 82, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ReactColors.electricBlueBright, width: 2), boxShadow: const [BoxShadow(color: ReactColors.electricBlueBright, blurRadius: 18, spreadRadius: -10)]), child: const Icon(Icons.change_history_rounded, color: ReactColors.electricBlueBright, size: 42)),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(height: 2), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: .75))]))]);
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({required this.data});
  final _ModeData data;

  @override
  Widget build(BuildContext context) {
    final skin = SeasonCosmeticState.equippedReward('mode_card_skin');
    final seasonAccent = skin == null ? null : SeasonCosmeticLayers.accentForReward(skin);
    final borderColor = seasonAccent ?? data.color;
    final skinKey = skin?.rewardKey ?? '';
    final ion = skinKey.contains('ion');
    final gridline = skinKey.contains('gridline');
    final overdrive = skinKey.contains('overdrive');
    final radius = ion ? 12.0 : gridline ? 5.0 : 22.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.all(gridline ? 11 : 13),
          decoration: BoxDecoration(
            gradient: skin == null
                ? null
                : LinearGradient(
                    begin: overdrive ? Alignment.bottomLeft : Alignment.topLeft,
                    end: overdrive ? Alignment.topRight : Alignment.bottomRight,
                    colors: ion
                        ? [
                            seasonAccent!.withValues(alpha: .20),
                            const Color(0xFF050A13),
                            seasonAccent.withValues(alpha: .06),
                          ]
                        : gridline
                            ? [
                                const Color(0xFF050A13),
                                seasonAccent!.withValues(alpha: .08),
                                const Color(0xFF050A13),
                              ]
                            : [
                                seasonAccent!.withValues(alpha: .16),
                                const Color(0xFF07111D),
                                seasonAccent.withValues(alpha: .035),
                              ],
                  ),
            color: skin == null ? const Color(0xFF07111D) : null,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor.withValues(alpha: overdrive ? .92 : .68),
              width: ion ? 1.8 : gridline ? 1 : overdrive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(
                  alpha: skin == null ? .05 : overdrive ? .20 : .12,
                ),
                blurRadius: skin == null ? 16 : overdrive ? 28 : 22,
              ),
            ],
          ),
          child: Stack(
            children: [
              if (gridline)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ModeCardGridPainter(borderColor),
                    ),
                  ),
                ),
              if (overdrive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.change_history_rounded,
                    color: borderColor.withValues(alpha: .16),
                    size: 54,
                  ),
                ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: ion ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: ion ? BorderRadius.circular(10) : null,
                      color: const Color(0xFF050A13),
                      border: Border.all(color: borderColor, width: ion ? 2 : 1.6),
                    ),
                    child: Icon(data.icon, color: borderColor, size: 22),
                  ),
                  const Spacer(),
                  if (skin != null) ...[
                    Icon(
                      ion
                          ? Icons.blur_on_rounded
                          : gridline
                              ? Icons.grid_4x4_rounded
                              : Icons.auto_awesome_rounded,
                      color: seasonAccent,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(child: _Badge(label: data.badge, color: borderColor)),
                ]),
                const SizedBox(height: 10),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(data.title, maxLines: 1, style: TextStyle(color: ReactColors.textPrimary, fontSize: overdrive ? 20 : 19, fontWeight: FontWeight.w900, letterSpacing: gridline ? 1.1 : .6))),
                const SizedBox(height: 4),
                Expanded(child: Align(alignment: Alignment.topLeft, child: Text(data.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 10, height: 1.25, fontWeight: FontWeight.w600)))),
                const SizedBox(height: 5),
                Row(children: [Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(data.detail, maxLines: 1, style: TextStyle(color: borderColor, fontSize: 7.1, fontWeight: FontWeight.w900, letterSpacing: .45)))), const SizedBox(width: 4), Icon(Icons.chevron_right_rounded, color: borderColor, size: 19)]),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCardGridPainter extends CustomPainter {
  const _ModeCardGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .055)
      ..strokeWidth = .6;
    const gap = 18.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ModeCardGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: .06), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: .48))),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: .7))),
      );
}