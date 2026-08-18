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

enum ReactReactionPack {
  core,
  redline,
  synthwave,
  mono,
  greenline,
  voltage,
  ember,
  hotPink;

  String get packId => switch (this) {
    ReactReactionPack.core => 'core',
    ReactReactionPack.redline => 'redline',
    ReactReactionPack.synthwave => 'synthwave',
    ReactReactionPack.mono => 'mono',
    ReactReactionPack.greenline => 'greenline',
    ReactReactionPack.voltage => 'voltage',
    ReactReactionPack.ember => 'ember',
    ReactReactionPack.hotPink => 'hot_pink',
  };

  String get label => switch (this) {
    ReactReactionPack.core => 'RE△CT CORE',
    ReactReactionPack.redline => 'REDLINE',
    ReactReactionPack.synthwave => 'SYNTHWAVE',
    ReactReactionPack.mono => 'MONO',
    ReactReactionPack.greenline => 'GREENLINE',
    ReactReactionPack.voltage => 'VOLTAGE',
    ReactReactionPack.ember => 'EMBER',
    ReactReactionPack.hotPink => 'HOT PINK',
  };

  static ReactReactionPack? fromPackId(String? value) {
    if (value == null) return null;
    for (final pack in values) {
      if (pack.packId == value) return pack;
    }
    return null;
  }

  static ReactReactionPack fromLegacyTheme(ReactVisualTheme theme) => switch (theme) {
    ReactVisualTheme.core => ReactReactionPack.core,
    ReactVisualTheme.redline => ReactReactionPack.redline,
    ReactVisualTheme.synthwave => ReactReactionPack.synthwave,
    ReactVisualTheme.mono => ReactReactionPack.mono,
  };
}

enum ReactCountdownStyle {
  core,
  rings,
  cards,
  terminal,
  pulse;

  String get packId => switch (this) {
    ReactCountdownStyle.core => 'core_countdown',
    ReactCountdownStyle.rings => 'rings_countdown',
    ReactCountdownStyle.cards => 'cards_countdown',
    ReactCountdownStyle.terminal => 'terminal_countdown',
    ReactCountdownStyle.pulse => 'pulse_countdown',
  };

  static ReactCountdownStyle? fromPackId(String? value) {
    if (value == null) return null;
    for (final style in values) {
      if (style.packId == value) return style;
    }
    return null;
  }
}

enum ReactSoundPack {
  core,
  arcade,
  pulse,
  bass,
  minimal,
  laser;

  String get packId => switch (this) {
    ReactSoundPack.core => 'core_sfx',
    ReactSoundPack.arcade => 'arcade_sfx',
    ReactSoundPack.pulse => 'pulse_sfx',
    ReactSoundPack.bass => 'bass_sfx',
    ReactSoundPack.minimal => 'minimal_sfx',
    ReactSoundPack.laser => 'laser_sfx',
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
  glitch,
  terminal,
  arcade,
  minimal,
  impact;

  String get packId => switch (this) {
    ReactCommandStyle.core => 'core_commands',
    ReactCommandStyle.glitch => 'glitch_commands',
    ReactCommandStyle.terminal => 'terminal_commands',
    ReactCommandStyle.arcade => 'arcade_commands',
    ReactCommandStyle.minimal => 'minimal_commands',
    ReactCommandStyle.impact => 'impact_commands',
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
  static const _equippedReactionPackKey = 'shop_equipped_reaction_pack';
  static const _equippedCountdownStyleKey = 'shop_equipped_countdown_style';
  static const _equippedSoundPackKey = 'shop_equipped_sound_pack';
  static const _equippedCommandStyleKey = 'shop_equipped_command_style';
  static const _equippedShareStyleKey = 'shop_equipped_share_style';
  static const _legacyEquippedPackKey = 'shop_equipped_pack';

  static ReactVisualTheme currentTheme = ReactVisualTheme.core;
  static ReactReactionPack? _reactionPackOverride;
  static ReactCountdownStyle currentCountdownStyle = ReactCountdownStyle.core;
  static ReactSoundPack currentSoundPack = ReactSoundPack.core;
  static ReactCommandStyle currentCommandStyle = ReactCommandStyle.core;
  static ReactShareStyle currentShareStyle = ReactShareStyle.core;

  static ReactReactionPack get currentReactionPack =>
      _reactionPackOverride ?? ReactReactionPack.fromLegacyTheme(currentTheme);

  static ReactCosmeticPalette get palette => paletteForReactionPack(currentReactionPack);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedReactionPack = prefs.getString(_equippedReactionPackKey) ??
        prefs.getString(_equippedThemeKey) ??
        prefs.getString(_legacyEquippedPackKey);
    _applyReactionPackInMemory(
      ReactReactionPack.fromPackId(savedReactionPack) ?? ReactReactionPack.core,
    );

    currentCountdownStyle = ReactCountdownStyle.fromPackId(
          prefs.getString(_equippedCountdownStyleKey),
        ) ??
        ReactCountdownStyle.core;
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

  static Future<void> equipReactionPack(ReactReactionPack pack) async {
    _applyReactionPackInMemory(pack);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedReactionPackKey, pack.packId);
    await prefs.setString(_equippedThemeKey, currentTheme.packId);
    await prefs.setString(_legacyEquippedPackKey, pack.packId);
  }

  static void _applyReactionPackInMemory(ReactReactionPack pack) {
    switch (pack) {
      case ReactReactionPack.core:
        currentTheme = ReactVisualTheme.core;
        _reactionPackOverride = null;
      case ReactReactionPack.redline:
        currentTheme = ReactVisualTheme.redline;
        _reactionPackOverride = null;
      case ReactReactionPack.synthwave:
        currentTheme = ReactVisualTheme.synthwave;
        _reactionPackOverride = null;
      case ReactReactionPack.mono:
        currentTheme = ReactVisualTheme.mono;
        _reactionPackOverride = null;
      case ReactReactionPack.greenline ||
            ReactReactionPack.voltage ||
            ReactReactionPack.ember ||
            ReactReactionPack.hotPink:
        // New colour packs use the existing neutral-black gameplay surfaces.
        // Borders, timers and effects still derive from the pack palette, so
        // no Core-blue or Redline-red chrome leaks into these colourways.
        currentTheme = ReactVisualTheme.mono;
        _reactionPackOverride = pack;
    }
  }

  static Future<void> equipTheme(ReactVisualTheme theme) async {
    await equipReactionPack(ReactReactionPack.fromLegacyTheme(theme));
  }

  static Future<void> equipCountdownStyle(ReactCountdownStyle style) async {
    currentCountdownStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedCountdownStyleKey, style.packId);
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

  static ReactCosmeticPalette paletteFor(ReactVisualTheme theme) =>
      paletteForReactionPack(ReactReactionPack.fromLegacyTheme(theme));

  static ReactCosmeticPalette paletteForReactionPack(ReactReactionPack pack) => switch (pack) {
    ReactReactionPack.core => const ReactCosmeticPalette(
        background: ReactColors.background,
        primary: ReactColors.electricBlueBright,
        secondary: ReactColors.lime,
        failure: ReactColors.coral,
        effectIntensityScale: 1,
      ),
    ReactReactionPack.redline => const ReactCosmeticPalette(
        background: Color(0xFF100507),
        primary: Color(0xFFFF4D5A),
        secondary: Color(0xFFFF9B45),
        failure: Color(0xFFFF2738),
        effectIntensityScale: 1.12,
      ),
    ReactReactionPack.synthwave => const ReactCosmeticPalette(
        background: Color(0xFF09051A),
        primary: Color(0xFFA66CFF),
        secondary: Color(0xFF47D7FF),
        failure: Color(0xFFFF557E),
        effectIntensityScale: 1.05,
      ),
    ReactReactionPack.mono => const ReactCosmeticPalette(
        background: Color(0xFF030303),
        primary: Color(0xFFF4F4F4),
        secondary: Color(0xFF9A9A9A),
        failure: Color(0xFFD8D8D8),
        effectIntensityScale: .58,
      ),
    ReactReactionPack.greenline => const ReactCosmeticPalette(
        background: Color(0xFF031008),
        primary: Color(0xFF35F06F),
        secondary: Color(0xFFB7FF55),
        failure: Color(0xFFFF5B5B),
        effectIntensityScale: 1.08,
      ),
    ReactReactionPack.voltage => const ReactCosmeticPalette(
        background: Color(0xFF100E02),
        primary: Color(0xFFFFE14A),
        secondary: Color(0xFFFFB52E),
        failure: Color(0xFFFF5A45),
        effectIntensityScale: 1.10,
      ),
    ReactReactionPack.ember => const ReactCosmeticPalette(
        background: Color(0xFF120702),
        primary: Color(0xFFFF7A32),
        secondary: Color(0xFFFFC34A),
        failure: Color(0xFFFF3D35),
        effectIntensityScale: 1.12,
      ),
    ReactReactionPack.hotPink => const ReactCosmeticPalette(
        background: Color(0xFF12030E),
        primary: Color(0xFFFF4DB8),
        secondary: Color(0xFFFF8FDF),
        failure: Color(0xFFFF4761),
        effectIntensityScale: 1.08,
      ),
  };

  static Color effectAccentFor(Color modeAccent) {
    if (currentReactionPack == ReactReactionPack.core) return modeAccent;
    final current = palette;

    if (modeAccent == ReactColors.coral) return current.failure;
    if (modeAccent == ReactColors.lime) return current.secondary;
    if (modeAccent == ReactColors.purple &&
        currentReactionPack == ReactReactionPack.synthwave) {
      return current.primary;
    }
    return current.primary;
  }
}
