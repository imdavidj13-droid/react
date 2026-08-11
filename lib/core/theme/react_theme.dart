import 'package:flutter/material.dart';

import 'react_colors.dart';

abstract final class ReactTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: ReactColors.electricBlue,
      brightness: Brightness.dark,
      surface: ReactColors.panel,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ReactColors.background,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: ReactColors.textPrimary,
          fontSize: 46,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.8,
          height: 0.95,
        ),
        headlineMedium: TextStyle(
          color: ReactColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: TextStyle(
          color: ReactColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
