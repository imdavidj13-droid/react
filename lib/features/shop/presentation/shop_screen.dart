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
    implemented: true,
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
      implemented: true,
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
      implemented: true,
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
      implemented: true,
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
      implemented: true,
      includes: [
        'Alternate countdown cues',
        'Arcade success and miss sounds',
        'Alternate completion and warning cues',
      ],
    ),
    _ShopPack(
      id: 'glitch_commands',
      title: 'GLITCH COMMANDS',
      subtitle: 'Digital command typography and distortion-style transitions.',
      category: 'COMMAND STYLE',
      filter: _ShopFilter.styles,
      price: '£0.99',
      accent: ReactColors.electricBlueBright,
      icon: Icons.broken_image_outlined,
      includes: [
        'Glitch command typography',
        'Digital command transitions',
        'Matching command accent effects',
      ],
    ),
    _ShopPack(
      id: 'pro_share_cards',
      title: 'PRO SHARE CARDS',
      subtitle: 'Premium result-card layouts for sharing scores and Daily runs.',
      category: 'SHARE STYLE',
      filter: _ShopFilter.styles,
      price: '£0.99',
      accent: ReactColors.purple,
      icon: Icons.ios_share_rounded,
      includes: [
        'Premium Classic result layout',
        'Premium Daily result layout',
        'Additional score-card treatments',
      ],
    ),
  ];

  static const _featuredPackId = LocalShopState.redlinePackId;

  late Future<Set<String>> _equippedPackIds;
  _ShopFilter _filter = _ShopFilter.all;

  _ShopPack get _featuredPack =>
      _packs.firstWhere((pack) => pack.id == _featuredPackId);

  List<_ShopPack> get _visiblePacks {
    if (_filter == _ShopFilter.all) {
      return _packs.where((pack) => pack.id != _featuredPackId).toList();
    }
    return _packs.where((pack) => pack.filter == _filter).toList();
  }

  @override
  void initState() {
    super.initState();
    _equippedPackIds = LocalShopState.equippedPackIds();
  }

  void _refreshEquipped() {
    if (!mounted) return;
    setState(() => _equippedPackIds = LocalShopState.equippedPackIds());
  }

  Future<void> _equip(_ShopPack pack) async {
    await LocalShopState.equip(pack.id);
    _refreshEquipped();
  }

  Future<void> _useCoreSfx() async {
    await LocalShopState.equipCoreAudio();
    _refreshEquipped();
  }

  Future<void> _showPackDetails(_ShopPack pack) async {
    final owned = LocalShopState.isOwned(pack.id);
    final equipped = (await LocalShopState.equippedPackIds()).contains(pack.id);
    if (!mounted) return;

    final isArcade = pack.id == LocalShopState.arcadeSfxPackId;
    final canEquip = owned && pack.implemented;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PackDetailsSheet(
        pack: pack,
        owned: owned,
        equipped: equipped,
        actionLabel: isArcade && equipped
            ? 'USE CORE SFX'
            : canEquip
                ? 'EQUIP'
                : 'COMING SOON',
        onAction: isArcade && equipped
            ? _useCoreSfx
            : canEquip
                ? () => _equip(pack)
                : null,
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
            final visiblePacks = _visiblePacks;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 10),
                  sliver: SliverToBoxAdapter(
                    child: _Header(onBack: () => Navigator.of(context).pop()),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 12),
                  sliver: const SliverToBoxAdapter(child: _ShopHero()),
                ),
                if (LocalShopState.debugUnlocksEnabled)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
                    sliver: const SliverToBoxAdapter(child: _DevUnlockCard()),
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
                      onTap: () => _showPackDetails(_corePack),
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
                      child: _FeaturedPackCard(
                        key: const ValueKey('featured_redline'),
                        pack: _featuredPack,
                        owned: LocalShopState.isOwned(_featuredPack.id),
                        equipped: equipped.contains(_featuredPack.id),
                        onTap: () => _showPackDetails(_featuredPack),
                      ),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                  sliver: SliverToBoxAdapter(
                    child: _ShopFilters(
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
                if (visiblePacks.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 16, pad, 20),
                    sliver: const SliverToBoxAdapter(child: _EmptyFilterCard()),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 10, pad, 20),
                    sliver: SliverList.separated(
                      itemCount: visiblePacks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final pack = visiblePacks[index];
                        return _PackCard(
                          pack: pack,
                          owned: LocalShopState.isOwned(pack.id),
                          equipped: equipped.contains(pack.id),
                          onTap: () => _showPackDetails(pack),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
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
}

class _ShopHero extends StatelessWidget {
  const _ShopHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ReactColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: ReactColors.electricBlue.withValues(alpha: .08),
            blurRadius: 24,
          ),
        ],
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
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DevUnlockCard extends StatelessWidget {
  const _DevUnlockCard();

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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ReactColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
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
                    Row(
                      children: [
                        _StatusPill(
                          label: equipped ? 'EQUIPPED' : owned ? 'OWNED' : 'LOCKED',
                          color: equipped
                              ? ReactColors.lime
                              : owned
                                  ? pack.accent
                                  : ReactColors.textSecondary,
                        ),
                        if (!owned) ...[
                          const SizedBox(width: 8),
                          Text(
                            pack.price,
                            style: const TextStyle(
                              color: ReactColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
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

class _FeaturedPackCard extends StatelessWidget {
  const _FeaturedPackCard({
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
            boxShadow: [
              BoxShadow(color: pack.accent.withValues(alpha: .10), blurRadius: 24),
            ],
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
                    if (!owned) ...[
                      const SizedBox(height: 7),
                      Text(
                        pack.price,
                        style: const TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
  Widget build(BuildContext context) {
    return Container(
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
}

class _ShopFilters extends StatelessWidget {
  const _ShopFilters({required this.selected, required this.onSelected});

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

class _PackDetailsSheet extends StatelessWidget {
  const _PackDetailsSheet({
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
            ...pack.includes.map(
              (item) => Padding(
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
            ),
            const SizedBox(height: 10),
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
  Widget build(BuildContext context) {
    return Container(
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
}

class _EmptyFilterCard extends StatelessWidget {
  const _EmptyFilterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ReactColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.border),
      ),
      child: const Text(
        'NO COSMETICS IN THIS CATEGORY YET.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
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
    this.implemented = false,
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
  final bool implemented;
}
