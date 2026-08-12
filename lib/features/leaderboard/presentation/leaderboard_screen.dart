import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const _leaders = [
    ('1', 'NEON_NINJA', '54,320', '14 DAYS', 'S+', ReactColors.lime),
    ('2', 'REFLEX_KING', '43,890', '11 DAYS', 'S', ReactColors.electricBlueBright),
    ('3', 'TAP_MASTER', '38,670', '9 DAYS', 'A+', Color(0xFFFFA23C)),
    ('4', 'BEAT_BLAZER', '32,410', '7 DAYS', 'A', ReactColors.purple),
    ('5', 'SYNAPSE_42', '28,990', '6 DAYS', 'B+', Color(0xFF5EE55A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF07101E),
                      foregroundColor: ReactColors.textPrimary,
                      side: const BorderSide(color: Color(0xFF1E3552)),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const Spacer(),
                  const Text(
                    'LEADERBOARD',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF07111D),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0xFF21344D)),
                ),
                child: const Row(
                  children: [
                    Expanded(child: _Tab(label: 'GLOBAL', active: true)),
                    Expanded(child: _Tab(label: 'FRIENDS', active: false)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _ProfileSummary(),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF07111D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF293B54)),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: Row(
                        children: [
                          SizedBox(width: 34, child: Text('RANK', style: _headerStyle)),
                          Expanded(child: Text('PLAYER', style: _headerStyle)),
                          SizedBox(width: 72, child: Text('SCORE', style: _headerStyle)),
                          SizedBox(width: 62, child: Text('GRADE', textAlign: TextAlign.end, style: _headerStyle)),
                        ],
                      ),
                    ),
                    for (final row in _leaders) _LeaderRow(data: row),
                    const _YouRow(),
                    const _LeaderRow(data: ('1,249', 'QUICK_FINGERS', '12,720', '7 DAYS', 'A-', Color(0xFF5A6D85))),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF168CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                      side: const BorderSide(color: Color(0xFF5FE5FF)),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'START NEW RUN',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: ReactColors.textSecondary,
  fontSize: 8,
  fontWeight: FontWeight.w800,
  letterSpacing: .8,
);

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),
        Text(
          label,
          style: TextStyle(
            color: active ? ReactColors.electricBlueBright : ReactColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const Spacer(),
        Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? ReactColors.electricBlueBright : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF29405D)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFF0A1525),
            child: Icon(Icons.person_outline_rounded, color: ReactColors.electricBlueBright, size: 38),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REACTOR_7', style: TextStyle(color: ReactColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: .8)),
                SizedBox(height: 9),
                Row(children: [Expanded(child: _SummaryMetric(label: 'TOTAL GAMES', value: '124', color: ReactColors.electricBlueBright)), Expanded(child: _SummaryMetric(label: 'BEST COMBO', value: 'x28', color: ReactColors.purple)), Expanded(child: _SummaryMetric(label: 'SEASON RANK', value: '#1,248', color: ReactColors.lime))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 7, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.data});
  final (String, String, String, String, String, Color) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF18283D)))),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text(data.$1, style: TextStyle(color: data.$6, fontSize: 13, fontWeight: FontWeight.w900))),
          Expanded(child: Text(data.$2, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w800))),
          SizedBox(width: 72, child: Text(data.$3, style: TextStyle(color: data.$6, fontSize: 12, fontWeight: FontWeight.w900))),
          SizedBox(width: 62, child: Text(data.$5, textAlign: TextAlign.end, style: TextStyle(color: data.$6, fontSize: 12, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _YouRow extends StatelessWidget {
  const _YouRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: ReactColors.electricBlueBright),
        color: const Color(0xFF0B2342),
      ),
      child: const Row(
        children: [
          SizedBox(width: 34, child: Text('1,248', style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 12, fontWeight: FontWeight.w900))),
          Expanded(child: Text('YOU', style: TextStyle(color: ReactColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900))),
          SizedBox(width: 72, child: Text('12,850', style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 12, fontWeight: FontWeight.w900))),
          SizedBox(width: 62, child: Text('A-', textAlign: TextAlign.end, style: TextStyle(color: ReactColors.electricBlueBright, fontSize: 12, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}
