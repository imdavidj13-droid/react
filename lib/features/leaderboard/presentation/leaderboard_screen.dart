import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const _leaders = [
    ('4', 'BEAT_BLAZER', '32,410', 'A', ReactColors.purple),
    ('5', 'SYNAPSE_42', '28,990', 'B+', Color(0xFF5EE55A)),
    ('6', 'QUICK_FINGERS', '27,840', 'B+', Color(0xFF58C5FF)),
    ('7', 'FLASHPOINT', '25,610', 'B', Color(0xFFFF8A66)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 380 ? 16.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 18),
                  const _ModeTabs(),
                  const SizedBox(height: 20),
                  const _SeasonBanner(),
                  const SizedBox(height: 20),
                  const _Podium(),
                  const SizedBox(height: 18),
                  const _YouCard(),
                  const SizedBox(height: 18),
                  const _SectionLabel('GLOBAL TOP SCORES'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07111D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF223750)),
                    ),
                    child: Column(
                      children: [
                        for (final row in _leaders) _LeaderRow(data: row),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _RankProgressCard(),
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
              'LEADERBOARD',
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'CLASSIC • SEASON 01',
              style: TextStyle(
                color: ReactColors.electricBlueBright,
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

class _ModeTabs extends StatelessWidget {
  const _ModeTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF21344D)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D2949),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ReactColors.electricBlueBright),
              ),
              alignment: Alignment.center,
              child: const Text(
                'GLOBAL',
                style: TextStyle(
                  color: ReactColors.electricBlueBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'FRIENDS',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonBanner extends StatelessWidget {
  const _SeasonBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF29405D)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: ReactColors.lime,
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEASON 01',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'BEST CLASSIC SCORE WINS THE RANK',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '18D LEFT',
            style: TextStyle(
              color: ReactColors.coral,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Expanded(
            child: _PodiumPlayer(
              rank: 2,
              name: 'REFLEX_KING',
              score: '43,890',
              color: ReactColors.electricBlueBright,
              height: 160,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _PodiumPlayer(
              rank: 1,
              name: 'NEON_NINJA',
              score: '54,320',
              color: ReactColors.lime,
              height: 205,
              crown: true,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _PodiumPlayer(
              rank: 3,
              name: 'TAP_MASTER',
              score: '38,670',
              color: Color(0xFFFFA23C),
              height: 142,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPlayer extends StatelessWidget {
  const _PodiumPlayer({
    required this.rank,
    required this.name,
    required this.score,
    required this.color,
    required this.height,
    this.crown = false,
  });

  final int rank;
  final String name;
  final String score;
  final Color color;
  final double height;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (crown)
            Icon(Icons.workspace_premium_rounded, color: color, size: 24),
          if (crown) const SizedBox(height: 3),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF091423),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(Icons.person_rounded, color: color, size: 30),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: height - 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF07111D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: color.withValues(alpha: .6)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: color,
                  fontSize: rank == 1 ? 42 : 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YouCard extends StatelessWidget {
  const _YouCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1D35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReactColors.electricBlueBright, width: 1.4),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Color(0xFF07111D),
            child: Icon(
              Icons.person_outline_rounded,
              color: ReactColors.electricBlueBright,
              size: 32,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR RANK',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '#1,248',
                  style: TextStyle(
                    color: ReactColors.electricBlueBright,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _MiniMetric(label: 'BEST', value: '12,850', color: ReactColors.lime),
          SizedBox(width: 16),
          _MiniMetric(label: 'GRADE', value: 'A-', color: ReactColors.purple),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF233750))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF233750))),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.data});

  final (String, String, String, String, Color) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF081522),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: data.$5.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: data.$5.withValues(alpha: .65)),
            ),
            child: Text(
              data.$1,
              style: TextStyle(
                color: data.$5,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              data.$2,
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.$3,
                style: TextStyle(
                  color: data.$5,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.$4,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankProgressCard extends StatelessWidget {
  const _RankProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263A55)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: ReactColors.lime, size: 21),
              SizedBox(width: 8),
              Text(
                'NEXT TARGET  #1,000',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              Spacer(),
              Text(
                '+1,940',
                style: TextStyle(
                  color: ReactColors.lime,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: LinearProgressIndicator(
              value: .67,
              minHeight: 7,
              backgroundColor: Color(0xFF13233A),
              color: ReactColors.electricBlueBright,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
