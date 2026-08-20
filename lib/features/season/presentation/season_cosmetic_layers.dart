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
            painter: _SeasonGridPainter(accent: accent),
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
/// the whole profile surface. Identity cosmetics such as badges, titles and
/// emblems must be rendered inside the profile identity card instead of being
/// floated over the page header.
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

class _SeasonGridPainter extends CustomPainter {
  const _SeasonGridPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(covariant _SeasonGridPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
