import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<(ReactGameMode, int)>> _scores;

  @override
  void initState() {
    super.initState();
    _scores = _loadScores();
  }

  Future<List<(ReactGameMode, int)>> _loadScores() async {
    final modes = [
      ReactGameMode.classic,
      ReactGameMode.blitz,
      ReactGameMode.endless,
      ReactGameMode.daily,
    ];
    final values = await Future.wait(modes.map(LocalPlayerStats.bestFor));
    return [for (var i = 0; i < modes.length; i++) (modes[i], values[i])];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<List<(ReactGameMode, int)>>(
          future: _scores,
          builder: (context, snapshot) {
            final scores = snapshot.data ?? const [];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 20),
                  const _OfflineBanner(),
                  const SizedBox(height: 20),
                  const _SectionLabel('YOUR BEST SCORES'),
                  const SizedBox(height: 10),
                  for (final entry in scores) ...[
                    _ScoreRow(mode: entry.$1, score: entry.$2),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  const _PassItNote(),
                  const SizedBox(height: 10),
                  const _FutureOnlineCard(),
                ],
              ),
            );
          },
        ),
      ),
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
        const Column(
          children: [
            Text(
              'SCORES',
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'LOCAL DEVICE RECORDS',
              style: TextStyle(
                color: ReactColors.purple,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF29405D)),
      ),
      child: const Row(
        children: [
          Icon(Icons.offline_bolt_rounded, color: ReactColors.lime, size: 30),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OFFLINE SCOREBOARD',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'NO FAKE RANKS • THESE ARE YOUR REAL SCORES ON THIS DEVICE',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFF263851))),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.mode, required this.score});

  final ReactGameMode mode;
  final int score;

  Color get color => switch (mode) {
        ReactGameMode.classic => ReactColors.electricBlueBright,
        ReactGameMode.blitz => ReactColors.coral,
        ReactGameMode.endless => ReactColors.lime,
        ReactGameMode.daily => ReactColors.purple,
        ReactGameMode.passIt => ReactColors.purple,
      };

  IconData get icon => switch (mode) {
        ReactGameMode.classic => Icons.bolt_rounded,
        ReactGameMode.blitz => Icons.timer_rounded,
        ReactGameMode.endless => Icons.all_inclusive_rounded,
        ReactGameMode.daily => Icons.calendar_month_rounded,
        ReactGameMode.passIt => Icons.groups_2_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.label,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'PERSONAL BEST',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassItNote extends StatelessWidget {
  const _PassItNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.groups_2_rounded, color: ReactColors.purple, size: 24),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'PASS IT IS A MATCH MODE • WINNERS ARE SHOWN PER GAME, NOT AS A PERSONAL SCORE RECORD',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8,
                height: 1.4,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureOnlineCard extends StatelessWidget {
  const _FutureOnlineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1220),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .45)),
      ),
      child: const Row(
        children: [
          Icon(Icons.public_rounded, color: ReactColors.purple, size: 30),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GLOBAL LEADERBOARDS LATER',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ONLINE RANKS, FRIENDS AND SEASONS WILL ONLY APPEAR ONCE REAL BACKEND DATA EXISTS.',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
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
