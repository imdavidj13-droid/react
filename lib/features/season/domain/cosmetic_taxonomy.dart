import 'package:flutter/material.dart';

enum CosmeticLockerTab {
  all,
  gameplay,
  home,
  profile,
  social;

  String get label => switch (this) {
        CosmeticLockerTab.all => 'ALL',
        CosmeticLockerTab.gameplay => 'GAMEPLAY',
        CosmeticLockerTab.home => 'HOME',
        CosmeticLockerTab.profile => 'PROFILE',
        CosmeticLockerTab.social => 'SOCIAL',
      };
}

class CosmeticKindSpec {
  const CosmeticKindSpec({
    required this.canonicalKind,
    required this.label,
    required this.tab,
    required this.icon,
    required this.effect,
    required this.destination,
  });

  final String canonicalKind;
  final String label;
  final CosmeticLockerTab tab;
  final IconData icon;
  final String effect;
  final String destination;
}

abstract final class CosmeticTaxonomy {
  static const gameplayTheme = CosmeticKindSpec(
    canonicalKind: 'gameplay_theme',
    label: 'FULL GAMEPLAY THEME',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.palette_outlined,
    effect: 'Rethemes the complete run presentation: background, HUD accents, arena surfaces, timer colours and feedback palette.',
    destination: 'Across gameplay modes during a run.',
  );

  static const arenaTheme = CosmeticKindSpec(
    canonicalKind: 'arena_theme',
    label: 'ARENA / CIRCLE THEME',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.radio_button_checked_rounded,
    effect: 'Restyles only the central arena, circle, ring and timer track without changing the whole game theme.',
    destination: 'The gameplay command arena and timer ring.',
  );

  static const commandPack = CosmeticKindSpec(
    canonicalKind: 'command_pack',
    label: 'COMMAND TEXT PACK',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.text_fields_rounded,
    effect: 'Changes command wording and text format while leaving timing and rules unchanged.',
    destination: 'Command words and hints in gesture-based gameplay modes.',
  );

  static const countdownStyle = CosmeticKindSpec(
    canonicalKind: 'countdown_style',
    label: 'COUNTDOWN SCREEN',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.timer_outlined,
    effect: 'Changes the complete visual 3–2–1–GO launch presentation.',
    destination: 'The pre-run countdown screen.',
  );

  static const soundPack = CosmeticKindSpec(
    canonicalKind: 'sound_pack',
    label: 'SOUND EFFECT PACK',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.graphic_eq_rounded,
    effect: 'Changes countdown, command, success, miss, warning, handoff and completion sound cues.',
    destination: 'Gameplay and pre-run sound effects.',
  );

  /// Reserved for a genuine in-run reaction renderer. Do not award this family
  /// until the input-success/miss surfaces consume it in every gameplay mode.
  static const reactionPack = CosmeticKindSpec(
    canonicalKind: 'input_reaction_pack',
    label: 'REACTION PACK',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.burst_mode_outlined,
    effect: 'Changes the visual burst/shockwave treatment after successful and failed inputs.',
    destination: 'Immediately after inputs during gameplay.',
  );

  static const hudStyle = CosmeticKindSpec(
    canonicalKind: 'hud_style',
    label: 'HUD STYLE',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.dashboard_customize_outlined,
    effect: 'Restyles score, lives, timer and mode HUD cards without changing the arena.',
    destination: 'The gameplay HUD.',
  );

  static const particlePack = CosmeticKindSpec(
    canonicalKind: 'particle_pack',
    label: 'PARTICLE PACK',
    tab: CosmeticLockerTab.gameplay,
    icon: Icons.auto_awesome_rounded,
    effect: 'Changes ambient gameplay particles independently from the full gameplay theme.',
    destination: 'Behind gameplay surfaces during a run.',
  );

  static const homeBackground = CosmeticKindSpec(
    canonicalKind: 'home_background',
    label: 'HOME BACKGROUND',
    tab: CosmeticLockerTab.home,
    icon: Icons.home_outlined,
    effect: 'Changes or animates the background behind the Home screen only.',
    destination: 'Behind the Home screen.',
  );

  static const modeCardSkin = CosmeticKindSpec(
    canonicalKind: 'mode_card_skin',
    label: 'MODE CARD SKIN',
    tab: CosmeticLockerTab.home,
    icon: Icons.view_module_outlined,
    effect: 'Restyles cards in the Modes catalogue.',
    destination: 'Mode cards on the Modes screen.',
  );

  static const profileFrame = CosmeticKindSpec(
    canonicalKind: 'profile_frame',
    label: 'PROFILE SCREEN FRAME',
    tab: CosmeticLockerTab.profile,
    icon: Icons.crop_square_rounded,
    effect: 'Adds a decorative frame around the Player Profile screen.',
    destination: 'Around the outer edge of Player Profile.',
  );

  static const profileBadge = CosmeticKindSpec(
    canonicalKind: 'profile_badge',
    label: 'PROFILE BADGE',
    tab: CosmeticLockerTab.profile,
    icon: Icons.workspace_premium_outlined,
    effect: 'Adds a named badge to the player identity card.',
    destination: 'Under the avatar on Player Profile.',
  );

  static const title = CosmeticKindSpec(
    canonicalKind: 'title',
    label: 'PLAYER TITLE',
    tab: CosmeticLockerTab.profile,
    icon: Icons.title_rounded,
    effect: 'Adds an equippable title beneath the display name.',
    destination: 'Below the player name on Player Profile.',
  );

  static const emblem = CosmeticKindSpec(
    canonicalKind: 'emblem',
    label: 'PLAYER EMBLEM',
    tab: CosmeticLockerTab.profile,
    icon: Icons.bolt_rounded,
    effect: 'Adds an equippable emblem to the player identity.',
    destination: 'Beside the RX player code on Player Profile.',
  );

  static const playerCodeStyle = CosmeticKindSpec(
    canonicalKind: 'player_code_style',
    label: 'PLAYER CODE STYLE',
    tab: CosmeticLockerTab.profile,
    icon: Icons.badge_outlined,
    effect: 'Restyles only the RX player-code container and text.',
    destination: 'The RX player code on Player Profile.',
  );

  static const shareCard = CosmeticKindSpec(
    canonicalKind: 'share_card',
    label: 'SHARE CARD',
    tab: CosmeticLockerTab.social,
    icon: Icons.ios_share_rounded,
    effect: 'Changes the exported result share-card design.',
    destination: 'The result sharing screen and exported image.',
  );

  static const resultScoreStyle = CosmeticKindSpec(
    canonicalKind: 'result_score_style',
    label: 'RESULT SCORE STYLE',
    tab: CosmeticLockerTab.social,
    icon: Icons.auto_graph_rounded,
    effect: 'Restyles the final-score presentation after a run.',
    destination: 'The final score on Results.',
  );

  static const resultSuccessStyle = CosmeticKindSpec(
    canonicalKind: 'result_success_style',
    label: 'RESULT SUCCESS STYLE',
    tab: CosmeticLockerTab.social,
    icon: Icons.check_circle_outline_rounded,
    effect: 'Restyles the successful/completed outcome treatment after a run.',
    destination: 'Successful outcome presentation on Results.',
  );

  static const resultFailureStyle = CosmeticKindSpec(
    canonicalKind: 'result_failure_style',
    label: 'RESULT FAILURE STYLE',
    tab: CosmeticLockerTab.social,
    icon: Icons.flash_off_rounded,
    effect: 'Restyles the miss/failure outcome treatment after a run.',
    destination: 'Failed outcome presentation on Results.',
  );

  static const resultCardStyle = CosmeticKindSpec(
    canonicalKind: 'result_card_style',
    label: 'RESULT CARD STYLE',
    tab: CosmeticLockerTab.social,
    icon: Icons.style_outlined,
    effect: 'Restyles the normal in-app Results presentation independently from share cards.',
    destination: 'The Results screen after a run.',
  );

  /// Maps S01 legacy/backend kinds into the canonical player-facing taxonomy.
  /// The mapping describes what the renderer ACTUALLY does today.
  static CosmeticKindSpec specFor(String kind) => switch (kind) {
        'reaction_pack' || 'gameplay_theme' => gameplayTheme,
        'arena_theme' => arenaTheme,
        'command_style' || 'command_pack' => commandPack,
        'countdown_style' => countdownStyle,
        'sound_pack' => soundPack,
        'input_reaction_pack' || 'success_reaction' || 'failure_reaction' => reactionPack,
        'hud_style' => hudStyle,
        'particle_pack' => particlePack,
        'home_theme' || 'home_background' => homeBackground,
        'mode_card_skin' => modeCardSkin,
        'profile_frame' => profileFrame,
        'profile_badge' => profileBadge,
        'title' => title,
        'emblem' => emblem,
        'player_code_style' => playerCodeStyle,
        'share_style' || 'share_card' => shareCard,
        'score_effect' || 'result_score_style' => resultScoreStyle,
        'success_effect' || 'result_success_style' => resultSuccessStyle,
        'failure_effect' || 'result_failure_style' => resultFailureStyle,
        'result_card_style' => resultCardStyle,
        _ => CosmeticKindSpec(
            canonicalKind: kind,
            label: kind.replaceAll('_', ' ').toUpperCase(),
            tab: CosmeticLockerTab.all,
            icon: Icons.redeem_outlined,
            effect: 'Cosmetic presentation.',
            destination: 'Its connected cosmetic surface.',
          ),
      };

  static CosmeticLockerTab tabFor(String kind) => specFor(kind).tab;
}
