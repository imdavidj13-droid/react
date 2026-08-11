import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../classic/presentation/classic_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 780;
            final pad = constraints.maxWidth < 380 ? 18.0 : 22.0;
            final dialSize = constraints.maxWidth.clamp(270.0, 330.0).toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 10, pad, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
                child: Column(
                  children: [
                    const _TopSection(),
                    SizedBox(height: compact ? 14 : 18),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _BestScore()),
                        SizedBox(width: 14),
                        _Streak(),
                      ],
                    ),
                    SizedBox(height: compact ? 4 : 8),
                    _PlayDial(
                      size: dialSize,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ClassicScreen(),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    _PlayButton(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ClassicScreen(),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    const Row(
                      children: [
                        Expanded(
                          child: _NavTile(
                            icon: Icons.view_in_ar_rounded,
                            label: 'MODES',
                            color: Color(0xFF27D8F6),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _NavTile(
                            icon: Icons.calendar_month_rounded,
                            label: 'DAILY',
                            color: ReactColors.lime,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _NavTile(
                            icon: Icons.leaderboard_rounded,
                            label: 'LEADERBOARD',
                            color: ReactColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _CommandsPanel(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            children: [
              _Logo(),
              SizedBox(height: 6),
              Text(
                'FOLLOW THE COMMAND\nBEFORE TIME RUNS OUT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
        ),
        const Align(
          alignment: Alignment.topRight,
          child: _ProfileButton(),
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF07101E),
        border: Border.all(
          color: ReactColors.electricBlue.withValues(alpha: .75),
        ),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: ReactColors.textPrimary,
        size: 22,
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RE',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 42,
            fontWeight: FontWeight.w300,
            letterSpacing: 3.2,
            height: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.change_history_rounded,
            color: Color(0xFF2DDCFF),
            size: 39,
            shadows: [
              Shadow(color: ReactColors.electricBlue, blurRadius: 16),
            ],
          ),
        ),
        Text(
          'CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 42,
            fontWeight: FontWeight.w300,
            letterSpacing: 3.2,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BestScore extends StatelessWidget {
  const _BestScore();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: const Color(0xCC07111D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233651)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            color: ReactColors.lime,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEST SCORE',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '12,850',
                  style: TextStyle(
                    color: ReactColors.lime,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'RANK  #1,248',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
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

class _Streak extends StatelessWidget {
  const _Streak();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF7A72), width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: ReactColors.coral.withValues(alpha: .14),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: ReactColors.coral,
                  size: 20,
                ),
                Text(
                  '7',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'DAY STREAK',
            style: TextStyle(
              color: ReactColors.coral,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
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
              width: size * .50,
              height: size * .50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ReactColors.background,
                border: Border.all(
                  color: const Color(0xFF42D8FF),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ReactColors.electricBlue.withValues(alpha: .13),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF39D8FF),
                size: 74,
                shadows: [
                  Shadow(color: ReactColors.electricBlue, blurRadius: 14),
                ],
              ),
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
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF14263E);

    canvas.drawCircle(center, radius - 3, base);
    canvas.drawCircle(center, radius * .72, base);
    canvas.drawCircle(center, radius * .59, base);

    void arc(double start, double sweep, Color color, double r) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9
        ..color = color.withValues(alpha: .08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5
        ..color = color;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, start, sweep, false, glow);
      canvas.drawArc(rect, start, sweep, false, line);
    }

    arc(
      math.pi * .72,
      math.pi * .54,
      ReactColors.electricBlueBright,
      radius * .83,
    );
    arc(
      math.pi * 1.54,
      math.pi * .43,
      ReactColors.lime,
      radius * .76,
    );
    arc(
      math.pi * .08,
      math.pi * .42,
      const Color(0xFFFF6D8B),
      radius * .87,
    );

    final tick = Paint()..strokeWidth = 1.4;
    for (var i = 0; i < 52; i++) {
      final a = i * math.pi * 2 / 52;
      tick.color = i < 18
          ? ReactColors.electricBlue.withValues(alpha: .58)
          : i < 35
              ? ReactColors.lime.withValues(alpha: .46)
              : ReactColors.purple.withValues(alpha: .43);
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF24AFFF), Color(0xFF0D78F6)],
          ),
          border: Border.all(color: const Color(0xFF74E8FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: ReactColors.electricBlue.withValues(alpha: .16),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            SizedBox(width: 14),
            Text(
              'PLAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
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
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xCC07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A3A52)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 7),
          FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xCC07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263851)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: Color(0xFF263851))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'COMMANDS',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFF263851))),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Command(
                icon: Icons.touch_app_rounded,
                label: 'TAP',
                color: Color(0xFF55B8FF),
              ),
              _Command(
                icon: Icons.double_arrow_rounded,
                label: 'SWIPE',
                color: ReactColors.electricBlue,
              ),
              _Command(
                icon: Icons.zoom_in_map_rounded,
                label: 'PINCH',
                color: ReactColors.lime,
              ),
              _Command(
                icon: Icons.sync_rounded,
                label: 'ROTATE',
                color: ReactColors.purple,
              ),
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
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
