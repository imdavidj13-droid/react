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
      id: 'redline',
      title: 'REDLINE',
      subtitle: 'Aggressive red arena, harder-edged glow and matching SFX.',
      category: 'REACTION PACK',
      price: '£1.99',
      accent: ReactColors.coral,
      icon: Icons.local_fire_department_rounded,
      includes: [
        'Redline arena palette',
        'Matching timer and success effects',
        'Hard-edged countdown and result SFX',
      ],
    ),
    _ShopPack(
      id: 'synthwave',
      title: 'SYNTHWAVE',
      subtitle: 'Retro neon presentation with a purple-blue arcade sound set.',
      category: 'REACTION PACK',
      price: '£1.99',
      accent: ReactColors.purple,
      icon: Icons.waves_rounded,
      includes: [
        'Purple-blue neon arena',
        'Retro command presentation',
        'Synth-inspired gameplay SFX',
      ],
    ),
    _ShopPack(
      id: 'mono',
      title: 'MONO',
      subtitle: 'Clean black-and-white competitive visuals with minimal effects.',
      category: 'THEME',
      price: '£0.99',
      accent: ReactColors.textPrimary,
      icon: Icons.contrast_rounded,
      includes: [
        'Monochrome arena palette',
        'Reduced glow treatment',
        'Minimal competitive UI styling',
      ],
    ),
    _ShopPack(
      id: 'arcade_sfx',
      title: 'ARCADE SFX',
      subtitle: 'Alternative countdown, success, miss and completion sounds.',
      category: 'SOUND PACK',
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
      id: 'glitch_commands',
      title: 'GLITCH COMMANDS',
      subtitle: 'Digital command typography and distortion-style transitions.',
      category: 'COMMAND STYLE',
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

  late Future<String> _equippedPack;

  @override
  void initState() {
    super.initState();
    _equippedPack = LocalShopState.equippedPack();
  }

  Future<void> _equipCore() async {
    await LocalShopState.equip(LocalShopState.corePackId);
    if (!mounted) return;
    setState(() => _equippedPack = LocalShopState.equippedPack());
  }

  Future<void> _showPackDetails(_ShopPack pack, {required bool owned}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PackDetailsSheet(
        pack: pack,
        owned: owned,
        onEquip: owned ? _equipCore : null,
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
        child: FutureBuilder<String>(
          future: _equippedPack,
          builder: (context, snapshot) {
            final equipped = snapshot.data ?? LocalShopState.corePackId;
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
                      equipped: equipped == LocalShopState.corePackId,
                      onTap: () => _showPackDetails(_corePack, owned: true),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  sliver: const SliverToBoxAdapter(child: _SectionLabel('COMING SOON')),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 10, pad, 20),
                  sliver: SliverList.separated(
                    itemCount: _packs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _PackCard(
                      pack: _packs[index],
                      owned: LocalShopState.isOwned(_packs[index].id),
                      equipped: equipped == _packs[index].id,
                      onTap: () => _showPackDetails(
                        _packs[index],
                        owned: LocalShopState.isOwned(_packs[index].id),
                      ),
                    ),
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
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
            side: const BorderSide(color: Color(0xFF1E3552)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'SHOP',
              style: TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ReactColors.electricBlueBright.withValues(alpha: .42)),
      ),
      child: const Column(
        children: [
          Icon(Icons.shopping_bag_outlined, color: ReactColors.electricBlueBright, size: 40),
          SizedBox(height: 12),
          Text(
            'MAKE RE△CT YOURS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Cosmetic packs can change the look and sound of the game without changing scores, lives, timing or leaderboard fairness.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 10.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFF263851))),
      ],
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
    final status = equipped ? 'EQUIPPED' : owned ? 'OWNED' : pack.price;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: pack.accent.withValues(alpha: equipped ? .65 : .32)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: pack.accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: pack.accent.withValues(alpha: .32)),
              ),
              child: Icon(pack.icon, color: pack.accent, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.category,
                    style: TextStyle(
                      color: pack.accent,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pack.title,
                    style: const TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack.subtitle,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 9,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  status,
                  style: TextStyle(color: pack.accent, fontSize: 11.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Icon(
                  owned ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                  color: pack.accent,
                  size: 19,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackDetailsSheet extends StatelessWidget {
  const _PackDetailsSheet({
    required this.pack,
    required this.owned,
    required this.onEquip,
  });

  final _ShopPack pack;
  final bool owned;
  final Future<void> Function()? onEquip;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF07111D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF263851))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334761),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: pack.accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: pack.accent.withValues(alpha: .38)),
                  ),
                  child: Icon(pack.icon, color: pack.accent, size: 29),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.category,
                        style: TextStyle(
                          color: pack.accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pack.title,
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  owned ? 'OWNED' : pack.price,
                  style: TextStyle(color: pack.accent, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              pack.subtitle,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'INCLUDES',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in pack.includes) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline_rounded, color: pack.accent, size: 17),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF050A13),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF263851)),
              ),
              child: Text(
                owned
                    ? 'OWNED ON THIS DEVICE • COSMETIC ONLY.'
                    : 'PREVIEW ONLY • STORE CHECKOUT IS NOT ENABLED YET.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: owned
                    ? () async {
                        await onEquip?.call();
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    : null,
                icon: Icon(owned ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded),
                label: Text(owned ? 'EQUIP' : 'COMING SOON'),
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
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF09101C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.lime.withValues(alpha: .28)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: ReactColors.lime, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'FAIR PLAY PROMISE • NO EXTRA LIVES, SCORE BOOSTS, FASTER RETRIES OR PAID GAMEPLAY ADVANTAGES.',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8.5,
                height: 1.4,
                fontWeight: FontWeight.w900,
                letterSpacing: .55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopPack {
  const _ShopPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.accent,
    required this.icon,
    required this.includes,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String price;
  final Color accent;
  final IconData icon;
  final List<String> includes;
}
