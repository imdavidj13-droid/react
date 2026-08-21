import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/season/domain/cosmetic_taxonomy.dart';

void main() {
  test('legacy S01 cosmetic kinds map to canonical families', () {
    expect(
      CosmeticTaxonomy.specFor('reaction_pack').canonicalKind,
      'gameplay_theme',
    );
    expect(
      CosmeticTaxonomy.specFor('command_style').canonicalKind,
      'command_pack',
    );
    expect(
      CosmeticTaxonomy.specFor('home_theme').canonicalKind,
      'home_background',
    );
    expect(
      CosmeticTaxonomy.specFor('share_style').canonicalKind,
      'share_card',
    );
    expect(
      CosmeticTaxonomy.specFor('success_effect').canonicalKind,
      'success_reaction',
    );
    expect(
      CosmeticTaxonomy.specFor('failure_effect').canonicalKind,
      'failure_reaction',
    );
  });

  test('canonical families land in stable Locker tabs', () {
    expect(
      CosmeticTaxonomy.tabFor('gameplay_theme'),
      CosmeticLockerTab.gameplay,
    );
    expect(
      CosmeticTaxonomy.tabFor('arena_theme'),
      CosmeticLockerTab.gameplay,
    );
    expect(
      CosmeticTaxonomy.tabFor('sound_pack'),
      CosmeticLockerTab.gameplay,
    );
    expect(
      CosmeticTaxonomy.tabFor('home_background'),
      CosmeticLockerTab.home,
    );
    expect(
      CosmeticTaxonomy.tabFor('mode_card_skin'),
      CosmeticLockerTab.home,
    );
    expect(
      CosmeticTaxonomy.tabFor('profile_frame'),
      CosmeticLockerTab.profile,
    );
    expect(
      CosmeticTaxonomy.tabFor('player_code_style'),
      CosmeticLockerTab.profile,
    );
    expect(
      CosmeticTaxonomy.tabFor('share_card'),
      CosmeticLockerTab.social,
    );
    expect(
      CosmeticTaxonomy.tabFor('result_card_style'),
      CosmeticLockerTab.social,
    );
  });

  test('every canonical family has explicit player-facing scope copy', () {
    const canonicalKinds = <String>[
      'gameplay_theme',
      'arena_theme',
      'command_pack',
      'countdown_style',
      'sound_pack',
      'success_reaction',
      'failure_reaction',
      'score_effect',
      'hud_style',
      'particle_pack',
      'home_background',
      'mode_card_skin',
      'profile_frame',
      'profile_badge',
      'title',
      'emblem',
      'player_code_style',
      'share_card',
      'result_card_style',
    ];

    for (final kind in canonicalKinds) {
      final spec = CosmeticTaxonomy.specFor(kind);
      expect(spec.canonicalKind, kind, reason: kind);
      expect(spec.label, isNotEmpty, reason: kind);
      expect(spec.effect, isNotEmpty, reason: kind);
      expect(spec.destination, isNotEmpty, reason: kind);
    }
  });
}
