import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';
import '../domain/daily_challenge.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late Future<_DailyState> _state;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _state = _DailyState.load();

  Future<void> _start() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReactRunLaunchScreen(mode: ReactGameMode.daily),
      ),
    );
    if (!mounted) return;
    setState(_reload);
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
                        'ONE CHALLENGE • ONE RULE • ONE ATTEMPT',
                        style: TextStyle(
                          color: ReactColors.electricBlueBright,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Identity(challenge: state.challenge),
                      const SizedBox(height: 10),
                      _ModifierCard(
                        modifier: state.challenge.modifier,
                        compact: narrow,
                      ),
                      const SizedBox(height: 10),
                      _RunCard(
                        state: state,
                        narrow: narrow,
                        onTap: state.playedToday ? null : _start,
                      ),
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
                              label: 'DAILY BEST',
                              value: '${state.best}',
                              icon: Icons.workspace_premium_outlined,
                              color: ReactColors.lime,
                              compact: narrow,
                            ),
                          ),
                        ],
                      ),
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
  });

  final DailyChallenge challenge;
  final bool playedToday;
  final int streak;
  final int best;

  factory _DailyState.empty() => _DailyState(challenge: DailyChallenge.today());

  static Future<_DailyState> load() async {
    final challenge = DailyChallenge.today();
    final values = await Future.wait<Object>([
      LocalPlayerStats.hasPlayedDailyToday(),
      LocalPlayerStats.dailyStreak(),
      LocalPlayerStats.bestFor(ReactGameMode.daily),
    ]);
    return _DailyState(
      challenge: challenge,
      playedToday: values[0] as bool,
      streak: values[1] as int,
      best: values[2] as int,
    );
  }
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

class _Identity extends StatelessWidget {
  const _Identity({required this.challenge});
  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF24405E)),
        ),
        child: Row(
          children: [
            const Icon(Icons.fingerprint_rounded,
                color: ReactColors.electricBlueBright, size: 22),
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
              'FIXED SEED',
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

class _ModifierCard extends StatelessWidget {
  const _ModifierCard({required this.modifier, required this.compact});
  final DailyModifier modifier;
  final bool compact;

  IconData get icon => switch (modifier) {
        DailyModifier.lightsOut => Icons.visibility_off_rounded,
        DailyModifier.surge => Icons.bolt_rounded,
        DailyModifier.noClock => Icons.timer_off_rounded,
        DailyModifier.echo => Icons.repeat_rounded,
        DailyModifier.reverse => Icons.swap_horiz_rounded,
        DailyModifier.chain => Icons.link_rounded,
        DailyModifier.redline => Icons.speed_rounded,
      };

  Color get color => switch (modifier) {
        DailyModifier.lightsOut => ReactColors.purple,
        DailyModifier.surge => ReactColors.coral,
        DailyModifier.noClock => ReactColors.lime,
        DailyModifier.echo => ReactColors.electricBlueBright,
        DailyModifier.reverse => ReactColors.purple,
        DailyModifier.chain => ReactColors.lime,
        DailyModifier.redline => ReactColors.coral,
      };

  @override
  Widget build(BuildContext context) => Container(
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
              child: Icon(icon, color: color, size: compact ? 22 : 25),
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

class _RunCard extends StatelessWidget {
  const _RunCard({required this.state, required this.narrow, required this.onTap});
  final _DailyState state;
  final bool narrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = state.playedToday ? 'COMPLETED' : 'READY';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A506E)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TODAY'S RUN",
                        style: TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        )),
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
                    Text(
                      state.challenge.modifier.shortRule,
                      style: const TextStyle(
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
              const SizedBox(width: 10),
              Container(
                width: narrow ? 68 : 88,
                height: narrow ? 68 : 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ReactColors.electricBlueBright, width: 2),
                ),
                child: Icon(
                  state.playedToday ? Icons.check_rounded : Icons.wb_sunny_outlined,
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
              Expanded(child: _Metric(label: 'YOUR BEST', value: '${state.best}', color: ReactColors.lime)),
              const _Divider(),
              const Expanded(child: _Metric(label: 'TARGET', value: '60', color: ReactColors.purple)),
              const _Divider(),
              const Expanded(child: _Metric(label: 'MISSES', value: '0', color: ReactColors.coral)),
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
                disabledBackgroundColor: const Color(0xFF18314B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
              ),
              icon: Icon(state.playedToday ? Icons.check_rounded : Icons.play_arrow_rounded),
              label: Text(
                state.playedToday ? 'PLAYED TODAY' : 'PLAY DAILY',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.3),
              ),
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
    final text = state.playedToday
        ? 'Challenge #${state.challenge.id} is locked. A new sequence and rule unlock at local midnight.'
        : '${state.challenge.modifier.label} and challenge #${state.challenge.id} stay fixed for today. One miss ends the attempt.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF293B54)),
      ),
      child: Row(
        children: [
          Icon(state.playedToday ? Icons.schedule_rounded : Icons.lock_clock_rounded,
              color: state.playedToday ? ReactColors.lime : ReactColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
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
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 34, color: const Color(0xFF233850));
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
  Widget build(BuildContext context) => Container(
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
            FittedBox(child: Text(label,
                style: const TextStyle(color: ReactColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w900))),
            const SizedBox(height: 3),
            FittedBox(child: Text(value,
                style: TextStyle(color: color, fontSize: compact ? 16 : 18, fontWeight: FontWeight.w900))),
          ],
        ),
      );
}
