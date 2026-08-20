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
/// the player identity surface.
class SeasonProfileLayer extends StatelessWidget {
  const SeasonProfileLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = SeasonCosmeticState.equippedReward('profile_frame');
    final codeStyle = SeasonCosmeticState.equippedReward('player_code_style');
    if (frame == null && codeStyle == null) return child;

    final frameAccent = frame == null
        ? null
        : SeasonCosmeticLayers.accentForReward(frame);
    final codeAccent = codeStyle == null
        ? null
        : SeasonCosmeticLayers.accentForReward(codeStyle);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (frameAccent != null)
                  Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: frameAccent.withValues(alpha: .75),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: frameAccent.withValues(alpha: .12),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                if (codeStyle != null && codeAccent != null) ...[
                  CustomPaint(
                    painter: _PlayerCodeTracePainter(accent: codeAccent),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: _CodeStylePill(
                      reward: codeStyle,
                      accent: codeAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Makes an equipped player-code cosmetic visibly affect the Friends surface.
///
/// The treatment is deliberately limited to the local player's networking
/// screen so another player's identity never inherits this device's cosmetic.
class SeasonFriendsLayer extends StatelessWidget {
  const SeasonFriendsLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = SeasonCosmeticState.equippedReward('player_code_style');
    if (style == null) return child;

    final accent = SeasonCosmeticLayers.accentForReward(style);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _PlayerCodeTracePainter(accent: accent),
                ),
                Positioned(
                  right: 14,
                  top: 72,
                  child: _CodeStylePill(reward: style, accent: accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeStylePill extends StatelessWidget {
  const _CodeStylePill({required this.reward, required this.accent});

  final SeasonReward reward;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF040914).withValues(alpha: .88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: .58)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .12),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_rounded, color: accent, size: 12),
            const SizedBox(width: 5),
            Text(
              reward.name.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 6.8,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      );
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

class _PlayerCodeTracePainter extends CustomPainter {
  const _PlayerCodeTracePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final trace = Paint()
      ..color = accent.withValues(alpha: .19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final glow = Paint()
      ..color = accent.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final left = Path()
      ..moveTo(8, 118)
      ..lineTo(24, 118)
      ..lineTo(34, 128)
      ..lineTo(34, size.height * .42)
      ..lineTo(18, size.height * .42)
      ..lineTo(8, size.height * .42 + 10);
    final right = Path()
      ..moveTo(size.width - 8, size.height * .60)
      ..lineTo(size.width - 24, size.height * .60)
      ..lineTo(size.width - 34, size.height * .60 + 10)
      ..lineTo(size.width - 34, size.height - 78)
      ..lineTo(size.width - 18, size.height - 78)
      ..lineTo(size.width - 8, size.height - 68);

    canvas
      ..drawPath(left, glow)
      ..drawPath(right, glow)
      ..drawPath(left, trace)
      ..drawPath(right, trace);

    final node = Paint()..color = accent.withValues(alpha: .68);
    for (final point in <Offset>[
      const Offset(24, 118),
      Offset(34, size.height * .42),
      Offset(size.width - 24, size.height * .60),
      Offset(size.width - 34, size.height - 78),
    ]) {
      canvas.drawCircle(point, 2.2, node);
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerCodeTracePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
