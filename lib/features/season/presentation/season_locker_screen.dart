import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../shop/data/local_shop_state.dart';
import '../data/season_cosmetic_state.dart';
import '../data/season_repository.dart';
import '../domain/season_models.dart';
import 'season_cosmetic_layers.dart';

class SeasonLockerScreen extends StatefulWidget {
  const SeasonLockerScreen({super.key});

  @override
  State<SeasonLockerScreen> createState() => _SeasonLockerScreenState();
}

class _SeasonLockerScreenState extends State<SeasonLockerScreen> {
  late Future<_LockerData> _data;
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
      if (SeasonCosmeticState.isEquippable(reward)) {
        await SeasonCosmeticState.equip(reward);
      } else if (LocalShopState.isImplemented(reward.rewardKey)) {
        await LocalShopState.equip(reward.rewardKey);
      }
      if (!mounted) return;
      setState(_reload);
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 18, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        color: ReactColors.textPrimary,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SEASON LOCKER',
                              style: TextStyle(
                                color: ReactColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'EQUIP COSMETICS EARNED FROM THE PASS',
                              style: TextStyle(
                                color: ReactColors.textSecondary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: data == null
                      ? const Center(child: CircularProgressIndicator())
                      : data.rewards.isEmpty
                      ? const _EmptyLocker()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                          itemCount: data.rewards.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final reward = data.rewards[index];
                            final seasonEquippable =
                                SeasonCosmeticState.isEquippable(reward);
                            final implementedPack =
                                LocalShopState.isImplemented(reward.rewardKey);
                            final equipped = seasonEquippable
                                ? SeasonCosmeticState.isEquipped(reward)
                                : data.equippedPackIds.contains(reward.rewardKey);
                            final usable = seasonEquippable || implementedPack;
                            return _LockerRewardCard(
                              reward: reward,
                              equipped: equipped,
                              usable: usable,
                              busy: _busyKey == reward.rewardKey,
                              onEquip: () => _equip(reward),
                              onClear: equipped && seasonEquippable
                                  ? () => _clear(reward)
                                  : null,
                            );
                          },
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

class _LockerData {
  const _LockerData({required this.rewards, required this.equippedPackIds});

  final List<SeasonReward> rewards;
  final Set<String> equippedPackIds;

  static Future<_LockerData> load() async {
    final season = await const SeasonRepository().loadActiveSeason();
    final equipped = await LocalShopState.equippedPackIds();
    if (season == null) {
      return _LockerData(
        rewards: const <SeasonReward>[],
        equippedPackIds: equipped,
      );
    }

    final rewards = <SeasonReward>[
      for (final tier in season.tiers)
        for (final reward in tier.rewards)
          if (season.isUnlocked(reward)) reward,
    ]
      ..sort((a, b) {
        final kind = _kindLabel(a.kind).compareTo(_kindLabel(b.kind));
        if (kind != 0) return kind;
        return a.tier.compareTo(b.tier);
      });

    return _LockerData(rewards: rewards, equippedPackIds: equipped);
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
    final accent = SeasonCosmeticLayers.accentForReward(reward);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: equipped
              ? accent.withValues(alpha: .65)
              : Colors.white.withValues(alpha: .07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: accent.withValues(alpha: .28)),
            ),
            child: Icon(_kindIcon(reward.kind), color: accent, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .45,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_kindLabel(reward.kind)}  •  TIER ${reward.tier}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 8.3,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  usable
                      ? reward.description
                      : '${reward.description} · display support reserved for a later cosmetic renderer',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (equipped)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: ReactColors.lime,
                  size: 20,
                ),
                if (onClear != null)
                  TextButton(
                    onPressed: onClear,
                    child: const Text(
                      'CLEAR',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            )
          else
            FilledButton(
              onPressed: usable ? onEquip : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(62, 34),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: accent.withValues(alpha: .18),
                foregroundColor: accent,
              ),
              child: Text(
                usable ? 'EQUIP' : 'OWNED',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyLocker extends StatelessWidget {
  const _EmptyLocker();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'REACH PASS TIERS TO ADD\nCOSMETICS TO YOUR LOCKER',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 10,
            height: 1.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

String _kindLabel(String kind) => switch (kind) {
      'reaction_pack' => 'REACTION COLOUR',
      'command_style' => 'COMMAND TEXT',
      'countdown_style' => 'COUNTDOWN',
      'sound_pack' => 'SOUND PACK',
      'share_style' => 'SHARE / RESULT CARD',
      'profile_frame' => 'PROFILE FRAME',
      'profile_badge' => 'PROFILE BADGE',
      'player_code_style' => 'PLAYER CODE',
      'home_theme' => 'HOME THEME',
      'score_effect' => 'SCORE EFFECT',
      'success_effect' => 'SUCCESS EFFECT',
      'failure_effect' => 'FAILURE EFFECT',
      'mode_card_skin' => 'MODE CARD SKIN',
      'title' => 'TITLE',
      'emblem' => 'ICON / EMBLEM',
      _ => kind.replaceAll('_', ' ').toUpperCase(),
    };

IconData _kindIcon(String kind) => switch (kind) {
      'reaction_pack' => Icons.palette_outlined,
      'command_style' => Icons.text_fields_rounded,
      'countdown_style' => Icons.timer_outlined,
      'sound_pack' => Icons.graphic_eq_rounded,
      'share_style' => Icons.ios_share_rounded,
      'profile_frame' => Icons.crop_square_rounded,
      'profile_badge' => Icons.workspace_premium_outlined,
      'player_code_style' => Icons.qr_code_2_rounded,
      'home_theme' => Icons.home_outlined,
      'score_effect' => Icons.auto_awesome_rounded,
      'success_effect' => Icons.check_circle_outline_rounded,
      'failure_effect' => Icons.cancel_outlined,
      'mode_card_skin' => Icons.dashboard_customize_outlined,
      'title' => Icons.title_rounded,
      'emblem' => Icons.bolt_rounded,
      _ => Icons.redeem_outlined,
    };
