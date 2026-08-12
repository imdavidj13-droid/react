import 'package:flutter/material.dart';

import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../modes/presentation/mode_run_screen.dart';

class PassItScreen extends StatefulWidget {
  const PassItScreen({super.key});

  @override
  State<PassItScreen> createState() => _PassItScreenState();
}

class _PassItScreenState extends State<PassItScreen> {
  late int _playerCount;

  @override
  void initState() {
    super.initState();
    _playerCount = ReactSettings.passItPlayerCount;
  }

  Future<void> _setPlayerCount(int value) async {
    setState(() => _playerCount = value);
    await ReactSettings.setPassItPlayerCount(value);
  }

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ModeRunScreen(mode: ReactRunMode.passIt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      ReactColors.electricBlueBright,
      ReactColors.lime,
      ReactColors.coral,
      ReactColors.purple,
    ];

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
                  const _Hero(),
                  const SizedBox(height: 18),
                  const _SectionTitle('PLAYERS'),
                  const SizedBox(height: 10),
                  _PlayerCountSelector(
                    value: _playerCount,
                    onChanged: _setPlayerCount,
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _playerCount; i++) ...[
                    _PlayerRow(index: i + 1, color: colors[i]),
                    if (i != _playerCount - 1) const SizedBox(height: 9),
                  ],
                  const SizedBox(height: 18),
                  const _SectionTitle('ROUND RULES'),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(
                        child: _RuleCard(
                          icon: Icons.favorite_rounded,
                          value: '3',
                          label: 'LIVES EACH',
                          color: ReactColors.coral,
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _RuleCard(
                          icon: Icons.swap_horiz_rounded,
                          value: '1 CMD',
                          label: 'PER TURN',
                          color: ReactColors.lime,
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _RuleCard(
                          icon: Icons.emoji_events_rounded,
                          value: 'LAST',
                          label: 'PLAYER WINS',
                          color: ReactColors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _RoundPreview(playerCount: _playerCount),
                  const SizedBox(height: 16),
                  _StartButton(onTap: () => _start(context)),
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

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050A13),
              border: Border.all(color: ReactColors.purple, width: 2),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: ReactColors.purple,
              size: 40,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASS IT',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'LOCAL MULTIPLAYER',
                  style: TextStyle(
                    color: ReactColors.purple,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Complete one command, then hand the phone over. Miss and you lose a life. Last player standing wins.',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF263851))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF263851))),
      ],
    );
  }
}

class _PlayerCountSelector extends StatelessWidget {
  const _PlayerCountSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .32)),
      ),
      child: Row(
        children: [
          for (final count in const [2, 3, 4]) ...[
            Expanded(
              child: InkWell(
                onTap: () => onChanged(count),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: 46,
                  decoration: BoxDecoration(
                    color: value == count
                        ? ReactColors.purple.withValues(alpha: .16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: value == count
                          ? ReactColors.purple
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$count PLAYERS',
                      style: TextStyle(
                        color: value == count
                            ? ReactColors.textPrimary
                            : ReactColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (count != 4) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.index, required this.color});
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(Icons.person_rounded, color: color, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER $index',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  index == 1 ? 'STARTS FIRST' : 'WAITING TURN',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '♥ ♥ ♥',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 7),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 7.2,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundPreview extends StatelessWidget {
  const _RoundPreview({required this.playerCount});

  final int playerCount;

  @override
  Widget build(BuildContext context) {
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
          const Icon(
            Icons.phone_android_rounded,
            color: ReactColors.electricBlueBright,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$playerCount PLAYERS • ONE COMMAND EACH • THEN PASS',
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: ReactColors.purple),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onTap,
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
          'START GAME',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
