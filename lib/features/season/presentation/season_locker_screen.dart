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
                              'SEE WHAT EACH REWARD CHANGES AND WHERE IT APPEARS',
                              style: TextStyle(
                                color: ReactColors.textSecondary,
                                fontSize: 8.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .65,
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
    final equipped = data.equippedRewards.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReactColors.electricBlueBright.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: ReactColors.electricBlueBright.withValues(alpha: .22),
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
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                equipped.isEmpty
                    ? 'NOTHING EQUIPPED'
                    : '${equipped.length} EQUIPPED',
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            equipped.isEmpty
                ? 'Only rewards with a live visual renderer can be equipped. Owned rewards that are not wired yet are clearly marked below.'
                : equipped
                      .map((reward) => '${reward.name} → ${_kindDestination(reward.kind)}')
                      .join('\n'),
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              height: 1.4,
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
    final destination = _kindDestination(reward.kind);
    final effect = _kindEffect(reward.kind);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: equipped
              ? ReactColors.lime.withValues(alpha: .55)
              : Colors.white.withValues(alpha: .07),
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
          const SizedBox(height: 10),
          _InfoLine(label: 'CHANGES', value: effect),
          const SizedBox(height: 4),
          _InfoLine(label: 'VISIBLE IN', value: destination),
          if (reward.description.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              reward.description,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8.8,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!usable) ...[
            const SizedBox(height: 8),
            const Text(
              'OWNED, BUT NOT EQUIPPABLE YET — THIS VISUAL SURFACE IS NOT WIRED TO THE GAME YET.',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8,
                height: 1.35,
                fontWeight: FontWeight.w900,
                letterSpacing: .35,
              ),
            ),
          ],
          if (equipped && onClear != null) ...[
            const SizedBox(height: 6),
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
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 7.8,
              fontWeight: FontWeight.w900,
              letterSpacing: .55,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 8.8,
              height: 1.25,
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
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
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

String _kindDestination(String kind) => switch (kind) {
      'reaction_pack' => 'All gameplay modes',
      'command_style' => 'Gameplay command text',
      'countdown_style' => '3–2–1 launch countdown',
      'sound_pack' => 'Gameplay audio cues',
      'share_style' => 'Result sharing screen',
      'profile_frame' => 'Player Profile screen border',
      'profile_badge' => 'Player Profile header',
      'player_code_style' => 'Player code / Friends UI',
      'home_theme' => 'Home screen background',
      'score_effect' => 'Gameplay score presentation',
      'success_effect' => 'Successful-command feedback',
      'failure_effect' => 'Miss / failure feedback',
      'mode_card_skin' => 'Modes catalogue cards',
      'title' => 'Player Profile header',
      'emblem' => 'Player Profile header',
      _ => 'Cosmetic presentation',
    };

String _kindEffect(String kind) => switch (kind) {
      'reaction_pack' => 'Changes the main neon reaction colour palette.',
      'command_style' => 'Changes how command words are styled during a run.',
      'countdown_style' => 'Changes the visual 3–2–1 countdown presentation.',
      'sound_pack' => 'Changes the sound set used for gameplay cues.',
      'share_style' => 'Changes the visual style of shared result cards.',
      'profile_frame' => 'Adds a themed frame around your Player Profile.',
      'profile_badge' => 'Adds a season badge to your Player Profile.',
      'player_code_style' => 'Changes the presentation of your public player code.',
      'home_theme' => 'Adds a season visual treatment behind the Home screen.',
      'score_effect' => 'Changes the visual treatment around score updates.',
      'success_effect' => 'Changes the feedback shown after a successful input.',
      'failure_effect' => 'Changes the feedback shown after a miss or failure.',
      'mode_card_skin' => 'Changes the appearance of mode cards.',
      'title' => 'Displays a season title on your Player Profile.',
      'emblem' => 'Displays a season emblem on your Player Profile.',
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
