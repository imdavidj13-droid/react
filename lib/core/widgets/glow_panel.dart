import 'package:flutter/material.dart';

import '../theme/react_colors.dart';

class GlowPanel extends StatelessWidget {
  const GlowPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.borderColor = ReactColors.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ReactColors.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.10),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
