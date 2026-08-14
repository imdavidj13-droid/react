import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  late Future<_MilestoneData> _data;

  @override
  void initState() {
    super.initState();
    _data = _MilestoneData.load();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad = MediaQuery.sizeOf(context).width < 360 ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<_MilestoneData>(
          future: _data,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const _MilestoneData();
            final milestones = data.milestones;
            final unlocked = milestones.where((item) => item.unlocked).length;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                14,
                horizontalPad,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 22),
                  _Hero(unlocked: unlocked, total: milestones.length),
                  const SizedBox(height: 18),
                  const _SectionLabel('REACTION'),
                  const SizedBox(height: 10),
                  for (final item in milestones.where(
                    (item) => item.group == _MilestoneGroup.reaction,
                  )) ...[
                    _MilestoneCard(item: item),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  const _SectionLabel('MODE RECORDS'),
                  const SizedBox(height: 10),
                  for (final item in milestones.where(
                    (item) => item.group == _MilestoneGroup.modes,
                  )) ...[
                    _MilestoneCard(item: item),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  const _SectionLabel('CONSISTENCY'),
                  const SizedBox(height: 10),
                  for (final item in milestones.where(
                    (item) => item.group == _MilestoneGroup.consistency,
                  )) ...[
                    _MilestoneCard(item: item),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MilestoneData {
  const _MilestoneData({
    this.totalCommands = 0,
    this.classicBest = 0,
    this.blitzBest = 0,
    this.endlessBest = 0,
    this.dailyBest = 0,
    this.dailyStreak = 0,
    this.passItRuns = 0,
    this.bestStreak = 0,
  });

  final int totalCommands;
  final int classicBest;
  final int blitzBest;
  final int endlessBest;
  final int dailyBest;
  final int dailyStreak;
  final int passItRuns;
  final int bestStreak;

  static Future<_MilestoneData> load() async {
    final values = await Future.wait<int>([
      LocalPlayerStats.totalSuccessfulCommands(),
      LocalPlayerStats.bestFor(ReactGameMode.classic),
      LocalPlayerStats.bestFor(ReactGameMode.blitz),
      LocalPlayerStats.bestFor(ReactGameMode.endless),
      LocalPlayerStats.bestFor(ReactGameMode.daily),
      LocalPlayerStats.dailyStreak(),
      LocalPlayerStats.runsFor(ReactGameMode.passIt),
      LocalPlayerStats.bestCommandStreak(),
    ]);

    return _MilestoneData(
      totalCommands: values[0],
      classicBest: values[1],
      blitzBest: values[2],
      endlessBest: values[3],
      dailyBest: values[4],
      dailyStreak: values[5],
      passItRuns: values[6],
      bestStreak: values[7],
    );
  }

  List<_Milestone> get milestones => [
    _Milestone(
      group: _MilestoneGroup.reaction,
      title: 'REACTION READY',
      description: 'Clear 10 commands across any modes.',
      icon: Icons.bolt_rounded,
      color: ReactColors.electricBlueBright,
      current: totalCommands,
      target: 10,
    ),
    _Milestone(
      group: _MilestoneGroup.reaction,
      title: 'CENTURY',
      description: 'Clear 100 commands across the game.',
      icon: Icons.electric_bolt_rounded,
      color: ReactColors.lime,
      current: totalCommands,
      target: 100,
    ),
    _Milestone(
      group: _MilestoneGroup.reaction,
      title: 'WIRED IN',
      description: 'Clear 500 commands across the game.',
      icon: Icons.memory_rounded,
      color: ReactColors.purple,
      current: totalCommands,
      target: 500,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'CLASSIC 25',
      description: 'Reach 25 in Classic.',
      icon: Icons.change_history_rounded,
      color: ReactColors.electricBlueBright,
      current: classicBest,
      target: 25,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'CLASSIC 50',
      description: 'Reach 50 in Classic.',
      icon: Icons.workspace_premium_outlined,
      color: ReactColors.electricBlueBright,
      current: classicBest,
      target: 50,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'BLITZ 15',
      description: 'Clear 15 commands in a Blitz run.',
      icon: Icons.timer_rounded,
      color: ReactColors.coral,
      current: blitzBest,
      target: 15,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'BLITZ 30',
      description: 'Clear 30 commands in a Blitz run.',
      icon: Icons.speed_rounded,
      color: ReactColors.coral,
      current: blitzBest,
      target: 30,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'ENDLESS 25',
      description: 'Survive 25 commands in Endless.',
      icon: Icons.all_inclusive_rounded,
      color: ReactColors.lime,
      current: endlessBest,
      target: 25,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'ENDLESS 50',
      description: 'Survive 50 commands in Endless.',
      icon: Icons.local_fire_department_rounded,
      color: ReactColors.lime,
      current: endlessBest,
      target: 50,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'DAILY 30',
      description: 'Reach 30 in any Daily challenge.',
      icon: Icons.calendar_month_rounded,
      color: ReactColors.purple,
      current: dailyBest,
      target: 30,
    ),
    _Milestone(
      group: _MilestoneGroup.modes,
      title: 'DAILY COMPLETE',
      description: 'Clear all 60 commands in a Daily challenge.',
      icon: Icons.emoji_events_rounded,
      color: ReactColors.purple,
      current: dailyBest,
      target: 60,
    ),
    _Milestone(
      group: _MilestoneGroup.consistency,
      title: 'STREAK 25',
      description: 'Clear 25 commands in a row without a miss.',
      icon: Icons.local_fire_department_rounded,
      color: ReactColors.lime,
      current: bestStreak,
      target: 25,
    ),
    _Milestone(
      group: _MilestoneGroup.consistency,
      title: 'THREE DAY RUN',
      description: 'Play the Daily challenge 3 days in a row.',
      icon: Icons.local_fire_department_rounded,
      color: ReactColors.coral,
      current: dailyStreak,
      target: 3,
    ),
    _Milestone(
      group: _MilestoneGroup.consistency,
      title: 'SEVEN DAY RUN',
      description: 'Play the Daily challenge 7 days in a row.',
      icon: Icons.calendar_view_week_rounded,
      color: ReactColors.coral,
      current: dailyStreak,
      target: 7,
    ),
    _Milestone(
      group: _MilestoneGroup.consistency,
      title: 'PASS IT REGULAR',
      description: 'Finish 3 Pass It matches on this device.',
      icon: Icons.groups_2_rounded,
      color: ReactColors.purple,
      current: passItRuns,
      target: 3,
    ),
    _Milestone(
      group: _MilestoneGroup.consistency,
      title: 'PASS IT VETERAN',
      description: 'Finish 10 Pass It matches on this device.',
      icon: Icons.groups_3_rounded,
      color: ReactColors.purple,
      current: passItRuns,
      target: 10,
    ),
  ];
}

enum _MilestoneGroup { reaction, modes, consistency }

class _Milestone {
  const _Milestone({
    required this.group,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
  });

  final _MilestoneGroup group;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int current;
  final int target;

  bool get unlocked => current >= target;
  int get displayCurrent => current.clamp(0, target).toInt();
  double get progress => (current / target).clamp(0.0, 1.0).toDouble();
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onBack,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF07101E),
          foregroundColor: ReactColors.textPrimary,
          side: const BorderSide(color: Color(0xFF1E3552)),
        ),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
      const SizedBox(width: 8),
      const Expanded(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'MILESTONES',
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 48),
    ],
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: ReactColors.lime.withValues(alpha: .42)),
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ReactColors.lime.withValues(alpha: .08),
            border: Border.all(color: ReactColors.lime.withValues(alpha: .55)),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: ReactColors.lime,
            size: 29,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$unlocked / $total UNLOCKED',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Milestones are calculated from your local records. No XP, levels or currency.',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 9,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: Color(0xFF263851))),
    ],
  );
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.item});

  final _Milestone item;

  @override
  Widget build(BuildContext context) {
    final unlocked = item.unlocked;
    final color = unlocked ? item.color : ReactColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? item.color.withValues(alpha: .48)
              : const Color(0xFF24364E),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? item.color.withValues(alpha: .08)
                  : const Color(0xFF090F1B),
              border: Border.all(
                color: unlocked
                    ? item.color.withValues(alpha: .55)
                    : const Color(0xFF2A3B51),
              ),
            ),
            child: Icon(
              unlocked ? item.icon : Icons.lock_outline_rounded,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: unlocked
                        ? ReactColors.textPrimary
                        : ReactColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unlocked
                      ? 'UNLOCKED'
                      : '${item.displayCurrent}/${item.target}',
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: item.progress,
                    backgroundColor: const Color(0xFF101C2B),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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
