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
                Expanded(
                  child: data == null
                      ? const Center(child: CircularProgressIndicator())
                      : data.rewards.isEmpty
                      ? const _EmptyLocker()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                          itemCount: data.rewards.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            if (index == 0) return _LockerSummary(data: data);
                            final reward = data.rewards[index - 1];
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

class _LockerHeader extends StatelessWidget {
  const _LockerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 18, 8),
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
                  'SEASON LOCKER',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'OWNED IS NOT THE SAME AS EQUIPPED',
                  style: TextStyle(
                    color: ReactColors.electricBlueBright,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockerData {
  const _LockerData({required this.rewards, required this.equippedPackIds});

  final List<SeasonReward> rewards;
  final Set<String> equippedPackIds;

  Iterable<SeasonReward> get equippedRewards => rewards.where((reward) {
    if (SeasonCosmeticState.isEquippable(reward)) {
      return SeasonCosmeticState.isEquipped(reward);
    }
    return equippedPackIds.contains(reward.rewardKey);
  });

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

class _LockerSummary extends StatelessWidget {
  const _LockerSummary({required this.data});

  final _LockerData data;

  @override
  Widget build(BuildContext context) {
    final equipped = data.equippedRewards.toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07182B), Color(0xFF0D0A1F)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ReactColors.electricBlueBright.withValues(alpha: .25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                equipped.isEmpty
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_rounded,
                color: equipped.isEmpty
                    ? ReactColors.electricBlueBright
                    : ReactColors.lime,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                equipped.isEmpty
                    ? 'NOTHING EQUIPPED RIGHT NOW'
                    : '${equipped.length} COSMETIC${equipped.length == 1 ? '' : 'S'} EQUIPPED',
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .65,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            equipped.isEmpty
                ? 'Tap EQUIP on an available reward below. A reward only shows EQUIPPED when the game has a real destination for it.'
                : equipped
                      .map(
                        (reward) =>
                            '• ${reward.name} — ${_kindDestination(reward.kind)}',
                      )
                      .join('\n'),
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
    final trackColor = reward.isPremium ? ReactColors.purple : ReactColors.electricBlueBright;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: equipped
              ? ReactColors.lime.withValues(alpha: .52)
              : accent.withValues(alpha: .13),
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
                  border: Border.all(color: accent.withValues(alpha: .27)),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _kindLabel(reward.kind),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .65,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${reward.isPremium ? 'PREMIUM' : 'FREE'} • T${reward.tier}',
                          style: TextStyle(
                            color: trackColor,
                            fontSize: 7.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 27,
                  height: 27,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (equipped)
                const _StatusPill(
                  label: 'EQUIPPED',
                  icon: Icons.check_rounded,
                  color: ReactColors.lime,
                )
              else if (usable)
                FilledButton(
                  onPressed: onEquip,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: accent.withValues(alpha: .18),
                    foregroundColor: accent,
                  ),
                  child: const Text(
                    'EQUIP',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                )
              else
                const _StatusPill(
                  label: 'OWNED',
                  icon: Icons.inventory_2_outlined,
                  color: ReactColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _InfoLine(label: 'WHAT IT DOES', value: _kindEffect(reward.kind)),
          const SizedBox(height: 5),
          _InfoLine(label: 'YOU SEE IT', value: _kindDestination(reward.kind)),
          const SizedBox(height: 5),
          _InfoLine(
            label: 'STATUS',
            value: equipped
                ? 'Equipped now.'
                : usable
                ? 'Owned and ready to equip.'
                : 'Owned, but this renderer is still being connected.',
            valueColor: equipped
                ? ReactColors.lime
                : usable
                ? ReactColors.textPrimary
                : ReactColors.textSecondary,
          ),
          if (reward.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reward.description,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (equipped && onClear != null) ...[
            const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.valueColor = ReactColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 8.8,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 7.3,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
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
      'player_code_style' => 'PLAYER CODE STYLE',
      'home_theme' => 'HOME THEME',
      'score_effect' => 'SCORE EFFECT',
      'success_effect' => 'SUCCESS EFFECT',
      'failure_effect' => 'FAILURE EFFECT',
      'mode_card_skin' => 'MODE CARD SKIN',
      'title' => 'PLAYER TITLE',
      'emblem' => 'PLAYER EMBLEM',
      _ => kind.replaceAll('_', ' ').toUpperCase(),
    };

String _kindDestination(String kind) => switch (kind) {
      'reaction_pack' => 'During runs in gameplay modes.',
      'command_style' => 'On command words during gameplay.',
      'countdown_style' => 'On the 3–2–1 launch countdown.',
      'sound_pack' => 'In gameplay sound cues.',
      'share_style' => 'On the result sharing screen.',
      'profile_frame' => 'Around the full Player Profile screen.',
      'profile_badge' => 'Under your avatar in the Player Profile identity card.',
      'player_code_style' => 'Around your RX code in the Player Profile identity card.',
      'home_theme' => 'Behind the Home screen.',
      'score_effect' => 'Around score feedback during/results after a run.',
      'success_effect' => 'When a command is completed successfully.',
      'failure_effect' => 'When a command is missed or fails.',
      'mode_card_skin' => 'On cards in the Modes catalogue.',
      'title' => 'Directly below your player name in Player Profile.',
      'emblem' => 'Beside your RX player code in Player Profile.',
      _ => 'On its connected cosmetic surface.',
    };

String _kindEffect(String kind) => switch (kind) {
      'reaction_pack' => 'Changes the main neon reaction colour palette.',
      'command_style' => 'Changes how command words are styled during a run.',
      'countdown_style' => 'Changes the visual 3–2–1 countdown presentation.',
      'sound_pack' => 'Changes the sound set used for gameplay cues.',
      'share_style' => 'Changes the visual style of shared result cards.',
      'profile_frame' => 'Adds a themed frame around your Player Profile.',
      'profile_badge' => 'Adds a named season badge to your identity card.',
      'player_code_style' => 'Restyles the container, accent and spacing of your RX code.',
      'home_theme' => 'Adds a season visual treatment behind the Home screen.',
      'score_effect' => 'Changes the visual treatment around score feedback.',
      'success_effect' => 'Changes the feedback shown after a successful input.',
      'failure_effect' => 'Changes the feedback shown after a miss or failure.',
      'mode_card_skin' => 'Restyles Modes cards with a themed gradient, border and glow.',
      'title' => 'Adds an equippable season title under your display name.',
      'emblem' => 'Adds a themed emblem beside your player code.',
      _ => 'Changes a cosmetic presentation only.',
    };

IconData _kindIcon(String kind) => switch (kind) {
      'reaction_pack' => Icons.palette_outlined,
      'command_style' => Icons.text_fields_rounded,
      'countdown_style' => Icons.timer_outlined,
      'sound_pack' => Icons.graphic_eq_rounded,
      'share_style' => Icons.ios_share_rounded,
      'profile_frame' => Icons.crop_square_rounded,
      'profile_badge' => Icons.workspace_premium_outlined,
      'player_code_style' => Icons.badge_outlined,
      'home_theme' => Icons.home_outlined,
      'score_effect' => Icons.auto_graph_rounded,
      'success_effect' => Icons.check_circle_outline_rounded,
      'failure_effect' => Icons.flash_off_rounded,
      'mode_card_skin' => Icons.view_module_outlined,
      'title' => Icons.title_rounded,
      'emblem' => Icons.bolt_rounded,
      _ => Icons.redeem_outlined,
    };
