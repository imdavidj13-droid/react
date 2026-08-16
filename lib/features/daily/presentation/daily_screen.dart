import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';
import '../domain/daily_challenge.dart';
import '../domain/daily_history_entry.dart';
import 'daily_dev_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> with WidgetsBindingObserver {
  late Future<_DailyState> _state;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshForCurrentDay();
  }

  void _reload() => _state = _DailyState.load();

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextReset = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextReset.difference(now) + const Duration(milliseconds: 100),
      _refreshForCurrentDay,
    );
  }

  void _refreshForCurrentDay() {
    if (!mounted) return;
    setState(_reload);
    _scheduleMidnightRefresh();
  }

  Future<void> _start() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReactRunLaunchScreen(mode: ReactGameMode.daily),
      ),
    );
    if (mounted) _refreshForCurrentDay();
  }

  Future<void> _openDevTester() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DailyDevScreen()),
    );
    if (mounted) _refreshForCurrentDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<_DailyState>(
          future: _state,
          builder: (context, snapshot) {
            final state = snapshot.data ?? _DailyState.empty();
            return LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 360;
                final pad = narrow ? 12.0 : 20.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
                  child: Column(
                    children: [
                      _Header(onBack: () => Navigator.of(context).pop()),
                      SizedBox(height: narrow ? 16 : 20),
                      Text(
                        'DAILY RUN',
                        style: TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: narrow ? 30 : 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'ONE CHALLENGE • ONE RULE • UNLIMITED ATTEMPTS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ReactColors.electricBlueBright,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.05,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Identity(challenge: state.challenge),
                      const SizedBox(height: 10),
                      _ModifierCard(
                        modifier: state.challenge.modifier,
                        compact: narrow,
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 10),
                        _DevTesterCard(onTap: _openDevTester),
                      ],
                      const SizedBox(height: 10),
                      _RunCard(state: state, narrow: narrow, onTap: _start),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'CURRENT STREAK',
                              value: '${state.streak} DAYS',
                              icon: Icons.local_fire_department_rounded,
                              color: ReactColors.coral,
                              compact: narrow,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              label: 'RULE BEST',
                              value: '${state.ruleBest}',
                              icon: Icons.workspace_premium_outlined,
                              color: ReactColors.lime,
                              compact: narrow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _WeekHistory(entries: state.history),
                      const SizedBox(height: 12),
                      _InfoCard(state: state),
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

class _DailyState {
  const _DailyState({
    required this.challenge,
    this.playedToday = false,
    this.streak = 0,
    this.best = 0,
    this.ruleBest = 0,
    this.history = const <DailyHistoryEntry>[],
  });

  final DailyChallenge challenge;
  final bool playedToday;
  final int streak;
  final int best;
  final int ruleBest;
  final List<DailyHistoryEntry> history;

  factory _DailyState.empty() => _DailyState(challenge: DailyChallenge.today());

  static Future<_DailyState> load() async {
    final challenge = DailyChallenge.today();
    return _DailyState(
      challenge: challenge,
      playedToday: await LocalPlayerStats.hasPlayedDailyToday(),
      streak: await LocalPlayerStats.dailyStreak(),
      best: await LocalPlayerStats.dailyBestToday(),
      ruleBest: await LocalPlayerStats.dailyBestForModifier(challenge.modifier),
      history: await LocalPlayerStats.dailyHistoryThisWeek(),
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
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
            side: const BorderSide(color: Color(0xFF1E3552)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Spacer(),
        const Text(
          'RE△CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 28,
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

class _Identity extends StatelessWidget {
  const _Identity({required this.challenge});
  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          const Icon(
            Icons.fingerprint_rounded,
            color: ReactColors.electricBlueBright,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHALLENGE #${challenge.id}',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  challenge.dateLabel,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'SAME RUN ALL DAY',
            style: TextStyle(
              color: ReactColors.lime,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifierCard extends StatelessWidget {
  const _ModifierCard({required this.modifier, required this.compact});
  final DailyModifier modifier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _modifierColor(modifier);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF08121F),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(_modifierIcon(modifier), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S RULE",
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  modifier.label,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  modifier.description,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
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
}

class _DevTesterCard extends StatelessWidget {
  const _DevTesterCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1322),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ReactColors.purple.withValues(alpha: .70)),
        ),
        child: const Row(
          children: [
            Icon(Icons.science_rounded, color: ReactColors.purple, size: 22),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEV MODIFIER TESTER',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'CHOOSE AND TEST ANY OF THE 7 DAILY RULES',
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ReactColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.state,
    required this.narrow,
    required this.onTap,
  });

  final _DailyState state;
  final bool narrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = state.playedToday ? 'PLAY AGAIN' : 'READY';
    return _Panel(
      padding: EdgeInsets.all(narrow ? 14 : 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TODAY'S RUN",
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      status,
                      style: TextStyle(
                        color: state.playedToday
                            ? ReactColors.lime
                            : ReactColors.electricBlueBright,
                        fontSize: narrow ? 24 : 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SURVIVE UNTIL YOU MISS • BEST SCORE COUNTS',
                      style: TextStyle(
                        color: ReactColors.lime,
                        fontSize: 7.4,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: narrow ? 68 : 88,
                height: narrow ? 68 : 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ReactColors.electricBlueBright,
                    width: 2,
                  ),
                ),
                child: Icon(
                  state.playedToday
                      ? Icons.replay_rounded
                      : Icons.all_inclusive_rounded,
                  color: ReactColors.electricBlueBright,
                  size: narrow ? 32 : 40,
                ),
              ),
            ],
          ),
          SizedBox(height: narrow ? 12 : 16),
          const Divider(color: Color(0xFF233850)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'TODAY BEST',
                  value: '${state.best}',
                  color: ReactColors.lime,
                ),
              ),
              const _Divider(),
              const Expanded(
                child: _Metric(
                  label: 'FORMAT',
                  value: 'ENDLESS',
                  color: ReactColors.purple,
                ),
              ),
              const _Divider(),
              const Expanded(
                child: _Metric(
                  label: 'MISS LIMIT',
                  value: '1',
                  color: ReactColors.coral,
                ),
              ),
            ],
          ),
          SizedBox(height: narrow ? 14 : 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF168CFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(29),
                ),
              ),
              icon: Icon(
                state.playedToday ? Icons.replay_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                state.playedToday ? 'PLAY AGAIN' : 'PLAY DAILY',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHistory extends StatelessWidget {
  const _WeekHistory({required this.entries});
  final List<DailyHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS WEEK',
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 9),
          if (entries.isEmpty)
            const SizedBox(height: 42)
          else
            Row(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  if (index > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _HistoryDay(
                      entry: entries[index],
                      today: entries[index].date == today,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HistoryDay extends StatelessWidget {
  const _HistoryDay({required this.entry, required this.today});
  final DailyHistoryEntry entry;
  final bool today;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final future = entry.date.isAfter(DateTime.now());
    final color = _modifierColor(entry.modifier);
    final score = future ? '—' : entry.score?.toString() ?? '—';
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: today ? const Color(0xFF0B1929) : const Color(0xFF08101B),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: today ? ReactColors.electricBlueBright : color.withValues(alpha: .3),
        ),
      ),
      child: Column(
        children: [
          Text(
            _days[entry.date.weekday - 1],
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Icon(_modifierIcon(entry.modifier), color: color, size: 15),
          const Spacer(),
          Text(
            score,
            style: TextStyle(
              color: entry.failed ? ReactColors.coral : ReactColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.state});
  final _DailyState state;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          const Icon(
            Icons.replay_circle_filled_rounded,
            color: ReactColors.electricBlueBright,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${state.challenge.modifier.label} and challenge #${state.challenge.id} stay fixed until local midnight. Play as many times as you want; your best score counts. There is no command cap. One miss ends each attempt.',
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0xFF233850));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 96 : 104,
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: compact ? 20 : 22),
          const Spacer(),
          FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF293B54)),
      ),
      child: child,
    );
  }
}

IconData _modifierIcon(DailyModifier modifier) => switch (modifier) {
      DailyModifier.lightsOut => Icons.visibility_off_rounded,
      DailyModifier.surge => Icons.bolt_rounded,
      DailyModifier.noClock => Icons.timer_off_rounded,
      DailyModifier.echo => Icons.repeat_rounded,
      DailyModifier.reverse => Icons.swap_horiz_rounded,
      DailyModifier.chain => Icons.link_rounded,
      DailyModifier.redline => Icons.speed_rounded,
    };

Color _modifierColor(DailyModifier modifier) => switch (modifier) {
      DailyModifier.lightsOut => ReactColors.purple,
      DailyModifier.surge => ReactColors.coral,
      DailyModifier.noClock => ReactColors.lime,
      DailyModifier.echo => ReactColors.electricBlueBright,
      DailyModifier.reverse => ReactColors.purple,
      DailyModifier.chain => ReactColors.lime,
      DailyModifier.redline => ReactColors.coral,
    };
