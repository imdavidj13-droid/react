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
  _MilestoneCategory _selected = _MilestoneCategory.general;

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
            final all = data.milestones;
            final unlocked = all.where((item) => item.unlocked).length;
            final visible = all
                .where((item) => item.category == _selected)
                .toList(growable: false);
            final sectionUnlocked = visible.where((item) => item.unlocked).length;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                14,
                horizontalPad,
                28,
              ),
              children: [
                _Header(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 18),
                _Hero(unlocked: unlocked, total: all.length),
                const SizedBox(height: 14),
                _CategoryStrip(
                  selected: _selected,
                  milestones: all,
                  onSelected: (category) {
                    setState(() => _selected = category);
                  },
                ),
                const SizedBox(height: 18),
                _SectionHeading(
                  category: _selected,
                  unlocked: sectionUnlocked,
                  total: visible.length,
                ),
                const SizedBox(height: 10),
                for (final item in visible) ...[
                  _MilestoneCard(item: item),
                  const SizedBox(height: 10),
                ],
              ],
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
    this.totalRuns = 0,
    this.bestStreak = 0,
    this.classicBest = 0,
    this.classicRuns = 0,
    this.classicClears = 0,
    this.blitzBest = 0,
    this.blitzRuns = 0,
    this.blitzClears = 0,
    this.endlessBest = 0,
    this.endlessRuns = 0,
    this.endlessClears = 0,
    this.sequenceBest = 0,
    this.sequenceRuns = 0,
    this.sequenceClears = 0,
    this.bestSequenceStreak = 0,
    this.dailyBest = 0,
    this.dailyRuns = 0,
    this.dailyClears = 0,
    this.dailyStreak = 0,
    this.passItRuns = 0,
    this.passItClears = 0,
  });

  final int totalCommands;
  final int totalRuns;
  final int bestStreak;
  final int classicBest;
  final int classicRuns;
  final int classicClears;
  final int blitzBest;
  final int blitzRuns;
  final int blitzClears;
  final int endlessBest;
  final int endlessRuns;
  final int endlessClears;
  final int sequenceBest;
  final int sequenceRuns;
  final int sequenceClears;
  final int bestSequenceStreak;
  final int dailyBest;
  final int dailyRuns;
  final int dailyClears;
  final int dailyStreak;
  final int passItRuns;
  final int passItClears;

  static Future<_MilestoneData> load() async {
    final values = await Future.wait<int>([
      LocalPlayerStats.totalSuccessfulCommands(),
      LocalPlayerStats.runsPlayed(),
      LocalPlayerStats.bestCommandStreak(),
      LocalPlayerStats.bestFor(ReactGameMode.classic),
      LocalPlayerStats.runsFor(ReactGameMode.classic),
      LocalPlayerStats.successfulCommandsFor(ReactGameMode.classic),
      LocalPlayerStats.bestFor(ReactGameMode.blitz),
      LocalPlayerStats.runsFor(ReactGameMode.blitz),
      LocalPlayerStats.successfulCommandsFor(ReactGameMode.blitz),
      LocalPlayerStats.bestFor(ReactGameMode.endless),
      LocalPlayerStats.runsFor(ReactGameMode.endless),
      LocalPlayerStats.successfulCommandsFor(ReactGameMode.endless),
      LocalPlayerStats.bestFor(ReactGameMode.sequence),
      LocalPlayerStats.runsFor(ReactGameMode.sequence),
      LocalPlayerStats.sequenceClears(),
      LocalPlayerStats.bestSequenceStreak(),
      LocalPlayerStats.bestFor(ReactGameMode.daily),
      LocalPlayerStats.runsFor(ReactGameMode.daily),
      LocalPlayerStats.successfulCommandsFor(ReactGameMode.daily),
      LocalPlayerStats.dailyStreak(),
      LocalPlayerStats.runsFor(ReactGameMode.passIt),
      LocalPlayerStats.successfulCommandsFor(ReactGameMode.passIt),
    ]);

    return _MilestoneData(
      totalCommands: values[0],
      totalRuns: values[1],
      bestStreak: values[2],
      classicBest: values[3],
      classicRuns: values[4],
      classicClears: values[5],
      blitzBest: values[6],
      blitzRuns: values[7],
      blitzClears: values[8],
      endlessBest: values[9],
      endlessRuns: values[10],
      endlessClears: values[11],
      sequenceBest: values[12],
      sequenceRuns: values[13],
      sequenceClears: values[14],
      bestSequenceStreak: values[15],
      dailyBest: values[16],
      dailyRuns: values[17],
      dailyClears: values[18],
      dailyStreak: values[19],
      passItRuns: values[20],
      passItClears: values[21],
    );
  }

  List<_Milestone> get milestones => [
    ..._generalMilestones,
    ..._classicMilestones,
    ..._blitzMilestones,
    ..._endlessMilestones,
    ..._sequenceMilestones,
    ..._dailyMilestones,
    ..._passItMilestones,
  ];

  List<_Milestone> get _generalMilestones => [
    _m(_MilestoneCategory.general, 'FIRST CONTACT', 'Clear 10 gesture commands.', Icons.bolt_rounded, ReactColors.electricBlueBright, totalCommands, 10),
    _m(_MilestoneCategory.general, 'WARMED UP', 'Clear 50 gesture commands.', Icons.flash_on_rounded, ReactColors.electricBlueBright, totalCommands, 50),
    _m(_MilestoneCategory.general, 'CENTURY', 'Clear 100 gesture commands.', Icons.electric_bolt_rounded, ReactColors.lime, totalCommands, 100),
    _m(_MilestoneCategory.general, 'QUARTER K', 'Clear 250 gesture commands.', Icons.speed_rounded, ReactColors.lime, totalCommands, 250),
    _m(_MilestoneCategory.general, 'WIRED IN', 'Clear 500 gesture commands.', Icons.memory_rounded, ReactColors.purple, totalCommands, 500),
    _m(_MilestoneCategory.general, 'FOUR DIGITS', 'Clear 1,000 gesture commands.', Icons.functions_rounded, ReactColors.purple, totalCommands, 1000),
    _m(_MilestoneCategory.general, 'REFLEX ENGINE', 'Clear 2,500 gesture commands.', Icons.settings_input_component_rounded, ReactColors.coral, totalCommands, 2500),
    _m(_MilestoneCategory.general, 'FIVE THOUSAND', 'Clear 5,000 gesture commands.', Icons.whatshot_rounded, ReactColors.coral, totalCommands, 5000),
    _m(_MilestoneCategory.general, 'FIRST RUN', 'Finish your first run.', Icons.play_arrow_rounded, ReactColors.electricBlueBright, totalRuns, 1),
    _m(_MilestoneCategory.general, 'TEN RUNS DEEP', 'Finish 10 runs.', Icons.repeat_rounded, ReactColors.electricBlueBright, totalRuns, 10),
    _m(_MilestoneCategory.general, 'REGULAR', 'Finish 25 runs.', Icons.loop_rounded, ReactColors.lime, totalRuns, 25),
    _m(_MilestoneCategory.general, 'FIFTY RUN CLUB', 'Finish 50 runs.', Icons.workspace_premium_outlined, ReactColors.lime, totalRuns, 50),
    _m(_MilestoneCategory.general, 'TRIPLE DIGITS', 'Finish 100 runs.', Icons.emoji_events_outlined, ReactColors.purple, totalRuns, 100),
    _m(_MilestoneCategory.general, 'RELENTLESS', 'Finish 250 runs.', Icons.local_fire_department_rounded, ReactColors.coral, totalRuns, 250),
    _m(_MilestoneCategory.general, 'LOCKED IN', 'Clear 25 gesture commands in a row.', Icons.link_rounded, ReactColors.lime, bestStreak, 25),
    _m(_MilestoneCategory.general, 'UNBROKEN 50', 'Clear 50 gesture commands in a row.', Icons.all_inclusive_rounded, ReactColors.coral, bestStreak, 50),
  ];

  List<_Milestone> get _classicMilestones => _scoreModeMilestones(
    category: _MilestoneCategory.classic,
    color: ReactColors.electricBlueBright,
    icon: Icons.bolt_rounded,
    best: classicBest,
    runs: classicRuns,
    clears: classicClears,
    scoreTargets: const [10, 25, 50, 75, 100, 150, 250],
    scoreNames: const ['CLASSIC 10', 'CLASSIC 25', 'CLASSIC 50', 'CLASSIC 75', 'CLASSIC 100', 'CLASSIC 150', 'CLASSIC 250'],
  );

  List<_Milestone> get _blitzMilestones => _scoreModeMilestones(
    category: _MilestoneCategory.blitz,
    color: ReactColors.coral,
    icon: Icons.timer_rounded,
    best: blitzBest,
    runs: blitzRuns,
    clears: blitzClears,
    scoreTargets: const [10, 15, 20, 25, 30, 40, 50],
    scoreNames: const ['BLITZ 10', 'BLITZ 15', 'BLITZ 20', 'BLITZ 25', 'BLITZ 30', 'BLITZ 40', 'BLITZ 50'],
  );

  List<_Milestone> get _endlessMilestones => _scoreModeMilestones(
    category: _MilestoneCategory.endless,
    color: ReactColors.lime,
    icon: Icons.all_inclusive_rounded,
    best: endlessBest,
    runs: endlessRuns,
    clears: endlessClears,
    scoreTargets: const [5, 10, 25, 50, 75, 100, 150],
    scoreNames: const ['ENDLESS 5', 'ENDLESS 10', 'ENDLESS 25', 'ENDLESS 50', 'ENDLESS 75', 'ENDLESS 100', 'ENDLESS 150'],
  );

  List<_Milestone> get _sequenceMilestones => [
    for (final entry in const [(5, 'SEQUENCE 5'), (10, 'SEQUENCE 10'), (15, 'SEQUENCE 15'), (25, 'SEQUENCE 25'), (40, 'SEQUENCE 40'), (60, 'SEQUENCE 60'), (100, 'SEQUENCE 100')])
      _m(_MilestoneCategory.sequence, entry.$2, 'Clear ${entry.$1} numbered sequences in one run.', Icons.blur_circular_rounded, ReactColors.electricBlueBright, sequenceBest, entry.$1),
    for (final target in const [5, 25, 50, 100])
      _m(_MilestoneCategory.sequence, 'SEQUENCE RUNS $target', 'Finish $target Sequence runs.', Icons.repeat_rounded, ReactColors.electricBlueBright, sequenceRuns, target),
    _m(_MilestoneCategory.sequence, '100 SEQUENCES', 'Clear 100 numbered sequences in total.', Icons.filter_5_rounded, ReactColors.electricBlueBright, sequenceClears, 100),
    _m(_MilestoneCategory.sequence, '500 SEQUENCES', 'Clear 500 numbered sequences in total.', Icons.grid_view_rounded, ReactColors.purple, sequenceClears, 500),
    _m(_MilestoneCategory.sequence, 'PERFECT TEN', 'Clear 10 Sequence rounds in a row without losing a life.', Icons.blur_on_rounded, ReactColors.lime, bestSequenceStreak, 10),
  ];

  List<_Milestone> get _dailyMilestones => [
    for (final entry in const [(10, 'DAILY 10'), (20, 'DAILY 20'), (30, 'DAILY 30'), (60, 'DAILY 60'), (100, 'DAILY 100'), (150, 'DAILY 150')])
      _m(_MilestoneCategory.daily, entry.$2, 'Reach ${entry.$1} in a Daily challenge.', Icons.calendar_month_rounded, ReactColors.purple, dailyBest, entry.$1),
    for (final target in const [3, 7, 30, 100])
      _m(_MilestoneCategory.daily, 'DAILY RUNS $target', 'Finish $target Daily challenges.', Icons.today_rounded, ReactColors.purple, dailyRuns, target),
    _m(_MilestoneCategory.daily, '100 DAILY CLEARS', 'Clear 100 commands in Daily challenges.', Icons.bolt_rounded, ReactColors.lime, dailyClears, 100),
    _m(_MilestoneCategory.daily, '500 DAILY CLEARS', 'Clear 500 commands in Daily challenges.', Icons.flash_on_rounded, ReactColors.lime, dailyClears, 500),
    _m(_MilestoneCategory.daily, 'SEVEN DAY RUN', 'Play Daily 7 days in a row.', Icons.calendar_view_week_rounded, ReactColors.coral, dailyStreak, 7),
    _m(_MilestoneCategory.daily, 'THIRTY DAY RUN', 'Play Daily 30 days in a row.', Icons.local_fire_department_rounded, ReactColors.coral, dailyStreak, 30),
  ];

  List<_Milestone> get _passItMilestones => [
    for (final entry in const [(1, 'FIRST HANDOFF'), (3, 'PASS IT REGULAR'), (5, 'FIVE MATCHES'), (10, 'PASS IT VETERAN'), (25, 'PARTY 25'), (50, 'PARTY 50'), (100, 'CENTURY PARTY')])
      _m(_MilestoneCategory.passIt, entry.$2, 'Finish ${entry.$1} Pass It ${entry.$1 == 1 ? 'match' : 'matches'}.', Icons.groups_2_rounded, ReactColors.purple, passItRuns, entry.$1),
    for (final entry in const [(10, 'HANDOFF 10'), (50, 'HANDOFF 50'), (100, 'HANDOFF 100'), (250, 'HANDOFF 250'), (500, 'HANDOFF 500'), (1000, 'HANDOFF 1000'), (2500, 'HANDOFF 2500')])
      _m(_MilestoneCategory.passIt, entry.$2, 'Clear ${entry.$1} commands across Pass It matches.', Icons.compare_arrows_rounded, ReactColors.coral, passItClears, entry.$1),
  ];

  List<_Milestone> _scoreModeMilestones({
    required _MilestoneCategory category,
    required Color color,
    required IconData icon,
    required int best,
    required int runs,
    required int clears,
    required List<int> scoreTargets,
    required List<String> scoreNames,
  }) {
    return [
      for (var i = 0; i < scoreTargets.length; i++)
        _m(category, scoreNames[i], 'Reach ${scoreTargets[i]} in one ${category.label} run.', icon, color, best, scoreTargets[i]),
      for (final target in const [5, 25, 50, 100])
        _m(category, '${category.label} RUNS $target', 'Finish $target ${category.label} runs.', Icons.repeat_rounded, color, runs, target),
      _m(category, '100 TOTAL CLEARS', 'Clear 100 commands in ${category.label}.', Icons.bolt_rounded, color, clears, 100),
      _m(category, '500 TOTAL CLEARS', 'Clear 500 commands in ${category.label}.', Icons.flash_on_rounded, color, clears, 500),
      _m(category, '2000 TOTAL CLEARS', 'Clear 2,000 commands in ${category.label}.', Icons.whatshot_rounded, color, clears, 2000),
    ];
  }

  _Milestone _m(
    _MilestoneCategory category,
    String title,
    String description,
    IconData icon,
    Color color,
    int current,
    int target,
  ) {
    return _Milestone(
      category: category,
      title: title,
      description: description,
      icon: icon,
      color: color,
      current: current,
      target: target,
    );
  }
}

enum _MilestoneCategory {
  general('GENERAL', Icons.grid_view_rounded, ReactColors.textPrimary),
  classic('CLASSIC', Icons.bolt_rounded, ReactColors.electricBlueBright),
  blitz('BLITZ', Icons.timer_rounded, ReactColors.coral),
  endless('ENDLESS', Icons.all_inclusive_rounded, ReactColors.lime),
  sequence('SEQUENCE', Icons.blur_circular_rounded, ReactColors.electricBlueBright),
  daily('DAILY', Icons.calendar_month_rounded, ReactColors.purple),
  passIt('PASS IT', Icons.groups_2_rounded, ReactColors.purple);

  const _MilestoneCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _Milestone {
  const _Milestone({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
  });

  final _MilestoneCategory category;
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: ReactColors.lime.withValues(alpha: .42)),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ReactColors.lime.withValues(alpha: .08),
            border: Border.all(color: ReactColors.lime.withValues(alpha: .55)),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: ReactColors.lime,
            size: 28,
          ),
        ),
        const SizedBox(width: 13),
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
                '100 competitive targets built from your real local records.',
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

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.selected,
    required this.milestones,
    required this.onSelected,
  });

  final _MilestoneCategory selected;
  final List<_Milestone> milestones;
  final ValueChanged<_MilestoneCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in _MilestoneCategory.values) ...[
            _CategoryChip(
              category: category,
              selected: category == selected,
              unlocked: milestones
                  .where((item) => item.category == category && item.unlocked)
                  .length,
              total: milestones.where((item) => item.category == category).length,
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.unlocked,
    required this.total,
    required this.onTap,
  });

  final _MilestoneCategory category;
  final bool selected;
  final int unlocked;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .12) : const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color.withValues(alpha: .72) : const Color(0xFF24364E),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                color: selected ? ReactColors.textPrimary : ReactColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$unlocked/$total',
              style: TextStyle(
                color: color,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.category,
    required this.unlocked,
    required this.total,
  });

  final _MilestoneCategory category;
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(category.icon, color: category.color, size: 18),
      const SizedBox(width: 8),
      Text(
        category.label,
        style: const TextStyle(
          color: ReactColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
      const Spacer(),
      Text(
        '$unlocked / $total',
        style: TextStyle(
          color: category.color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .08),
              border: Border.all(color: color.withValues(alpha: .45)),
            ),
            child: Icon(item.icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unlocked ? 'UNLOCKED' : '${item.displayCurrent}/${item.target}',
                      style: TextStyle(
                        color: unlocked ? item.color : ReactColors.textSecondary,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: item.progress,
                    backgroundColor: const Color(0xFF14243A),
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
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
