import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_screen.dart';
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

  void _reload() {
    _state = _DailyState.load();
  }

  Future<void> _start() async {
    await LocalPlayerStats.markDailyAttemptStarted();
    if (!mounted) return;

    setState(_reload);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReactRunScreen(mode: ReactGameMode.daily),
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
                final pad = constraints.maxWidth < 380 ? 16.0 : 20.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
                  child: Column(
                    children: [
                      _Header(onBack: () => Navigator.of(context).pop()),
                      const SizedBox(height: 20),
                      const Text(
                        'DAILY RUN',
                        style: TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'ONE LOCAL CHALLENGE EVERY DAY',
                        style: TextStyle(
                          color: ReactColors.electricBlueBright,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ChallengeIdentity(challenge: state.challenge),
                      const SizedBox(height: 12),
                      _ChallengeCard(
                        state: state,
                        onTap: state.playedToday ? null : _start,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.local_fire_department_rounded,
                              label: 'CURRENT STREAK',
                              value: '${state.streak} DAYS',
                              color: ReactColors.coral,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.workspace_premium_outlined,
                              label: 'DAILY BEST',
                              value: '${state.best}',
                              color: ReactColors.lime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _LocalDailyInfo(
                        playedToday: state.playedToday,
                        challenge: state.challenge,
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

class _ChallengeIdentity extends StatelessWidget {
  const _ChallengeIdentity({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF24405E)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.fingerprint_rounded,
            color: ReactColors.electricBlueBright,
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHALLENGE #${challenge.id}',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  challenge.dateLabel,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'FIXED SEED',
            style: TextStyle(
              color: ReactColors.lime,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.state, required this.onTap});

  final _DailyState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                    const Text(
                      "TODAY'S RUN",
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.playedToday ? 'COMPLETED' : 'READY',
                      style: TextStyle(
                        color: state.playedToday
                            ? ReactColors.lime
                            : ReactColors.electricBlueBright,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '20 COMMANDS • SAME ORDER ALL DAY',
                      style: TextStyle(
                        color: ReactColors.lime,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ReactColors.electricBlueBright,
                    width: 2.2,
                  ),
                ),
                child: Icon(
                  state.playedToday
                      ? Icons.check_rounded
                      : Icons.wb_sunny_outlined,
                  color: ReactColors.electricBlueBright,
                  size: 42,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(color: Color(0xFF233850)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'YOUR BEST',
                  value: '${state.best}',
                  color: ReactColors.lime,
                ),
              ),
              const _Divider(),
              const Expanded(
                child: _Metric(
                  label: 'TARGET',
                  value: '20',
                  color: ReactColors.purple,
                ),
              ),
              const _Divider(),
              const Expanded(
                child: _Metric(
                  label: 'POINTS',
                  value: '1 / CMD',
                  color: ReactColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF168CFF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF18314B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(29),
                  side: const BorderSide(color: Color(0xFF5FE5FF)),
                ),
              ),
              icon: Icon(
                state.playedToday
                    ? Icons.check_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                state.playedToday ? 'PLAYED TODAY' : 'PLAY DAILY',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalDailyInfo extends StatelessWidget {
  const _LocalDailyInfo({
    required this.playedToday,
    required this.challenge,
  });

  final bool playedToday;
  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final title = playedToday ? 'NEXT CHALLENGE TOMORROW' : 'LOCAL DAILY MODE';
    final detail = playedToday
        ? 'A new challenge ID and command order unlock at local midnight.'
        : 'Your device date generates one fixed challenge and command order for the entire day.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF293B54)),
      ),
      child: Row(
        children: [
          Icon(
            playedToday ? Icons.schedule_rounded : Icons.today_rounded,
            color: playedToday ? ReactColors.lime : ReactColors.textSecondary,
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
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
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: const Color(0xFF233850),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
