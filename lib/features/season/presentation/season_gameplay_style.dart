import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/season_cosmetic_state.dart';
import '../domain/season_models.dart';
import 'season_cosmetic_layers.dart';

/// Resolved visual values for season gameplay cosmetics.
///
/// These families are deliberately independent. A full gameplay theme is still
/// owned by ReactCosmetics; arena, HUD, reactions and particles only affect
/// their named surfaces.
abstract final class SeasonGameplayStyle {
  static SeasonReward? get arenaReward =>
      SeasonCosmeticState.equippedReward('arena_theme');
  static SeasonReward? get hudReward =>
      SeasonCosmeticState.equippedReward('hud_style');
  static SeasonReward? get reactionReward =>
      SeasonCosmeticState.equippedReward('input_reaction_pack');
  static SeasonReward? get particleReward =>
      SeasonCosmeticState.equippedReward('particle_pack');

  static Color _accent(SeasonReward reward) =>
      SeasonCosmeticLayers.accentForReward(reward);

  static Color arenaSurface(Color fallback) {
    final reward = arenaReward;
    if (reward == null) return fallback;
    final accent = _accent(reward);
    final key = reward.rewardKey;
    if (key.contains('void') || key.contains('black')) {
      return Color.lerp(const Color(0xFF020408), accent, .06)!;
    }
    if (key.contains('glass') || key.contains('ion')) {
      return Color.lerp(const Color(0xFF050A13), accent, .10)!;
    }
    return Color.lerp(fallback, accent, .075)!;
  }

  static Color arenaInnerBorder(Color fallback) {
    final reward = arenaReward;
    if (reward == null) return fallback;
    return _accent(reward).withValues(alpha: .68);
  }

  static Color arenaRingBase(Color fallback) {
    final reward = arenaReward;
    if (reward == null) return fallback;
    return _accent(reward).withValues(alpha: .18);
  }

  static Color arenaTimerTrack(Color fallback) {
    final reward = arenaReward;
    if (reward == null) return fallback;
    return _accent(reward).withValues(alpha: .26);
  }

  static Color arenaPrimary(Color fallback) {
    final reward = arenaReward;
    if (reward == null) return fallback;
    return _accent(reward);
  }

  static Color arenaSecondary(Color fallback) {
    final reward = arenaReward;
    if (reward == null) return fallback;
    final accent = _accent(reward);
    return Color.lerp(accent, ReactColors.lime, .34)!;
  }

  static Color arenaFailure(Color fallback) {
    final reward = arenaReward;
    if (reward == null) return fallback;
    final accent = _accent(reward);
    return Color.lerp(accent, ReactColors.coral, .52)!;
  }

  static double get arenaRingStroke {
    final key = arenaReward?.rewardKey ?? '';
    if (key.contains('thin') || key.contains('trace')) return 6;
    if (key.contains('heavy') || key.contains('reactor')) return 11;
    return 9;
  }

  static double get arenaTimerStroke {
    final key = arenaReward?.rewardKey ?? '';
    if (key.contains('thin') || key.contains('trace')) return 8;
    if (key.contains('heavy') || key.contains('reactor')) return 14;
    return 12;
  }

  static StrokeCap get arenaStrokeCap {
    final key = arenaReward?.rewardKey ?? '';
    return key.contains('segment') || key.contains('grid')
        ? StrokeCap.butt
        : StrokeCap.round;
  }

  static Color hudPanel(Color fallback) {
    final reward = hudReward;
    if (reward == null) return fallback;
    final accent = _accent(reward);
    return Color.lerp(const Color(0xFF040911), accent, .075)!;
  }

  static Color hudBorder(Color fallback) {
    final reward = hudReward;
    if (reward == null) return fallback;
    return _accent(reward).withValues(alpha: .55);
  }

  static Color hudAccent(Color fallback) {
    final reward = hudReward;
    if (reward == null) return fallback;
    return _accent(reward);
  }

  static double get hudRadius {
    final key = hudReward?.rewardKey ?? '';
    if (key.contains('terminal') || key.contains('rail')) return 8;
    if (key.contains('soft') || key.contains('bubble')) return 24;
    return 16;
  }

  static List<BoxShadow>? get hudShadow {
    final reward = hudReward;
    if (reward == null) return null;
    final accent = _accent(reward);
    final key = reward.rewardKey;
    if (key.contains('minimal')) return null;
    return [
      BoxShadow(
        color: accent.withValues(alpha: key.contains('neon') ? .22 : .12),
        blurRadius: key.contains('neon') ? 18 : 10,
      ),
    ];
  }

  static Color reactionAccent({required bool success, required Color fallback}) {
    final reward = reactionReward;
    if (reward == null) return fallback;
    final accent = _accent(reward);
    return success
        ? Color.lerp(accent, ReactColors.lime, .18)!
        : Color.lerp(accent, ReactColors.coral, .48)!;
  }

  static int reactionParticleCount(int fallback, {required bool success}) {
    final key = reactionReward?.rewardKey ?? '';
    if (key.contains('shatter')) return fallback + (success ? 18 : 28);
    if (key.contains('pulse')) return (fallback * .55).round();
    if (key.contains('spark') || key.contains('arc')) return fallback + 12;
    return fallback;
  }

  static double reactionSpeed(double fallback) {
    final key = reactionReward?.rewardKey ?? '';
    if (key.contains('shatter')) return fallback * 1.35;
    if (key.contains('pulse')) return fallback * .72;
    if (key.contains('arc')) return fallback * 1.16;
    return fallback;
  }

  static int get reactionRingCount {
    final key = reactionReward?.rewardKey ?? '';
    if (key.contains('echo') || key.contains('pulse')) return 3;
    if (key.contains('shock') || key.contains('overload')) return 2;
    return reactionReward == null ? 1 : 2;
  }

  static Color particleAccent(Color fallback) {
    final reward = particleReward;
    if (reward == null) return fallback;
    return _accent(reward);
  }

  static int particleCount(int fallback) {
    final key = particleReward?.rewardKey ?? '';
    if (key.contains('storm') || key.contains('dense')) return fallback + 28;
    if (key.contains('minimal') || key.contains('dust')) return (fallback * .55).round();
    if (key.contains('spark') || key.contains('ion')) return fallback + 14;
    return fallback;
  }

  static double particleSpeedScale() {
    final key = particleReward?.rewardKey ?? '';
    if (key.contains('storm')) return 1.55;
    if (key.contains('drift') || key.contains('dust')) return .62;
    if (key.contains('spark')) return 1.25;
    return 1;
  }

  static double particleAlphaScale() {
    final key = particleReward?.rewardKey ?? '';
    if (key.contains('minimal')) return .55;
    if (key.contains('storm') || key.contains('neon')) return 1.35;
    return 1;
  }
}
