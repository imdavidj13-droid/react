import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../daily/presentation/daily_screen.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../modes/presentation/modes_screen.dart';
import '../../season/presentation/season_locker_screen.dart';
import '../../season/presentation/season_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tutorial/presentation/how_to_play_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeStats> _stats;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _stats = _HomeStats.load();
  }

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<_HomeStats>(
          future: _stats,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? const _HomeStats();
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 780;
                final veryCompact = constraints.maxHeight < 700;
                final pad = constraints.maxWidth < 380 ? 14.0 : 18.0;
                final maxDial = constraints.maxWidth.clamp(270.0, 330.0).toDouble();
                final dialCap = veryCompact
                    ? 202.0
                    : compact
                        ? 232.0
                        : maxDial;

                return Padding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, compact ? 8 : 12),
                  child: Column(
                    children: [
                      const _TopSection(),
                      SizedBox(height: compact ? 8 : 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _BestScore(score: stats.classicBest)),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Streak(days: stats.dailyStreak),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 7 : 10),
                      _RecordStrip(stats: stats),
                      SizedBox(height: compact ? 1 : 5),
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, dialConstraints) {
                              final available = math.min(
                                dialConstraints.maxWidth,
                                dialConstraints.maxHeight,
                              );
                              final dialSize = available
                                  .clamp(172.0, dialCap)
                                  .toDouble();
                              return _PlayDial(
                                size: dialSize,
                                onTap: () => _open(context, const ClassicScreen()),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 3 : 7),
                      _PlayButton(
                        compact: compact,
                        onTap: () => _open(context, const ClassicScreen()),
                      ),
                      SizedBox(height: compact ? 7 : 10),
                      _HomeNavGrid(
                        compact: compact,
                        stats: stats,
                        open: (screen) => _open(context, screen),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HomeStats {
  const _HomeStats({
    this.classicBest = 0,
    this.blitzBest = 0,
    this.endlessBest = 0,
    this.sequenceBest = 0,
    this.dailyStreak = 0,
    this.runsPlayed = 0,
    this.dailyPlayedToday = false,
  });

  final int classicBest;
  final int blitzBest;
  final int endlessBest;
  final int sequenceBest;
  final int dailyStreak;
  final int runsPlayed;
  final bool dailyPlayedToday;

  static Future<_HomeStats> load() async {
    final values = await Future.wait<Object>([
      LocalPlayerStats.bestFor(ReactGameMode.classic),
      LocalPlayerStats.bestFor(ReactGameMode.blitz),
      LocalPlayerStats.bestFor(ReactGameMode.endless),
      LocalPlayerStats.bestFor(ReactGameMode.sequence),
      LocalPlayerStats.dailyStreak(),
      LocalPlayerStats.runsPlayed(),
      LocalPlayerStats.hasPlayedDailyToday(),
    ]);
    return _HomeStats(
      classicBest: values[0] as int,
      blitzBest: values[1] as int,
      endlessBest: values[2] as int,
      sequenceBest: values[3] as int,
      dailyStreak: values[4] as int,
      runsPlayed: values[5] as int,
      dailyPlayedToday: values[6] as bool,
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Column(
        children: [
          _Logo(),
          SizedBox(height: 6),
          Text(
            'FOLLOW THE COMMAND\nBEFORE TIME RUNS OUT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('RE', style: _logoStyle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.change_history_rounded,
            color: Color(0xFF2DDCFF),
            size: 39,
          ),
        ),
        Text('CT', style: _logoStyle),
      ],
    );
  }

  static const _logoStyle = TextStyle(
    color: ReactColors.textPrimary,
    fontSize: 42,
    fontWeight: FontWeight.w300,
    letterSpacing: 3.2,
    height: 1,
  );
}

class _BestScore extends StatelessWidget {
  const _BestScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: const Color(0xCC07111D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233651)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: ReactColors.lime,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLASSIC BEST',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: ReactColors.lime,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'ON THIS DEVICE',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Streak extends StatelessWidget {
  const _Streak({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF7A72), width: 3.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: ReactColors.coral,
                  size: 20,
                ),
                Text(
                  '$days',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'DAILY STREAK',
            style: TextStyle(
              color: ReactColors.coral,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordStrip extends StatelessWidget {
  const _RecordStrip({required this.stats});

  final _HomeStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC07111D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233651)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RecordMetric(
              label: 'BLITZ',
              value: '${stats.blitzBest}',
              color: ReactColors.coral,
            ),
          ),
          const _RecordDivider(),
          Expanded(
            child: _RecordMetric(
              label: 'ENDLESS',
              value: '${stats.endlessBest}',
              color: ReactColors.lime,
            ),
          ),
          const _RecordDivider(),
          Expanded(
            child: _RecordMetric(
              label: 'SEQUENCE',
              value: '${stats.sequenceBest}',
              color: ReactColors.electricBlueBright,
            ),
          ),
          const _RecordDivider(),
          Expanded(
            child: _RecordMetric(
              label: 'RUNS',
              value: '${stats.runsPlayed}',
              color: ReactColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordMetric extends StatelessWidget {
  const _RecordMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordDivider extends StatelessWidget {
  const _RecordDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFF1D3048),
    );
  }
}

class _PlayDial extends StatelessWidget {
  const _PlayDial({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _DialPainter(),
          child: Center(
            child: Container(
              width: size * .50,
              height: size * .50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ReactColors.background,
                border: Border.all(
                  color: const Color(0xFF42D8FF),
                  width: 2.5,
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: const Color(0xFF39D8FF),
                size: (size * .22).clamp(45.0, 74.0).toDouble(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF14263E);
    canvas.drawCircle(center, radius - 3, base);
    canvas.drawCircle(center, radius * .72, base);
    canvas.drawCircle(center, radius * .59, base);

    void arc(double start, double sweep, Color color, double r) {
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sweep,
        false,
        line,
      );
    }

    arc(
      math.pi * .72,
      math.pi * .54,
      ReactColors.electricBlueBright,
      radius * .83,
    );
    arc(math.pi * 1.54, math.pi * .43, ReactColors.lime, radius * .76);
    arc(
      math.pi * .08,
      math.pi * .42,
      const Color(0xFFFF6D8B),
      radius * .87,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 52 : 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF24AFFF), Color(0xFF0D78F6)],
          ),
          border: Border.all(color: const Color(0xFF74E8FF), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 27),
            const SizedBox(width: 12),
            Text(
              'PLAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 24 : 27,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNavGrid extends StatelessWidget {
  const _HomeNavGrid({
    required this.compact,
    required this.stats,
    required this.open,
  });

  final bool compact;
  final _HomeStats stats;
  final ValueChanged<Widget> open;

  @override
  Widget build(BuildContext context) {
    final items = <_HomeNavItem>[
      const _HomeNavItem(
        icon: Icons.view_in_ar_rounded,
        label: 'MODES',
        color: Color(0xFF27D8F6),
        screen: ModesScreen(),
      ),
      _HomeNavItem(
        icon: Icons.calendar_month_rounded,
        label: 'DAILY',
        color: ReactColors.lime,
        screen: const DailyScreen(),
        status: stats.dailyPlayedToday ? 'AGAIN' : 'READY',
        statusColor: stats.dailyPlayedToday
            ? ReactColors.lime
            : ReactColors.electricBlueBright,
      ),
      const _HomeNavItem(
        icon: Icons.leaderboard_rounded,
        label: 'LEADERBOARD',
        color: ReactColors.purple,
        screen: LeaderboardScreen(),
      ),
      const _HomeNavItem(
        icon: Icons.bolt_rounded,
        label: 'PASS',
        color: ReactColors.electricBlueBright,
        screen: SeasonScreen(),
      ),
      const _HomeNavItem(
        icon: Icons.inventory_2_outlined,
        label: 'LOCKER',
        color: Color(0xFFFFB85A),
        screen: SeasonLockerScreen(),
      ),
      const _HomeNavItem(
        icon: Icons.group_outlined,
        label: 'FRIENDS',
        color: ReactColors.lime,
        screen: FriendsScreen(),
      ),
      const _HomeNavItem(
        icon: Icons.school_outlined,
        label: 'HOW TO PLAY',
        color: ReactColors.electricBlueBright,
        screen: HowToPlayScreen(),
      ),
      const _HomeNavItem(
        icon: Icons.settings_outlined,
        label: 'SETTINGS',
        color: ReactColors.textSecondary,
        screen: SettingsScreen(),
      ),
    ];

    final height = compact ? 61.0 : 68.0;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              Expanded(
                child: _NavTile(
                  item: items[i],
                  height: height,
                  onTap: () => open(items[i].screen),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 4; i < 8; i++) ...[
              if (i > 4) const SizedBox(width: 7),
              Expanded(
                child: _NavTile(
                  item: items[i],
                  height: height,
                  onTap: () => open(items[i].screen),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HomeNavItem {
  const _HomeNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.screen,
    this.status,
    this.statusColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Widget screen;
  final String? status;
  final Color? statusColor;
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.height,
    required this.onTap,
  });

  final _HomeNavItem item;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xCC07111D),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF2A3A52)),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: item.color, size: 21),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 8.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item.status != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050A13),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: (item.statusColor ?? item.color).withValues(alpha: .55),
                    ),
                  ),
                  child: Text(
                    item.status!,
                    style: TextStyle(
                      color: item.statusColor ?? item.color,
                      fontSize: 5.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .25,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
