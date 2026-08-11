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
          const _ClassicBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 760;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _RoundControl(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          const _HudMetric(
                            label: 'SCORE',
                            value: '12',
                            color: ReactColors.lime,
                          ),
                          const SizedBox(width: 22),
                          const _HudMetric(
                            label: 'COMBO',
                            value: 'x4',
                            color: ReactColors.purple,
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 24 : 34),
                      const Text(
                        'CLASSIC RUN',
                        style: TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.1,
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 28),
                      const Expanded(
                        child: Center(
                          child: _CommandDisplay(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'PERFORM THE COMMAND',
                        style: TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Complete it before the timer ring expires',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _CommandHints(),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const ResultsScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5E6D88),
                            side: const BorderSide(color: Color(0xFF1A2740)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.flag_outlined, size: 16),
                          label: const Text(
                            'PREVIEW RESULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandDisplay extends StatelessWidget {
  const _CommandDisplay();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width.clamp(300.0, 360.0).toDouble();

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size - 20,
            height: size - 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ReactColors.electricBlue.withValues(alpha: .24),
                  blurRadius: 70,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: size - 20,
            child: const CircularProgressIndicator(
              value: .72,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: Color(0xFF13213A),
              color: ReactColors.electricBlueBright,
            ),
          ),
          SizedBox.square(
            dimension: size - 52,
            child: CircularProgressIndicator(
              value: .84,
              strokeWidth: 2,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFF172033),
              color: ReactColors.electricBlue.withValues(alpha: .6),
            ),
          ),
          Container(
            width: size - 84,
            height: size - 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF0C1728), Color(0xFF070B15)],
              ),
              border: Border.all(color: const Color(0xFF17345C)),
              boxShadow: [
                BoxShadow(
                  color: ReactColors.electricBlue.withValues(alpha: .16),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: ReactColors.electricBlueBright,
                  size: 46,
                ),
                SizedBox(height: 14),
                Text(
                  'DOUBLE\nTAP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: .92,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '1.8',
                  style: TextStyle(
                    color: ReactColors.electricBlueBright,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SECONDS',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
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

class _CommandHints extends StatelessWidget {
  const _CommandHints();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HintDot(color: ReactColors.electricBlueBright),
        SizedBox(width: 8),
        Text(
          '10 COMMANDS ACTIVE',
          style: TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(width: 8),
        _HintDot(color: ReactColors.purple),
      ],
    );
  }
}

class _HintDot extends StatelessWidget {
  const _HintDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 8)],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF090E19),
        foregroundColor: ReactColors.textPrimary,
        side: const BorderSide(color: Color(0xFF1B2B46)),
      ),
      icon: Icon(icon),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
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
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ClassicBackdrop extends StatelessWidget {
  const _ClassicBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.05),
          radius: 1.05,
          colors: [Color(0xFF07152A), ReactColors.background, Color(0xFF02040B)],
        ),
      ),
    );
  }
}
