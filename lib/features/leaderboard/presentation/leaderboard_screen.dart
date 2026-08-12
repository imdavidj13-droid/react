import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const _leaders = [
    ('4', 'BEAT_BLAZER', '111', ReactColors.purple),
    ('5', 'SYNAPSE_42', '103', Color(0xFF5EE55A)),
    ('6', 'QUICK_FINGERS', '97', Color(0xFF58C5FF)),
    ('7', 'FLASHPOINT', '91', Color(0xFFFF8A66)),
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
                  const SizedBox(height: 18),
                  const _SeasonBanner(),
                  const SizedBox(height: 18),
                  const _Podium(),
                  const SizedBox(height: 16),
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
          Icon(Icons.emoji_events_outlined, color: ReactColors.lime, size: 28),
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
                  'BEST CLASSIC SCORE SETS YOUR RANK',
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
    return const SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumPlayer(
              rank: 2,
              name: 'REFLEX_KING',
              score: '128',
              color: ReactColors.electricBlueBright,
              blockHeight: 62,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _PodiumPlayer(
              rank: 1,
              name: 'NEON_NINJA',
              score: '142',
              color: ReactColors.lime,
              blockHeight: 88,
              crown: true,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _PodiumPlayer(
              rank: 3,
              name: 'TAP_MASTER',
              score: '119',
              color: Color(0xFFFFA23C),
              blockHeight: 50,
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
    required this.blockHeight,
    this.crown = false,
  });

  final int rank;
  final String name;
  final String score;
  final Color color;
  final double blockHeight;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 26,
          child: crown
              ? Icon(Icons.workspace_premium_rounded, color: color, size: 22)
              : null,
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF091423),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.person_rounded, color: color, size: 27),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          score,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: blockHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF07111D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: color.withValues(alpha: .6)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              color: color,
              fontSize: rank == 1 ? 36 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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
            radius: 28,
            backgroundColor: Color(0xFF07111D),
            child: Icon(
              Icons.person_outline_rounded,
              color: ReactColors.electricBlueBright,
              size: 31,
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
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _MiniMetric(label: 'YOUR BEST', value: '42', color: ReactColors.lime),
          SizedBox(width: 14),
          _MiniMetric(label: 'TOP SCORE', value: '142', color: ReactColors.purple),
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
            fontSize: 6.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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

  final (String, String, String, Color) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF081522),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: data.$4.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: data.$4.withValues(alpha: .65)),
            ),
            child: Text(
              data.$1,
              style: TextStyle(
                color: data.$4,
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
          Text(
            data.$3,
            style: TextStyle(
              color: data.$4,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
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
                '+5',
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
              value: .74,
              minHeight: 7,
              backgroundColor: Color(0xFF13233A),
              color: ReactColors.electricBlueBright,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'A score of 47 would currently move you into the top 1,000.',
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
