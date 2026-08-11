import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../classic/presentation/classic_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 780;
                final pad = constraints.maxWidth < 380 ? 18.0 : 24.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                    child: Column(
                      children: [
                        const _Header(),
                        SizedBox(height: compact ? 20 : 30),
                        const _Logo(),
                        const SizedBox(height: 12),
                        const Text(
                          'FOLLOW THE COMMAND\nBEFORE TIME RUNS OUT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ReactColors.textSecondary,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        SizedBox(height: compact ? 18 : 28),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _BestScore()),
                            SizedBox(width: 14),
                            _Streak(),
                          ],
                        ),
                        Transform.translate(
                          offset: Offset(0, compact ? -18 : -28),
                          child: _PlayDial(
                            size: constraints.maxWidth.clamp(270.0, 350.0).toDouble(),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const ClassicScreen()),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, compact ? -8 : -16),
                          child: _PlayButton(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const ClassicScreen()),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 14),
                        const Row(
                          children: [
                            Expanded(child: _NavTile(icon: Icons.view_in_ar_rounded, label: 'MODES', color: Color(0xFF27D8F6))),
                            SizedBox(width: 10),
                            Expanded(child: _NavTile(icon: Icons.calendar_month_rounded, label: 'DAILY', color: ReactColors.lime)),
                            SizedBox(width: 10),
                            Expanded(child: _NavTile(icon: Icons.leaderboard_rounded, label: 'LEADERBOARD', color: ReactColors.purple)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _CommandsPanel(),
                      ],
                    ),
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

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF07101E),
            border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .75)),
          ),
          child: const Icon(Icons.person_outline_rounded, color: ReactColors.textPrimary, size: 25),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('RE', style: TextStyle(color: ReactColors.textPrimary, fontSize: 49, fontWeight: FontWeight.w300, letterSpacing: 4, height: 1)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: const Icon(Icons.change_history_rounded, color: Color(0xFF2DDCFF), size: 45, shadows: [Shadow(color: ReactColors.electricBlue, blurRadius: 18)]),
        ),
        const Text('CT', style: TextStyle(color: ReactColors.textPrimary, fontSize: 49, fontWeight: FontWeight.w300, letterSpacing: 4, height: 1)),
      ],
    );
  }
}

class _BestScore extends StatelessWidget {
  const _BestScore();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xA6081220),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF233651)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_outlined, color: ReactColors.lime, size: 23),
          SizedBox(height: 8),
          Text('BEST SCORE', style: TextStyle(color: ReactColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          SizedBox(height: 3),
          Text('12,850', style: TextStyle(color: ReactColors.lime, fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: 1)),
          SizedBox(height: 4),
          Text('RANK  #1,248', style: TextStyle(color: ReactColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .8)),
        ],
      ),
    );
  }
}

class _Streak extends StatelessWidget {
  const _Streak();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF7A72), width: 4),
              boxShadow: [BoxShadow(color: ReactColors.coral.withValues(alpha: .18), blurRadius: 22)],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department_rounded, color: ReactColors.coral, size: 24),
                Text('7', style: TextStyle(color: ReactColors.textPrimary, fontSize: 21, fontWeight: FontWeight.w900, height: 1)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('DAY STREAK', style: TextStyle(color: ReactColors.coral, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _PlayDial extends StatelessWidget {
  const _PlayDial({required this.size, required this.onTap});
  final double size;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _DialPainter(),
          child: Center(
            child: Container(
              width: size * .52,
              height: size * .52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF143D67), Color(0xFF071525), Color(0xFF030914)]),
                border: Border.all(color: ReactColors.electricBlueBright, width: 3),
                boxShadow: [
                  BoxShadow(color: ReactColors.electricBlue.withValues(alpha: .34), blurRadius: 30, spreadRadius: 3),
                  BoxShadow(color: ReactColors.electricBlueBright.withValues(alpha: .18), blurRadius: 60, spreadRadius: 8),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF39D8FF), size: 82, shadows: [Shadow(color: ReactColors.electricBlue, blurRadius: 22)]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF14263E);
    canvas.drawCircle(center, radius - 3, base);
    canvas.drawCircle(center, radius * .72, base);
    canvas.drawCircle(center, radius * .59, base);

    void arc(double start, double sweep, Color color, double r) {
      final glow = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 12..color = color.withValues(alpha: .13)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      final line = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 5..color = color;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, start, sweep, false, glow);
      canvas.drawArc(rect, start, sweep, false, line);
    }

    arc(math.pi * .72, math.pi * .54, ReactColors.electricBlueBright, radius * .83);
    arc(math.pi * 1.54, math.pi * .43, ReactColors.lime, radius * .76);
    arc(math.pi * .08, math.pi * .42, const Color(0xFFFF6D8B), radius * .87);

    final tick = Paint()..strokeWidth = 1.5;
    for (var i = 0; i < 52; i++) {
      final a = i * math.pi * 2 / 52;
      tick.color = i < 18 ? ReactColors.electricBlue.withValues(alpha: .6) : i < 35 ? ReactColors.lime.withValues(alpha: .48) : ReactColors.purple.withValues(alpha: .45);
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (radius * .91);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (radius * .95);
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(colors: [Color(0xFF159DFF), Color(0xFF176BFF)]),
          border: Border.all(color: const Color(0xFF66E5FF), width: 2),
          boxShadow: [BoxShadow(color: ReactColors.electricBlue.withValues(alpha: .38), blurRadius: 28, spreadRadius: 2)],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            SizedBox(width: 14),
            Text('PLAY', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 4)),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(color: const Color(0xA6081220), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A3A52))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 8),
          FittedBox(child: Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8))),
        ],
      ),
    );
  }
}

class _CommandsPanel extends StatelessWidget {
  const _CommandsPanel();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 15),
      decoration: BoxDecoration(color: const Color(0xA6081220), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF263851))),
      child: const Column(
        children: [
          Row(children: [Expanded(child: Divider(color: Color(0xFF263851))), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('COMMANDS', style: TextStyle(color: ReactColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))), Expanded(child: Divider(color: Color(0xFF263851)))]),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Command(icon: Icons.touch_app_rounded, label: 'TAP', color: Color(0xFF55B8FF)),
              _Command(icon: Icons.double_arrow_rounded, label: 'SWIPE', color: ReactColors.electricBlue),
              _Command(icon: Icons.zoom_in_map_rounded, label: 'PINCH', color: ReactColors.lime),
              _Command(icon: Icons.vibration_rounded, label: 'SHAKE', color: ReactColors.coral),
              _Command(icon: Icons.sync_rounded, label: 'ROTATE', color: ReactColors.purple),
            ],
          ),
        ],
      ),
    );
  }
}

class _Command extends StatelessWidget {
  const _Command({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(children: [Icon(icon, color: color, size: 25), const SizedBox(height: 7), Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800))]);
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(center: Alignment(0, -.25), radius: 1.05, colors: [Color(0xFF081A2D), Color(0xFF030814), Color(0xFF01030A)]),
      ),
    );
  }
}
