import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/react_colors.dart';

enum ReactVisualTheme {
  core,
  redline,
  synthwave,
  mono;

  String get packId => switch (this) {
    ReactVisualTheme.core => 'core',
    ReactVisualTheme.redline => 'redline',
    ReactVisualTheme.synthwave => 'synthwave',
    ReactVisualTheme.mono => 'mono',
  };

  String get label => switch (this) {
    ReactVisualTheme.core => 'RE△CT CORE',
    ReactVisualTheme.redline => 'REDLINE',
    ReactVisualTheme.synthwave => 'SYNTHWAVE',
    ReactVisualTheme.mono => 'MONO',
  };

  static ReactVisualTheme? fromPackId(String? value) {
    if (value == null) return null;
    for (final theme in values) {
      if (theme.packId == value) return theme;
    }
    return null;
  }
}

enum ReactSoundPack {
  core,
  arcade;

  String get packId => switch (this) {
    ReactSoundPack.core => 'core_sfx',
    ReactSoundPack.arcade => 'arcade_sfx',
  };

  static ReactSoundPack? fromPackId(String? value) {
    if (value == null) return null;
    for (final pack in values) {
      if (pack.packId == value) return pack;
    }
    return null;
  }
}

enum ReactCommandStyle {
  core,
  glitch;

  String get packId => switch (this) {
    ReactCommandStyle.core => 'core_commands',
    ReactCommandStyle.glitch => 'glitch_commands',
  };

  static ReactCommandStyle? fromPackId(String? value) {
    if (value == null) return null;
    for (final style in values) {
      if (style.packId == value) return style;
    }
    return null;
  }
}

enum ReactShareStyle {
  core,
  pro;

  String get packId => switch (this) {
    ReactShareStyle.core => 'core_share_cards',
    ReactShareStyle.pro => 'pro_share_cards',
  };

  static ReactShareStyle? fromPackId(String? value) {
    if (value == null) return null;
    for (final style in values) {
      if (style.packId == value) return style;
    }
    return null;
  }
}

class ReactCosmeticPalette {
  const ReactCosmeticPalette({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.failure,
    required this.effectIntensityScale,
  });

  final Color background;
  final Color primary;
  final Color secondary;
  final Color failure;
  final double effectIntensityScale;
}

abstract final class ReactCosmetics {
  static const _equippedThemeKey = 'shop_equipped_theme';
  static const _equippedSoundPackKey = 'shop_equipped_sound_pack';
  static const _equippedCommandStyleKey = 'shop_equipped_command_style';
  static const _equippedShareStyleKey = 'shop_equipped_share_style';
  static const _legacyEquippedPackKey = 'shop_equipped_pack';

  static ReactVisualTheme currentTheme = ReactVisualTheme.core;
  static ReactSoundPack currentSoundPack = ReactSoundPack.core;
  static ReactCommandStyle currentCommandStyle = ReactCommandStyle.core;
  static ReactShareStyle currentShareStyle = ReactShareStyle.core;

  static ReactCosmeticPalette get palette => paletteFor(currentTheme);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_equippedThemeKey) ??
        prefs.getString(_legacyEquippedPackKey);
    currentTheme =
        ReactVisualTheme.fromPackId(savedTheme) ?? ReactVisualTheme.core;
    currentSoundPack = ReactSoundPack.fromPackId(
          prefs.getString(_equippedSoundPackKey),
        ) ??
        ReactSoundPack.core;
    currentCommandStyle = ReactCommandStyle.fromPackId(
          prefs.getString(_equippedCommandStyleKey),
        ) ??
        ReactCommandStyle.core;
    currentShareStyle = ReactShareStyle.fromPackId(
          prefs.getString(_equippedShareStyleKey),
        ) ??
        ReactShareStyle.core;
  }

  static Future<void> equipTheme(ReactVisualTheme theme) async {
    currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedThemeKey, theme.packId);
    await prefs.setString(_legacyEquippedPackKey, theme.packId);
  }

  static Future<void> equipSoundPack(ReactSoundPack pack) async {
    currentSoundPack = pack;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedSoundPackKey, pack.packId);
  }

  static Future<void> equipCommandStyle(ReactCommandStyle style) async {
    currentCommandStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedCommandStyleKey, style.packId);
  }

  static Future<void> equipShareStyle(ReactShareStyle style) async {
    currentShareStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedShareStyleKey, style.packId);
  }

  static ReactCosmeticPalette paletteFor(ReactVisualTheme theme) => switch (theme) {
    ReactVisualTheme.core => const ReactCosmeticPalette(
        background: ReactColors.background,
        primary: ReactColors.electricBlueBright,
        secondary: ReactColors.lime,
        failure: ReactColors.coral,
        effectIntensityScale: 1,
      ),
    ReactVisualTheme.redline => const ReactCosmeticPalette(
        background: Color(0xFF100507),
        primary: Color(0xFFFF4D5A),
        secondary: Color(0xFFFF9B45),
        failure: Color(0xFFFF2738),
        effectIntensityScale: 1.12,
      ),
    ReactVisualTheme.synthwave => const ReactCosmeticPalette(
        background: Color(0xFF09051A),
        primary: Color(0xFFA66CFF),
        secondary: Color(0xFF47D7FF),
        failure: Color(0xFFFF557E),
        effectIntensityScale: 1.05,
      ),
    ReactVisualTheme.mono => const ReactCosmeticPalette(
        background: Color(0xFF030303),
        primary: Color(0xFFF4F4F4),
        secondary: Color(0xFF9A9A9A),
        failure: Color(0xFFD8D8D8),
        effectIntensityScale: .58,
      ),
  };

  static Color effectAccentFor(Color modeAccent) {
    if (currentTheme == ReactVisualTheme.core) return modeAccent;
    final current = palette;

    if (modeAccent == ReactColors.coral) return current.failure;
    if (modeAccent == ReactColors.lime) return current.secondary;
    if (modeAccent == ReactColors.purple &&
        currentTheme == ReactVisualTheme.synthwave) {
      return current.primary;
    }
    return current.primary;
  }
}
