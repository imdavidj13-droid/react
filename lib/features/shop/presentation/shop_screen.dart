import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/local_shop_state.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _corePack = _ShopPack(
    id: LocalShopState.corePackId,
    title: 'RE△CT CORE',
    subtitle: 'The original electric-blue RE△CT gameplay presentation.',
    category: 'BUILT IN',
    slot: _PackSlot.reaction,
    price: 'OWNED',
    accent: ReactColors.electricBlueBright,
    icon: Icons.bolt_rounded,
    includes: [
      'Original electric-blue arena',
      'Core countdown presentation',
      'Standard RE△CT gameplay palette',
    ],
  );

  static const _packs = <_ShopPack>[
    _ShopPack(
      id: LocalShopState.redlinePackId,
      title: 'REDLINE',
      subtitle: 'Aggressive red arena, harder-edged glow and matching effects.',
      category: 'REACTION PACK',
      slot: _PackSlot.reaction,
      price: '£1.99',
      accent: ReactColors.coral,
      icon: Icons.local_fire_department_rounded,
      includes: [
        'Redline arena palette',
        'Matching timer and success effects',
        'Hard-edged gameplay presentation',
      ],
    ),
    _ShopPack(
      id: LocalShopState.synthwavePackId,
      title: 'SYNTHWAVE',
      subtitle: 'Purple-blue retro neon treatment for every gameplay mode.',
      category: 'REACTION PACK',
      slot: _PackSlot.reaction,
      price: '£1.99',
      accent: ReactColors.purple,
      icon: Icons.waves_rounded,
      includes: [
        'Purple-blue neon arena',
        'Retro gameplay effects',
        'Synthwave colour treatment',
      ],
    ),
    _ShopPack(
      id: LocalShopState.monoPackId,
      title: 'MONO',
      subtitle: 'Black-and-white competitive visuals with reduced effects.',
      category: 'REACTION PACK',
      slot: _PackSlot.reaction,
      price: '£0.99',
      accent: ReactColors.textPrimary,
      icon: Icons.contrast_rounded,
      includes: [
        'Monochrome arena palette',
        'Reduced effect intensity',
        'Minimal competitive presentation',
      ],
    ),
    _ShopPack(
      id: LocalShopState.greenlinePackId,
      title: 'GREENLINE',
      subtitle: 'Electric green gameplay with lime highlights and dark emerald space.',
      category: 'REACTION PACK',
      slot: _PackSlot.reaction,
      price: '£1.49',
      accent: Color(0xFF35F06F),
      icon: Icons.eco_rounded,
      includes: [
        'Electric green arena accents',
        'Lime success treatment',
        'Green-tinted gameplay background',
      ],
    ),
    _ShopPack(
      id: LocalShopState.voltagePackId,
      title: 'VOLTAGE',
      subtitle: 'Bright yellow reaction visuals with warm amber secondary effects.',
      category: 'REACTION PACK',
      slot: _PackSlot.reaction,
      price: '£1.49',
      accent: Color(0xFFFFE14A),
      icon: Icons.electric_bolt_rounded,
      includes: [
        'High-visibility yellow arena',
        'Amber success effects',
        'Dark gold gameplay background',
      ],
    ),
    _ShopPack(
      id: LocalShopState.emberPackId,
      title: 'EMBER',
      subtitle: 'Orange heat treatment with fire-bright timers and success effects.',
      category: 'REACTION PACK',
      slot: _PackSlot.reaction,
      price: '£1.49',
      accent: Color(0xFFFF7A32),
      icon: Icons.whatshot_rounded,
      includes: [
        'Orange arena palette',
        'Warm gold success effects',
        'Dark ember gameplay background',
      ],
    ),
    _ShopPack(
      id: LocalShopState.hotPinkPackId,
      title: 'HOT PINK',
      subtitle: 'Saturated pink gameplay with bright rose highlights.',
      category: 'REACTION PACK',
      slot: _PackSlot.reaction,
      price: '£1.49',
      accent: Color(0xFFFF4DB8),
      icon: Icons.favorite_rounded,
      includes: [
        'Hot-pink arena accents',
        'Rose success treatment',
        'Deep pink gameplay background',
      ],
    ),
    _ShopPack(
      id: LocalShopState.ringsCountdownPackId,
      title: 'RINGS COUNTDOWN',
      subtitle: 'A circular progress countdown built around the active number.',
      category: 'COUNTDOWN STYLE',
      slot: _PackSlot.countdown,
      price: '£0.79',
      accent: ReactColors.electricBlueBright,
      icon: Icons.radio_button_checked_rounded,
      includes: [
        'Circular progress ring',
        'Layered inner countdown ring',
        'Uses your equipped Reaction Pack colours',
      ],
    ),
    _ShopPack(
      id: LocalShopState.cardsCountdownPackId,
      title: 'CARDS COUNTDOWN',
      subtitle: 'Large framed number cards with three segmented progress bars.',
      category: 'COUNTDOWN STYLE',
      slot: _PackSlot.countdown,
      price: '£0.79',
      accent: ReactColors.lime,
      icon: Icons.view_agenda_rounded,
      includes: [
        'Framed countdown card',
        'Three-step segmented progress',
        'Reaction Pack colour matching',
      ],
    ),
    _ShopPack(
      id: LocalShopState.terminalCountdownPackId,
      title: 'TERMINAL COUNTDOWN',
      subtitle: 'System-console countdown with command-line status presentation.',
      category: 'COUNTDOWN STYLE',
      slot: _PackSlot.countdown,
      price: '£0.79',
      accent: Color(0xFF58FF9A),
      icon: Icons.terminal_rounded,
      includes: [
        'Command-line countdown labels',
        'System armed status',
        'Compact terminal progress line',
      ],
    ),
    _ShopPack(
      id: LocalShopState.pulseCountdownPackId,
      title: 'PULSE COUNTDOWN',
      subtitle: 'Concentric pulse rings that intensify into the GO state.',
      category: 'COUNTDOWN STYLE',
      slot: _PackSlot.countdown,
      price: '£0.79',
      accent: Color(0xFFA66CFF),
      icon: Icons.radar_rounded,
      includes: [
        'Concentric pulse rings',
        'GO-state glow expansion',
        'Reaction Pack colour matching',
      ],
    ),
    _ShopPack(
      id: LocalShopState.arcadeSfxPackId,
      title: 'ARCADE SFX',
      subtitle: 'Brighter stepped bleeps for countdowns, success and misses.',
      category: 'AUDIO PACK',
      slot: _PackSlot.audio,
      price: '£0.99',
      accent: ReactColors.lime,
      icon: Icons.sports_esports_rounded,
      includes: [
        'Alternate countdown cues',
        'Arcade success and miss sounds',
        'Alternate completion and warning cues',
      ],
    ),
    _ShopPack(
      id: LocalShopState.pulseSfxPackId,
      title: 'PULSE SFX',
      subtitle: 'Tight two-hit electronic pulses with a clean rhythmic identity.',
      category: 'AUDIO PACK',
      slot: _PackSlot.audio,
      price: '£0.99',
      accent: Color(0xFF47D7FF),
      icon: Icons.multiline_chart_rounded,
      includes: [
        'Electronic pulse command cues',
        'Layered success tones',
        'Pulse-style handoff and completion audio',
      ],
    ),
    _ShopPack(
      id: LocalShopState.bassSfxPackId,
      title: 'BASS SFX',
      subtitle: 'Lower, heavier game feedback with short punchy envelopes.',
      category: 'AUDIO PACK',
      slot: _PackSlot.audio,
      price: '£0.99',
      accent: Color(0xFFFF7A32),
      icon: Icons.surround_sound_rounded,
      includes: [
        'Low command thumps',
        'Weighty miss and life-loss tones',
        'Bass completion sequence',
      ],
    ),
    _ShopPack(
      id: LocalShopState.minimalSfxPackId,
      title: 'MINIMAL SFX',
      subtitle: 'Sparse single-note feedback for a cleaner competitive soundscape.',
      category: 'AUDIO PACK',
      slot: _PackSlot.audio,
      price: '£0.99',
      accent: ReactColors.textPrimary,
      icon: Icons.volume_down_rounded,
      includes: [
        'Single-note command feedback',
        'Reduced sonic clutter',
        'Minimal countdown and completion cues',
      ],
    ),
    _ShopPack(
      id: LocalShopState.laserSfxPackId,
      title: 'LASER SFX',
      subtitle: 'Fast high-frequency stepped tones with a sharper sci-fi edge.',
      category: 'AUDIO PACK',
      slot: _PackSlot.audio,
      price: '£0.99',
      accent: Color(0xFFFF4DB8),
      icon: Icons.flash_on_rounded,
      includes: [
        'High-frequency command chirps',
        'Laser-style success climb',
        'Sharp warning and completion cues',
      ],
    ),
    _ShopPack(
      id: LocalShopState.glitchCommandsPackId,
      title: 'GLITCH COMMANDS',
      subtitle: 'Digital command treatment while keeping the original wording.',
      category: 'COMMAND TEXT',
      slot: _PackSlot.text,
      price: '£0.99',
      accent: ReactColors.electricBlueBright,
      icon: Icons.broken_image_outlined,
      includes: [
        'Glitch command presentation',
        'System-coded command hints',
        'Original command wording retained',
      ],
    ),
    _ShopPack(
      id: LocalShopState.terminalCommandsPackId,
      title: 'TERMINAL COMMANDS',
      subtitle: 'Command-line syntax for every gesture instruction.',
      category: 'COMMAND TEXT',
      slot: _PackSlot.text,
      price: '£0.79',
      accent: Color(0xFF58FF9A),
      icon: Icons.code_rounded,
      includes: [
        'Prompt-prefixed command titles',
        'Underscore terminal syntax',
        'Gameplay timing unchanged',
      ],
    ),
    _ShopPack(
      id: LocalShopState.arcadeCommandsPackId,
      title: 'ARCADE COMMANDS',
      subtitle: 'Loud arcade-style labels and READY prompts.',
      category: 'COMMAND TEXT',
      slot: _PackSlot.text,
      price: '£0.79',
      accent: ReactColors.lime,
      icon: Icons.stars_rounded,
      includes: [
        'Star-framed command titles',
        'READY instruction prompts',
        'Gameplay timing unchanged',
      ],
    ),
    _ShopPack(
      id: LocalShopState.minimalCommandsPackId,
      title: 'MINIMAL COMMANDS',
      subtitle: 'Shorter instruction labels designed for maximum visual clarity.',
      category: 'COMMAND TEXT',
      slot: _PackSlot.text,
      price: '£0.79',
      accent: ReactColors.textPrimary,
      icon: Icons.horizontal_rule_rounded,
      includes: [
        'Short command titles',
        'Condensed instruction hints',
        'Gesture meaning unchanged',
      ],
    ),
    _ShopPack(
      id: LocalShopState.impactCommandsPackId,
      title: 'IMPACT COMMANDS',
      subtitle: 'Urgent command labels with NOW prompts and harder punctuation.',
      category: 'COMMAND TEXT',
      slot: _PackSlot.text,
      price: '£0.79',
      accent: ReactColors.coral,
      icon: Icons.priority_high_rounded,
      includes: [
        'High-impact command labels',
        'NOW instruction prompts',
        'Gameplay timing unchanged',
      ],
    ),
    _ShopPack(
      id: LocalShopState.proShareCardsPackId,
      title: 'PRO SHARE CARDS',
      subtitle: 'Premium score-first layouts for sharing runs and Daily scores.',
      category: 'SHARE CARD',
      slot: _PackSlot.share,
      price: '£0.99',
      accent: ReactColors.purple,
      icon: Icons.ios_share_rounded,
      includes: [
        'Premium score-first result layout',
        'Dedicated Daily rule treatment',
        'Competitive metrics and premium framing',
      ],
    ),
  ];

  static const _featuredPackId = LocalShopState.redlinePackId;
  late Future<Set<String>> _equippedPackIds;
  _ShopFilter _filter = _ShopFilter.all;

  _ShopPack get _featured =>
      _packs.firstWhere((pack) => pack.id == _featuredPackId);

  @override
  void initState() {
    super.initState();
    _equippedPackIds = LocalShopState.equippedPackIds();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _equippedPackIds = LocalShopState.equippedPackIds();
    });
  }

  Future<void> _equip(_ShopPack pack) async {
    await LocalShopState.equip(pack.id);
    _refresh();
  }

  Future<void> _restoreSlot(_ShopPack pack) async {
    switch (pack.slot) {
      case _PackSlot.reaction:
        await LocalShopState.equipCoreReactionPack();
      case _PackSlot.countdown:
        await LocalShopState.equipCoreCountdown();
      case _PackSlot.audio:
        await LocalShopState.equipCoreAudio();
      case _PackSlot.text:
        await LocalShopState.equipCoreCommandStyle();
      case _PackSlot.share:
        await LocalShopState.equipCoreShareStyle();
    }
    _refresh();
  }

  String _restoreLabel(_ShopPack pack) => switch (pack.slot) {
        _PackSlot.reaction => 'USE RE△CT CORE',
        _PackSlot.countdown => 'USE CORE COUNTDOWN',
        _PackSlot.audio => 'USE CORE SFX',
        _PackSlot.text => 'USE CORE COMMANDS',
        _PackSlot.share => 'USE CORE SHARE CARD',
      };

  Future<void> _showPack(_ShopPack pack) async {
    final equipped = (await LocalShopState.equippedPackIds()).contains(pack.id);
    final owned = LocalShopState.isOwned(pack.id);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PackSheet(
        pack: pack,
        owned: owned,
        equipped: equipped,
        actionLabel: equipped
            ? _restoreLabel(pack)
            : owned
                ? 'EQUIP'
                : 'COMING SOON',
        onAction: !owned
            ? null
            : equipped
                ? () => _restoreSlot(pack)
                : () => _equip(pack),
      ),
    );
  }

  List<_ShopPack> _forFilter(_ShopFilter filter) {
    if (filter == _ShopFilter.all) {
      return _packs.where((pack) => pack.id != _featuredPackId).toList();
    }
    if (filter == _ShopFilter.packs || filter == _ShopFilter.themes) {
      return _packs
          .where((pack) =>
              pack.slot == _PackSlot.reaction && pack.id != _featuredPackId)
          .toList();
    }
    if (filter == _ShopFilter.countdown) {
      return _packs.where((pack) => pack.slot == _PackSlot.countdown).toList();
    }
    if (filter == _ShopFilter.audio) {
      return _packs.where((pack) => pack.slot == _PackSlot.audio).toList();
    }
    return _packs
        .where((pack) =>
            pack.slot == _PackSlot.text || pack.slot == _PackSlot.share)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 360 ? 14.0 : 20.0;

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<Set<String>>(
          future: _equippedPackIds,
          builder: (context, snapshot) {
            final equipped = snapshot.data ?? {LocalShopState.corePackId};
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 28),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(onBack: () => Navigator.of(context).pop()),
                        const SizedBox(height: 16),
                        const _HeroCard(),
                        if (LocalShopState.debugUnlocksEnabled) ...[
                          const SizedBox(height: 12),
                          const _DevCard(),
                        ],
                        const SizedBox(height: 18),
                        const _SectionLabel('YOUR REACTION PACK'),
                        const SizedBox(height: 10),
                        _PackCard(
                          pack: _corePack,
                          owned: true,
                          equipped: equipped.contains(_corePack.id),
                          onTap: () => _showPack(_corePack),
                        ),
                        const SizedBox(height: 18),
                        const _SectionLabel('FEATURED'),
                        const SizedBox(height: 10),
                        _FeaturedCard(
                          key: const ValueKey('featured_redline'),
                          pack: _featured,
                          owned: LocalShopState.isOwned(_featured.id),
                          equipped: equipped.contains(_featured.id),
                          onTap: () => _showPack(_featured),
                        ),
                        const SizedBox(height: 18),
                        _Filters(
                          selected: _filter,
                          onSelected: (filter) => setState(() => _filter = filter),
                        ),
                        const SizedBox(height: 18),
                        if (_filter == _ShopFilter.all)
                          ..._buildSections(equipped)
                        else ...[
                          _SectionLabel(_filter.sectionLabel),
                          const SizedBox(height: 10),
                          ..._packCards(_forFilter(_filter), equipped),
                        ],
                        const SizedBox(height: 20),
                        const _FairPlayCard(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSections(Set<String> equipped) {
    final sections = <(_PackSlot, String)>[
      (_PackSlot.reaction, 'REACTION PACKS'),
      (_PackSlot.countdown, 'COUNTDOWN STYLES'),
      (_PackSlot.audio, 'AUDIO PACKS'),
      (_PackSlot.text, 'COMMAND TEXT STYLES'),
      (_PackSlot.share, 'SHARE CARDS'),
    ];

    return [
      for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) ...[
        _SectionLabel(sections[sectionIndex].$2),
        const SizedBox(height: 10),
        ..._packCards(
          _packs
              .where((pack) =>
                  pack.slot == sections[sectionIndex].$1 &&
                  pack.id != _featuredPackId)
              .toList(),
          equipped,
        ),
        if (sectionIndex != sections.length - 1) const SizedBox(height: 20),
      ],
    ];
  }

  List<Widget> _packCards(List<_ShopPack> packs, Set<String> equipped) => [
        for (var index = 0; index < packs.length; index++) ...[
          _PackCard(
            pack: packs[index],
            owned: LocalShopState.isOwned(packs[index].id),
            equipped: equipped.contains(packs[index].id),
            onTap: () => _showPack(packs[index]),
          ),
          if (index != packs.length - 1) const SizedBox(height: 10),
        ],
      ];
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: ReactColors.panel,
              foregroundColor: ReactColors.textPrimary,
              side: const BorderSide(color: ReactColors.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          const Text(
            'SHOP',
            style: TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
        ],
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ReactColors.panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ReactColors.electricBlue.withValues(alpha: .45),
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MAKE RE△CT YOURS',
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'MIX REACTION PACKS, COUNTDOWNS, AUDIO AND COMMAND TEXT.',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      );
}

class _DevCard extends StatelessWidget {
  const _DevCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ReactColors.purple.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ReactColors.purple.withValues(alpha: .42)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.developer_mode_rounded,
              color: ReactColors.purple,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'DEV • IMPLEMENTED COSMETICS UNLOCKED',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      );
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  final _ShopPack pack;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ReactColors.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: equipped
                    ? pack.accent.withValues(alpha: .75)
                    : ReactColors.border,
              ),
            ),
            child: Row(
              children: [
                _PackIcon(pack: pack),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pack.subtitle,
                        style: const TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _StatusPill(
                        label: equipped
                            ? 'EQUIPPED'
                            : owned
                                ? 'OWNED'
                                : 'LOCKED',
                        color: equipped
                            ? ReactColors.lime
                            : owned
                                ? pack.accent
                                : ReactColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ReactColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.pack,
    required this.owned,
    required this.equipped,
    required this.onTap,
    super.key,
  });

  final _ShopPack pack;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF170B10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: pack.accent.withValues(alpha: .65)),
            ),
            child: Row(
              children: [
                _PackIcon(pack: pack, large: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'FEATURED REACTION PACK',
                        style: TextStyle(
                          color: pack.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StatusPill(
                        label: equipped
                            ? 'EQUIPPED'
                            : owned
                                ? 'OWNED'
                                : 'LOCKED',
                        color: equipped
                            ? ReactColors.lime
                            : owned
                                ? pack.accent
                                : ReactColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ReactColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      );
}

class _PackIcon extends StatelessWidget {
  const _PackIcon({required this.pack, this.large = false});
  final _ShopPack pack;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 62.0 : 50.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: pack.accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(large ? 18 : 15),
        border: Border.all(color: pack.accent.withValues(alpha: .42)),
      ),
      child: Icon(pack.icon, color: pack.accent, size: large ? 30 : 25),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .38)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      );
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onSelected});
  final _ShopFilter selected;
  final ValueChanged<_ShopFilter> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _ShopFilter.values.map((filter) {
            final active = filter == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: ValueKey<String>('shop_filter_${filter.name}'),
                selected: active,
                onSelected: (_) => onSelected(filter),
                label: Text(filter.label),
                showCheckmark: false,
                backgroundColor: ReactColors.panel,
                selectedColor: ReactColors.electricBlue.withValues(alpha: .20),
                side: BorderSide(
                  color: active
                      ? ReactColors.electricBlueBright
                      : ReactColors.border,
                ),
                labelStyle: TextStyle(
                  color: active
                      ? ReactColors.textPrimary
                      : ReactColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _PackSheet extends StatelessWidget {
  const _PackSheet({
    required this.pack,
    required this.owned,
    required this.equipped,
    required this.actionLabel,
    required this.onAction,
  });

  final _ShopPack pack;
  final bool owned;
  final bool equipped;
  final String actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(22, 10, 22, 22 + bottom),
      decoration: const BoxDecoration(
        color: ReactColors.backgroundRaised,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ReactColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _PackIcon(pack: pack, large: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.category,
                          style: TextStyle(
                            color: pack.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pack.title,
                          style: const TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                pack.subtitle,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              for (final item in pack.includes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: pack.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (!owned)
                const Text(
                  'PREVIEW ONLY • STORE CHECKOUT IS NOT ENABLED YET.',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                )
              else if (LocalShopState.debugUnlocksEnabled &&
                  pack.id != LocalShopState.corePackId)
                const Text(
                  'DEV ENTITLEMENT • RELEASE BUILDS REMAIN LOCKED UNTIL PURCHASED.',
                  style: TextStyle(
                    color: ReactColors.purple,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction == null
                      ? null
                      : () async {
                          await onAction!();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: pack.accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: ReactColors.panelSoft,
                    disabledForegroundColor: ReactColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FairPlayCard extends StatelessWidget {
  const _FairPlayCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ReactColors.lime.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ReactColors.lime.withValues(alpha: .30)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FAIR PLAY PROMISE',
              style: TextStyle(
                color: ReactColors.lime,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'NO EXTRA LIVES, SCORE BOOSTS, FASTER RETRIES OR PAID GAMEPLAY ADVANTAGES.',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.45,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
      );
}

enum _ShopFilter {
  all('ALL', 'ALL COSMETICS'),
  packs('REACTION', 'REACTION PACKS'),
  themes('THEMES', 'REACTION PACKS'),
  countdown('COUNTDOWN', 'COUNTDOWN STYLES'),
  audio('AUDIO', 'AUDIO PACKS'),
  styles('STYLES', 'COMMAND TEXT + SHARE CARDS');

  const _ShopFilter(this.label, this.sectionLabel);
  final String label;
  final String sectionLabel;
}

enum _PackSlot { reaction, countdown, audio, text, share }

class _ShopPack {
  const _ShopPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.slot,
    required this.price,
    required this.accent,
    required this.icon,
    required this.includes,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final _PackSlot slot;
  final String price;
  final Color accent;
  final IconData icon;
  final List<String> includes;
}
