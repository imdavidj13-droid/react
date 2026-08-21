import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/season_cosmetic_state.dart';
import '../domain/season_models.dart';

/// Presentation-only layers for season-exclusive cosmetic families.
///
/// The visual treatment is derived from reward metadata/key instead of a
/// season switch statement, so later seasons can add rewards without adding
/// another hardcoded UI branch.
abstract final class SeasonCosmeticLayers {
  static Widget home({required Widget child}) => SeasonHomeLayer(child: child);

  static Color accentForReward(SeasonReward reward) {
    final hash = reward.rewardKey.codeUnits.fold<int>(0, (value, unit) {
      return ((value * 31) + unit) & 0x7fffffff;
    });
    const palette = <Color>[
      ReactColors.electricBlueBright,
      ReactColors.lime,
      ReactColors.purple,
      Color(0xFFFF6A45),
      Color(0xFFFFD84A),
      Color(0xFF42F5C8),
    ];
    return palette[hash % palette.length];
  }
}

/// Animated Home-only cosmetic layer. It never changes Home content/layout or
/// any gameplay surface. Reduced-animation accessibility settings freeze the
/// treatment at a stable frame.
class SeasonHomeLayer extends StatefulWidget {
  const SeasonHomeLayer({required this.child, super.key});

  final Widget child;

  @override
  State<SeasonHomeLayer> createState() => _SeasonHomeLayerState();
}

class _SeasonHomeLayerState extends State<SeasonHomeLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = SeasonCosmeticState.equippedReward('home_theme') ??
        SeasonCosmeticState.equippedReward('home_background');
    if (theme == null) return widget.child;
    final accent = SeasonCosmeticLayers.accentForReward(theme);
    final frozen = _animationsDisabled == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _SeasonHomePainter(
                accent: accent,
                rewardKey: theme.rewardKey,
                phase: frozen ? 0 : _controller.value,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Screen-level profile cosmetics belong here only when they genuinely affect
/// the whole Player Profile surface.
///
/// Player-code styles are deliberately not rendered here: they are scoped to
/// the RX code inside the profile identity card. Previously they also drew
/// traces and a floating label across the complete Profile/Friends screens,
/// which was much broader than a player-code style implies.
class SeasonProfileLayer extends StatelessWidget {
  const SeasonProfileLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = SeasonCosmeticState.equippedReward('profile_frame');
    if (frame == null) return child;

    final accent = SeasonCosmeticLayers.accentForReward(frame);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: SafeArea(
            child: CustomPaint(
              painter: _ProfileFramePainter(
                accent: accent,
                rewardKey: frame.rewardKey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Player-code cosmetics are local identity cosmetics, not a Friends-screen
/// theme. Keep this wrapper for API compatibility but intentionally leave the
/// Friends surface untouched.
class SeasonFriendsLayer extends StatelessWidget {
  const SeasonFriendsLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _ProfileFramePainter extends CustomPainter {
  const _ProfileFramePainter({required this.accent, required this.rewardKey});

  final Color accent;
  final String rewardKey;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
      const Radius.circular(24),
    );

    if (rewardKey.contains('ion_ring')) {
      final soft = Paint()
        ..color = accent.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7;
      final line = Paint()
        ..color = accent.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7;
      canvas
        ..drawRRect(outer, soft)
        ..drawRRect(outer, line);
      final corner = Paint()
        ..color = accent.withValues(alpha: .95)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      const length = 34.0;
      canvas
        ..drawLine(const Offset(18, 8), const Offset(18 + length, 8), corner)
        ..drawLine(
          Offset(size.width - 18 - length, size.height - 8),
          Offset(size.width - 18, size.height - 8),
          corner,
        );
      return;
    }

    if (rewardKey.contains('frame_current')) {
      final rail = Paint()
        ..color = accent.withValues(alpha: .78)
        ..strokeWidth = 2;
      final glow = Paint()
        ..color = accent.withValues(alpha: .11)
        ..strokeWidth = 8;
      for (final x in <double>[7, size.width - 7]) {
        canvas
          ..drawLine(Offset(x, 26), Offset(x, size.height - 26), glow)
          ..drawLine(Offset(x, 26), Offset(x, size.height - 26), rail);
      }
      final faint = Paint()
        ..color = accent.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(outer, faint);
      return;
    }

    final glow = Paint()
      ..color = accent.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final border = Paint()
      ..color = accent.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(20),
    );
    canvas
      ..drawRRect(outer, glow)
      ..drawRRect(outer, border)
      ..drawRRect(
        inner,
        Paint()
          ..color = accent.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(covariant _ProfileFramePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.rewardKey != rewardKey;
}

class _SeasonHomePainter extends CustomPainter {
  const _SeasonHomePainter({
    required this.accent,
    required this.rewardKey,
    required this.phase,
  });

  final Color accent;
  final String rewardKey;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (rewardKey.contains('neon_rail')) {
      _paintRails(canvas, size);
    } else if (rewardKey.endsWith('_grid')) {
      _paintGrid(canvas, size);
    } else {
      _paintOverdrive(canvas, size);
    }

    final glowCenter = Offset(
      size.width * (.50 + math.sin(phase * math.pi * 2) * .07),
      size.height * (.42 + math.cos(phase * math.pi * 2) * .025),
    );
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: .10), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: glowCenter,
          radius: math.max(size.width, size.height) * .48,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: .055)
      ..strokeWidth = 1;
    const gap = 46.0;
    final shift = phase * gap;
    for (double x = -size.height - gap + shift;
        x < size.width + size.height + gap;
        x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  void _paintOverdrive(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: .065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(
      size.width * .5,
      size.height * (.42 + math.sin(phase * math.pi * 2) * .012),
    );
    final pulse = 1 + math.sin(phase * math.pi * 2) * .025;
    for (final scale in const <double>[.20, .32, .44]) {
      canvas.drawCircle(center, size.width * scale * pulse, paint);
    }
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
    final sweep = Paint()
      ..color = accent.withValues(alpha: .045)
      ..strokeWidth = 2;
    final sweepY = (phase * size.height) % math.max(1, size.height);
    canvas.drawLine(Offset(0, sweepY), Offset(size.width, sweepY), sweep);
  }

  void _paintRails(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = accent.withValues(alpha: .075)
      ..strokeWidth = 2;
    final glow = Paint()
      ..color = accent.withValues(alpha: .025)
      ..strokeWidth = 10;
    const gap = 54.0;
    final shift = phase * gap;
    for (double x = 26 - gap + shift; x < size.width + gap; x += gap) {
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), glow)
        ..drawLine(Offset(x, 0), Offset(x, size.height), rail);
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonHomePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.rewardKey != rewardKey ||
      oldDelegate.phase != phase;
}
