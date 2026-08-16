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
    subtitle: 'The original electric-blue RE△CT arena and gameplay presentation.',
    category: 'BUILT IN',
    filter: _ShopFilter.themes,
    price: 'OWNED',
    accent: ReactColors.electricBlueBright,
    icon: Icons.bolt_rounded,
    includes: [
      'Original electric-blue arena',
      'Core gameplay effects and command style',
      'Standard RE△CT sound presentation',
    ],
  );

  static const _packs = <_ShopPack>[
    _ShopPack(
      id: LocalShopState.redlinePackId,
      title: 'REDLINE',
      subtitle: 'Aggressive red arena, harder-edged glow and matching effects.',
      category: 'REACTION PACK',
      filter: _ShopFilter.packs,
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
      subtitle: 'Retro neon presentation with a purple-blue arcade arena.',
      category: 'REACTION PACK',
      filter: _ShopFilter.packs,
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
      subtitle: 'Clean black-and-white competitive visuals with reduced effects.',
      category: 'THEME',
      filter: _ShopFilter.themes,
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
      id: LocalShopState.arcadeSfxPackId,
      title: 'ARCADE SFX',
      subtitle: 'Alternative countdown, success, miss and completion sounds.',
      category: 'SOUND PACK',
      filter: _ShopFilter.audio,
      price: '£0.99',
      accent: ReactColors.lime,
      icon: Icons.graphic_eq_rounded,
      includes: [
        'Alternate countdown cues',
        'Arcade success and miss sounds',
        'Alternate completion and warning cues',
      ],
    ),
    _ShopPack(
      id: LocalShopState.glitchCommandsPackId,
      title: 'GLITCH COMMANDS',
      subtitle: 'Digital command typography and system-coded instruction labels.',
      category: 'COMMAND STYLE',
      filter: _ShopFilter.styles,
      price: '£0.99',
      accent: ReactColors.electricBlueBright,
      icon: Icons.broken_image_outlined,
      includes: [
        'Glitch command typography',
        'System-coded command hints',
        'Matching digital syntax treatment',
      ],
    ),
    _ShopPack(
      id: LocalShopState.proShareCardsPackId,
      title: 'PRO SHARE CARDS',
      subtitle: 'Premium score-first layouts for sharing runs and Daily scores.',
      category: 'SHARE STYLE',
      filter: _ShopFilter.styles,
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

  List<_ShopPack> get _visiblePacks {
    final source = _filter == _ShopFilter.all
        ? _packs.where((pack) => pack.id != _featuredPackId)
        : _packs.where((pack) => pack.filter == _filter);
    return source.toList(growable: false);
  }

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
    if (pack.id == LocalShopState.arcadeSfxPackId) {
      await LocalShopState.equipCoreAudio();
    } else if (pack.id == LocalShopState.glitchCommandsPackId) {
      await LocalShopState.equipCoreCommandStyle();
    } else if (pack.id == LocalShopState.proShareCardsPackId) {
      await LocalShopState.equipCoreShareStyle();
    } else {
      await LocalShopState.equip(LocalShopState.corePackId);
    }
    _refresh();
  }

  String _restoreLabel(_ShopPack pack) {
    if (pack.id == LocalShopState.arcadeSfxPackId) return 'USE CORE SFX';
    if (pack.id == LocalShopState.glitchCommandsPackId) {
      return 'USE CORE COMMANDS';
    }
    if (pack.id == LocalShopState.proShareCardsPackId) {
      return 'USE CORE SHARE CARD';
    }
    return 'USE RE△CT CORE';
  }

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
        actionLabel: equipped ? _restoreLabel(pack) : owned ? 'EQUIP' : 'COMING SOON',
        onAction: !owned
            ? null
            : equipped
                ? () => _restoreSlot(pack)
                : () => _equip(pack),
      ),
    );
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
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 12),
                  sliver: SliverToBoxAdapter(child: _HeroCard()),
                ),
                if (LocalShopState.debugUnlocksEnabled)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
                    sliver: const SliverToBoxAdapter(child: _DevCard()),
                  ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  sliver: const SliverToBoxAdapter(child: _SectionLabel('YOUR STYLE')),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 10, pad, 18),
                  sliver: SliverToBoxAdapter(
                    child: _PackCard(
                      pack: _corePack,
                      owned: true,
                      equipped: equipped.contains(_corePack.id),
                      onTap: () => _showPack(_corePack),
                    ),
                  ),
                ),
                if (_filter == _ShopFilter.all) ...[
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    sliver: const SliverToBoxAdapter(child: _SectionLabel('FEATURED')),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 10, pad, 18),
                    sliver: SliverToBoxAdapter(
                      child: _FeaturedCard(
                        key: const ValueKey('featured_redline'),
                        pack: _featured,
                        owned: LocalShopState.isOwned(_featured.id),
                        equipped: equipped.contains(_featured.id),
                        onTap: () => _showPack(_featured),
                      ),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                  sliver: SliverToBoxAdapter(
                    child: _Filters(
                      selected: _filter,
                      onSelected: (filter) => setState(() => _filter = filter),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  sliver: const SliverToBoxAdapter(
                    child: _SectionLabel('COSMETIC COLLECTION'),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 10, pad, 20),
                  sliver: SliverList.separated(
                    itemCount: _visiblePacks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final pack = _visiblePacks[index];
                      return _PackCard(
                        pack: pack,
                        owned: LocalShopState.isOwned(pack.id),
                        equipped: equipped.contains(pack.id),
                        onTap: () => _showPack(pack),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 28),
                  sliver: const SliverToBoxAdapter(child: _FairPlayCard()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ReactColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .45)),
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
            'CUSTOMISE THE LOOK AND FEEL. NEVER THE RULES.',
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DevCard extends StatelessWidget {
  const _DevCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ReactColors.purple.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .42)),
      ),
      child: const Row(
        children: [
          Icon(Icons.developer_mode_rounded, color: ReactColors.purple, size: 20),
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
  Widget build(BuildContext context) {
    return Material(
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
              color: equipped ? pack.accent.withValues(alpha: .75) : ReactColors.border,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _StatusPill(
                      label: equipped ? 'EQUIPPED' : owned ? 'OWNED' : 'LOCKED',
                      color: equipped
                          ? ReactColors.lime
                          : owned
                              ? pack.accent
                              : ReactColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ReactColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Material(
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
                      label: equipped ? 'EQUIPPED' : owned ? 'OWNED' : 'LOCKED',
                      color: equipped
                          ? ReactColors.lime
                          : owned
                              ? pack.accent
                              : ReactColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ReactColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ShopFilter.values.map((filter) {
          final active = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: ValueKey('shop_filter_${filter.name}'),
              selected: active,
              onSelected: (_) => onSelected(filter),
              label: Text(filter.label),
              showCheckmark: false,
              backgroundColor: ReactColors.panel,
              selectedColor: ReactColors.electricBlue.withValues(alpha: .20),
              side: BorderSide(
                color: active ? ReactColors.electricBlueBright : ReactColors.border,
              ),
              labelStyle: TextStyle(
                color: active ? ReactColors.textPrimary : ReactColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
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
                    Icon(Icons.check_circle_rounded, color: pack.accent, size: 18),
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
  all('ALL'),
  packs('PACKS'),
  themes('THEMES'),
  audio('AUDIO'),
  styles('STYLES');

  const _ShopFilter(this.label);
  final String label;
}

class _ShopPack {
  const _ShopPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.filter,
    required this.price,
    required this.accent,
    required this.icon,
    required this.includes,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final _ShopFilter filter;
  final String price;
  final Color accent;
  final IconData icon;
  final List<String> includes;
}
