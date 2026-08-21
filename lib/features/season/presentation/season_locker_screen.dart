import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/season_cosmetic_state.dart';
import '../data/season_repository.dart';
import '../domain/cosmetic_taxonomy.dart';
import '../domain/season_models.dart';
import 'season_cosmetic_layers.dart';
import 'season_reward_preview.dart';

class SeasonLockerScreen extends StatefulWidget {
  const SeasonLockerScreen({super.key});

  @override
  State<SeasonLockerScreen> createState() => _SeasonLockerScreenState();
}

class _SeasonLockerScreenState extends State<SeasonLockerScreen> {
  late Future<_LockerData> _data;
  CosmeticLockerTab _tab = CosmeticLockerTab.all;
  String? _busyKey;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _data = _LockerData.load();

  Future<void> _equip(SeasonReward reward) async {
    if (_busyKey != null) return;
    setState(() => _busyKey = reward.rewardKey);
    try {
      await SeasonCosmeticState.equip(reward);
      if (mounted) setState(_reload);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _clear(SeasonReward reward) async {
    if (!SeasonCosmeticState.isEquippable(reward)) return;
    await SeasonCosmeticState.clearKind(reward.kind);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<_LockerData>(
          future: _data,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Column(
              children: [
                _LockerHeader(onBack: () => Navigator.of(context).pop()),
                if (data != null) ...[
                  _LockerTotals(data: data),
                  _LockerTabs(
                    selected: _tab,
                    data: data,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                ],
                Expanded(
                  child: data == null
                      ? const Center(child: CircularProgressIndicator())
                      : _LockerList(
                          data: data,
                          tab: _tab,
                          busyKey: _busyKey,
                          onEquip: _equip,
                          onClear: _clear,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LockerHeader extends StatelessWidget {
  const _LockerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 18, 6),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              color: ReactColors.textPrimary,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOCKER',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ALL EARNED COSMETICS • ONE PLACE TO EQUIP',
                    style: TextStyle(
                      color: ReactColors.electricBlueBright,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LockerTotals extends StatelessWidget {
  const _LockerTotals({required this.data});

  final _LockerData data;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 9),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF07111D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ReactColors.electricBlueBright.withValues(alpha: .22),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: ReactColors.electricBlueBright,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                '${data.rewards.length} UNLOCKED',
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
              const Spacer(),
              const Icon(Icons.check_circle_rounded, color: ReactColors.lime, size: 16),
              const SizedBox(width: 5),
              Text(
                '${data.equippedRewards.length} EQUIPPED',
                style: const TextStyle(
                  color: ReactColors.lime,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        ),
      );
}

class _LockerTabs extends StatelessWidget {
  const _LockerTabs({
    required this.selected,
    required this.data,
    required this.onChanged,
  });

  final CosmeticLockerTab selected;
  final _LockerData data;
  final ValueChanged<CosmeticLockerTab> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          itemCount: CosmeticLockerTab.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final tab = CosmeticLockerTab.values[index];
            final active = tab == selected;
            final count = data.countFor(tab);
            return ChoiceChip(
              selected: active,
              onSelected: (_) => onChanged(tab),
              showCheckmark: false,
              backgroundColor: const Color(0xFF07111D),
              selectedColor: ReactColors.electricBlueBright.withValues(alpha: .15),
              side: BorderSide(
                color: active
                    ? ReactColors.electricBlueBright
                    : const Color(0xFF203854),
              ),
              label: Text(
                '${tab.label}  $count',
                style: TextStyle(
                  color: active
                      ? ReactColors.electricBlueBright
                      : ReactColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
            );
          },
        ),
      );
}

class _LockerList extends StatelessWidget {
  const _LockerList({
    required this.data,
    required this.tab,
    required this.busyKey,
    required this.onEquip,
    required this.onClear,
  });

  final _LockerData data;
  final CosmeticLockerTab tab;
  final String? busyKey;
  final ValueChanged<SeasonReward> onEquip;
  final ValueChanged<SeasonReward> onClear;

  @override
  Widget build(BuildContext context) {
    final rewards = data.forTab(tab);
    if (data.rewards.isEmpty) return const _EmptyLocker();
    if (rewards.isEmpty) return _EmptyCategory(tab: tab);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      itemCount: rewards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final usable = SeasonCosmeticState.isEquippable(reward);
        final equipped = usable && SeasonCosmeticState.isEquipped(reward);
        return _LockerRewardCard(
          reward: reward,
          equipped: equipped,
          usable: usable,
          busy: busyKey == reward.rewardKey,
          onEquip: () => onEquip(reward),
          onClear: equipped ? () => onClear(reward) : null,
        );
      },
    );
  }
}

class _LockerData {
  const _LockerData({required this.rewards});

  final List<SeasonReward> rewards;

  List<SeasonReward> get equippedRewards => rewards
      .where(
        (reward) => SeasonCosmeticState.isEquippable(reward) &&
            SeasonCosmeticState.isEquipped(reward),
      )
      .toList(growable: false);

  int countFor(CosmeticLockerTab tab) => forTab(tab).length;

  List<SeasonReward> forTab(CosmeticLockerTab tab) {
    if (tab == CosmeticLockerTab.all) return rewards;
    return rewards
        .where((reward) => CosmeticTaxonomy.tabFor(reward.kind) == tab)
        .toList(growable: false);
  }

  static Future<_LockerData> load() async {
    await SeasonCosmeticState.load();
    const repository = SeasonRepository();

    // Current season refreshes newly reached/debug entitlements. Lifetime RPC
    // restores historical ownership on a clean install/new device.
    try {
      await repository.loadActiveSeason();
      await repository.loadOwnedCosmetics();
    } catch (_) {
      // Cached lifetime Locker remains usable offline.
    }

    final rewards = SeasonCosmeticState.ownedRewards.toList(growable: true)
      ..sort((a, b) {
        final tabOrder = CosmeticTaxonomy.tabFor(a.kind).index
            .compareTo(CosmeticTaxonomy.tabFor(b.kind).index);
        if (tabOrder != 0) return tabOrder;
        final kindOrder = CosmeticTaxonomy.specFor(a.kind).label
            .compareTo(CosmeticTaxonomy.specFor(b.kind).label);
        if (kindOrder != 0) return kindOrder;
        return a.tier.compareTo(b.tier);
      });

    return _LockerData(rewards: List<SeasonReward>.unmodifiable(rewards));
  }
}

class _LockerRewardCard extends StatelessWidget {
  const _LockerRewardCard({
    required this.reward,
    required this.equipped,
    required this.usable,
    required this.busy,
    required this.onEquip,
    this.onClear,
  });

  final SeasonReward reward;
  final bool equipped;
  final bool usable;
  final bool busy;
  final VoidCallback onEquip;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final spec = CosmeticTaxonomy.specFor(reward.kind);
    final accent = SeasonCosmeticLayers.accentForReward(reward);
    final track = reward.isPremium ? ReactColors.purple : ReactColors.electricBlueBright;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: equipped
              ? ReactColors.lime.withValues(alpha: .55)
              : accent.withValues(alpha: .22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: .3)),
                ),
                child: Icon(spec.icon, color: accent, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${spec.label}  •  ${reward.isPremium ? 'PREMIUM' : 'FREE'} T${reward.tier}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: track,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (equipped)
                const _StatusPill(label: 'EQUIPPED', color: ReactColors.lime)
              else if (usable)
                FilledButton(
                  onPressed: onEquip,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(62, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: accent.withValues(alpha: .17),
                    foregroundColor: accent,
                  ),
                  child: const Text(
                    'EQUIP',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                )
              else
                const _StatusPill(label: 'UNLOCKED', color: ReactColors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          SeasonRewardPreview(reward: reward, height: 82),
          const SizedBox(height: 10),
          _InfoLine(label: 'CHANGES', value: spec.effect),
          const SizedBox(height: 5),
          _InfoLine(label: 'APPEARS', value: spec.destination),
          if (!usable) ...[
            const SizedBox(height: 7),
            const Text(
              'UNLOCKED • RENDERER NOT CONNECTED YET',
              style: TextStyle(
                color: ReactColors.coral,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .55,
              ),
            ),
          ],
          if (equipped && onClear != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClear,
                child: const Text(
                  'UNEQUIP',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 7.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontSize: 8.7,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            letterSpacing: .35,
          ),
        ),
      );
}

class _EmptyLocker extends StatelessWidget {
  const _EmptyLocker();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'EARN COSMETICS IN THE SEASON PASS\nTO ADD THEM TO YOUR LOCKER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 10,
              height: 1.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      );
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.tab});

  final CosmeticLockerTab tab;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'NO ${tab.label} COSMETICS UNLOCKED YET',
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      );
}
