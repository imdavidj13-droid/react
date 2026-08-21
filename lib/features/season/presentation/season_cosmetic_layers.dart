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
  static Widget home({required Widget child}) {
    final theme = SeasonCosmeticState.equippedReward('home_theme');
    if (theme == null) return child;
    final accent = accentForReward(theme);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: CustomPaint(
            painter: _SeasonHomePainter(
              accent: accent,
              rewardKey: theme.rewardKey,
            ),
          ),
        ),
      ],
    );
  }

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

/// Screen-level profile cosmetics belong here only when they genuinely affect
/// the whole Player Profile surface.
///
/// Player-code styles are deliberately NOT rendered here: they are scoped to
/// the RX code inside [PlayerProfileScreen]. Previously they also drew traces
/// and a floating label across the complete Profile/Friends screens, which was
/// much broader than a "player code style" implies.
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
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accent.withValues(alpha: .75),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .12),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
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

class _SeasonHomePainter extends CustomPainter {
  const _SeasonHomePainter({required this.accent, required this.rewardKey});

  final Color accent;
  final String rewardKey;

  @override
  void paint(Canvas canvas, Size size) {
    if (rewardKey.contains('neon_rail')) {
      _paintRails(canvas, size);
    } else if (rewardKey.endsWith('_grid')) {
      _paintGrid(canvas, size);
    } else {
      _paintOverdrive(canvas, size);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: .10), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .5, size.height * .42),
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
    for (double x = -size.height; x < size.width + size.height; x += gap) {
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
    final center = Offset(size.width * .5, size.height * .42);
    for (final scale in const <double>[.20, .32, .44]) {
      canvas.drawCircle(center, size.width * scale, paint);
    }
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
  }

  void _paintRails(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = accent.withValues(alpha: .075)
      ..strokeWidth = 2;
    final glow = Paint()
      ..color = accent.withValues(alpha: .025)
      ..strokeWidth = 10;
    const gap = 54.0;
    for (double x = 26; x < size.width; x += gap) {
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), glow)
        ..drawLine(Offset(x, 0), Offset(x, size.height), rail);
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonHomePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.rewardKey != rewardKey;
}
