import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../../game/react_game.dart';
import '../../results/presentation/results_screen.dart';

class ClassicScreen extends StatefulWidget {
  const ClassicScreen({super.key});

  @override
  State<ClassicScreen> createState() => _ClassicScreenState();
}

class _ClassicScreenState extends State<ClassicScreen> {
  late final ReactGame _game;

  @override
  void initState() {
    super.initState();
    _game = ReactGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CircleControl(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const _TopMetric(label: 'SCORE', value: '12', color: ReactColors.lime),
                      const SizedBox(width: 18),
                      const _TopMetric(label: 'COMBO', value: 'x4', color: ReactColors.purple),
                    ],
                  ),
                  const Spacer(),
                  const _CommandOrb(),
                  const Spacer(),
                  const Text(
                    'Perform the command before the ring empties',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResultsScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ReactColors.textSecondary,
                        side: BorderSide(
                          color: ReactColors.border.withValues(alpha: 0.8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('PREVIEW RESULT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandOrb extends StatelessWidget {
  const _CommandOrb();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width.clamp(250.0, 330.0);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ReactColors.electricBlue.withValues(alpha: 0.24),
                  blurRadius: 70,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: size - 14,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: ReactColors.panelSoft,
              color: ReactColors.electricBlueBright,
            ),
          ),
          Container(
            width: size - 44,
            height: size - 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ReactColors.backgroundRaised,
              border: Border.all(
                color: ReactColors.electricBlue.withValues(alpha: 0.38),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: ReactColors.electricBlueBright,
                  size: 42,
                ),
                SizedBox(height: 16),
                Text(
                  'DOUBLE\nTAP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 0.95,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  '1.8s',
                  style: TextStyle(
                    color: ReactColors.electricBlueBright,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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

class _CircleControl extends StatelessWidget {
  const _CircleControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: ReactColors.panel,
        foregroundColor: ReactColors.textPrimary,
        side: const BorderSide(color: ReactColors.border),
      ),
      icon: Icon(icon),
    );
  }
}

class _TopMetric extends StatelessWidget {
  const _TopMetric({
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
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
