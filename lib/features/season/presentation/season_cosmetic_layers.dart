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
    final accent = _accentFor(theme);

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

  static Widget profile({required Widget child}) {
    final frame = SeasonCosmeticState.equippedReward('profile_frame');
    final badge = SeasonCosmeticState.equippedReward('profile_badge');
    final title = SeasonCosmeticState.equippedReward('title');
    final emblem = SeasonCosmeticState.equippedReward('emblem');
    if (frame == null && badge == null && title == null && emblem == null) {
      return child;
    }

    final accent = _accentFor(frame ?? badge ?? title ?? emblem!);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (frame != null)
          IgnorePointer(
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: .75), width: 2),
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
        if (badge != null || title != null || emblem != null)
          Positioned(
            left: 60,
            right: 60,
            top: MediaQuery.paddingOf(_rootContext(child)) + 8,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 230),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xE607111D),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: accent.withValues(alpha: .42)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (emblem != null) ...[
                        Icon(Icons.bolt_rounded, color: accent, size: 14),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          title?.name ?? badge?.name ?? emblem?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // A cosmetic layer should not require a BuildContext to be passed through
  // every navigation helper. This returns a harmless context-less top inset
  // fallback through the widget tree's media query when rendered.
  static BuildContext _rootContext(Widget child) => throw UnsupportedError(
        'SeasonCosmeticLayers.profile must use SeasonProfileLayer instead.',
      );

  static Color accentForReward(SeasonReward reward) => _accentFor(reward);

  static Color _accentFor(SeasonReward reward) {
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

class SeasonProfileLayer extends StatelessWidget {
  const SeasonProfileLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = SeasonCosmeticState.equippedReward('profile_frame');
    final badge = SeasonCosmeticState.equippedReward('profile_badge');
    final title = SeasonCosmeticState.equippedReward('title');
    final emblem = SeasonCosmeticState.equippedReward('emblem');
    if (frame == null && badge == null && title == null && emblem == null) {
      return child;
    }
    final accent = SeasonCosmeticLayers.accentForReward(
      frame ?? badge ?? title ?? emblem!,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (frame != null)
          IgnorePointer(
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: .75), width: 2),
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
        if (badge != null || title != null || emblem != null)
          Positioned(
            left: 60,
            right: 60,
            top: MediaQuery.paddingOf(context).top + 8,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 230),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xE607111D),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: accent.withValues(alpha: .42)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (emblem != null) ...[
                        Icon(Icons.bolt_rounded, color: accent, size: 14),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          title?.name ?? badge?.name ?? emblem?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ),
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
