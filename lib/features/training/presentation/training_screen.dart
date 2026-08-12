import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  static const _commands = <_TrainingCommand>[
    _TrainingCommand(
      title: 'TAP',
      description: 'Tap the target at the right time.',
      icon: Icons.touch_app_rounded,
      color: Color(0xFF55B8FF),
      stars: 3,
    ),
    _TrainingCommand(
      title: 'DOUBLE TAP',
      description: 'Tap twice quickly when prompted.',
      icon: Icons.ads_click_rounded,
      color: Color(0xFF2DDCFF),
      stars: 2,
    ),
    _TrainingCommand(
      title: 'HOLD',
      description: 'Press and hold as instructed.',
      icon: Icons.pan_tool_alt_rounded,
      color: ReactColors.lime,
      stars: 2,
    ),
    _TrainingCommand(
      title: 'SWIPE',
      description: 'Swipe in the indicated direction.',
      icon: Icons.double_arrow_rounded,
      color: ReactColors.electricBlue,
      stars: 3,
    ),
    _TrainingCommand(
      title: 'PINCH',
      description: 'Move two fingers together.',
      icon: Icons.close_fullscreen_rounded,
      color: ReactColors.lime,
      stars: 2,
    ),
    _TrainingCommand(
      title: 'SPREAD',
      description: 'Move two fingers apart.',
      icon: Icons.open_in_full_rounded,
      color: ReactColors.purple,
      stars: 1,
    ),
    _TrainingCommand(
      title: 'FREEZE',
      description: 'Do nothing until the timer ends.',
      icon: Icons.ac_unit_rounded,
      color: ReactColors.electricBlueBright,
      stars: 0,
    ),
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
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 18),
                  const _HeroCard(),
                  const SizedBox(height: 22),
                  const _SectionTitle('PRACTICE COMMANDS'),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _commands.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: .93,
                    ),
                    itemBuilder: (context, index) {
                      return _CommandCard(command: _commands[index]);
                    },
                  ),
                  const SizedBox(height: 16),
                  const _ProgressCard(),
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
            side: const BorderSide(color: Color(0xFF1E3552)),
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMAND TRAINING',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'LEARN EVERY INPUT BEFORE YOU PLAY',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MASTER EVERY COMMAND.',
                      style: TextStyle(
                        color: ReactColors.electricBlueBright,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Build speed. Sharpen reflexes.\nReact without thinking.',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14),
              _TrainingOrb(),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF168CFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: const BorderSide(color: Color(0xFF5FE5FF)),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'START TRAINING',
                style: TextStyle(
                  fontSize: 15,
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

class _TrainingOrb extends StatelessWidget {
  const _TrainingOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2DDCFF), width: 2),
      ),
      child: const Icon(
        Icons.view_in_ar_rounded,
        color: ReactColors.electricBlueBright,
        size: 46,
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
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF263851))),
      ],
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({required this.command});

  final _TrainingCommand command;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF293B54)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(command.icon, color: command.color, size: 38),
          const SizedBox(height: 12),
          Text(
            command.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            command.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final filled = index < command.stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 17,
                  color: filled ? command.color : const Color(0xFF34445A),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF29405D)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: .43,
                  strokeWidth: 5,
                  backgroundColor: Color(0xFF12233A),
                  color: ReactColors.electricBlueBright,
                ),
                Text(
                  '43%',
                  style: TextStyle(
                    color: ReactColors.electricBlueBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRAINING PROGRESS',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '3 / 7  COMMANDS MASTERED',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.bolt_rounded, color: ReactColors.electricBlueBright, size: 28),
        ],
      ),
    );
  }
}

class _TrainingCommand {
  const _TrainingCommand({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.stars,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int stars;
}
