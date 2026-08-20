import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/season_repository.dart';
import '../domain/season_models.dart';
import 'season_locker_screen.dart';

class SeasonScreen extends StatefulWidget {
  const SeasonScreen({super.key});

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  static const _repository = SeasonRepository();
  late Future<SeasonSnapshot?> _season;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _season = _repository.loadActiveSeason();

  Future<void> _refresh() async {
    setState(_reload);
    await _season;
  }

  Future<void> _openLocker() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SeasonLockerScreen()),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<SeasonSnapshot?>(
          future: _season,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingSeason();
            }
            final season = snapshot.data;
            if (season == null) {
              return _NoSeason(
                onBack: () => Navigator.of(context).pop(),
                onRetry: () => setState(_reload),
              );
            }
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _SeasonHero(
                    season: season,
                    onBack: () => Navigator.of(context).pop(),
                    onLocker: _openLocker,
                  ),
                  const _SeasonTabs(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PassTab(
                          season: season,
                          onRefresh: _refresh,
                          onLocker: _openLocker,
                        ),
                        _MissionsTab(season: season, onRefresh: _refresh),
                        _SeasonInfoTab(season: season),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SeasonHero extends StatelessWidget {
  const _SeasonHero({
    required this.season,
    required this.onBack,
    required this.onLocker,
  });

  final SeasonSnapshot season;
  final VoidCallback onBack;
  final VoidCallback onLocker;

  @override
  Widget build(BuildContext context) {
    final days = (season.remaining.inHours / 24).ceil();
    final tier = season.currentTier.clamp(1, 30);
    final next = season.nextTierCharge;
    final remaining = next == null ? 0 : (next - season.charge).clamp(0, 999999);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1730), Color(0xFF07111D), Color(0xFF100A25)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ReactColors.electricBlueBright.withValues(alpha: .38),
          ),
          boxShadow: [
            BoxShadow(
              color: ReactColors.electricBlueBright.withValues(alpha: .07),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  color: ReactColors.textPrimary,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        season.subtitle.toUpperCase(),
                        style: const TextStyle(
                          color: ReactColors.electricBlueBright,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Season locker',
                  onPressed: onLocker,
                  style: IconButton.styleFrom(
                    foregroundColor: ReactColors.purple,
                    backgroundColor: ReactColors.purple.withValues(alpha: .08),
                    side: BorderSide(
                      color: ReactColors.purple.withValues(alpha: .35),
                    ),
                  ),
                  icon: const Icon(Icons.checkroom_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ReactColors.electricBlueBright.withValues(alpha: .07),
                    border: Border.all(
                      color: ReactColors.electricBlueBright.withValues(alpha: .5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ReactColors.electricBlueBright.withValues(alpha: .12),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TIER',
                        style: TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '$tier',
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '/ 30',
                        style: TextStyle(
                          color: ReactColors.electricBlueBright,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _HeroStat(
                            icon: Icons.bolt_rounded,
                            value: '${season.charge}',
                            label: 'CHARGE',
                            color: ReactColors.electricBlueBright,
                          ),
                          const SizedBox(width: 8),
                          _HeroStat(
                            icon: Icons.timer_outlined,
                            value: '$days',
                            label: 'DAYS LEFT',
                            color: ReactColors.coral,
                          ),
                          const SizedBox(width: 8),
                          _HeroStat(
                            icon: season.premiumOwned
                                ? Icons.workspace_premium_rounded
                                : Icons.lock_outline_rounded,
                            value: season.premiumOwned ? 'ON' : 'OFF',
                            label: 'PREMIUM',
                            color: ReactColors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'NEXT TIER',
                            style: TextStyle(
                              color: ReactColors.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            next == null ? 'MAXED' : '$remaining CHARGE TO GO',
                            style: const TextStyle(
                              color: ReactColors.textPrimary,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: season.tierProgress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: .07),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                label,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 6.8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonTabs extends StatelessWidget {
  const _SeasonTabs();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: TabBar(
        indicatorColor: ReactColors.electricBlueBright,
        indicatorWeight: 3,
        labelColor: ReactColors.textPrimary,
        unselectedLabelColor: ReactColors.textSecondary,
        labelStyle: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
        tabs: [
          Tab(text: 'PASS'),
          Tab(text: 'MISSIONS'),
          Tab(text: 'SEASON INFO'),
        ],
      ),
    );
  }
}

class _PassTab extends StatelessWidget {
  const _PassTab({
    required this.season,
    required this.onRefresh,
    required this.onLocker,
  });

  final SeasonSnapshot season;
  final Future<void> Function() onRefresh;
  final VoidCallback onLocker;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        itemCount: season.tiers.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PassIntro(season: season, onLocker: onLocker);
          }
          if (index == 1) return const _TrackHeader();
          return _TierRoadCard(
            season: season,
            tier: season.tiers[index - 2],
          );
        },
      ),
    );
  }
}

class _PassIntro extends StatelessWidget {
  const _PassIntro({required this.season, required this.onLocker});

  final SeasonSnapshot season;
  final VoidCallback onLocker;

  @override
  Widget build(BuildContext context) {
    final reached = season.tiers
        .where((tier) => season.charge >= tier.chargeRequired)
        .length;
    final unlocked = season.unlockedRewardKeys.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: ReactColors.electricBlueBright,
                size: 22,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR REWARD ROAD',
                      style: TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'EARN CHARGE. REACH TIERS. EQUIP COSMETICS FROM THE LOCKER.',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 7.5,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .45,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onLocker,
                icon: const Icon(Icons.checkroom_rounded, size: 16),
                label: const Text('LOCKER'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(value: '$reached/30', label: 'TIERS REACHED'),
              const SizedBox(width: 8),
              _MiniStat(value: '$unlocked', label: 'REWARDS OWNED'),
              const SizedBox(width: 8),
              _MiniStat(
                value: season.premiumOwned ? 'ACTIVE' : 'LOCKED',
                label: 'PREMIUM TRACK',
                color: ReactColors.purple,
              ),
            ],
          ),
          if (season.premiumOwned) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: ReactColors.purple.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ReactColors.purple.withValues(alpha: .22),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: ReactColors.purple,
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'PREMIUM ACTIVE — REACHED PREMIUM REWARDS ARE AVAILABLE IN YOUR LOCKER.',
                      style: TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 7.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    this.color = ReactColors.electricBlueBright,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .16)),
        ),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                label,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 6.7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 46),
        SizedBox(width: 9),
        Expanded(
          child: _TrackTitle(
            icon: Icons.bolt_rounded,
            label: 'FREE',
            color: ReactColors.electricBlueBright,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _TrackTitle(
            icon: Icons.workspace_premium_rounded,
            label: 'PREMIUM',
            color: ReactColors.purple,
          ),
        ),
      ],
    );
  }
}

class _TrackTitle extends StatelessWidget {
  const _TrackTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _TierRoadCard extends StatelessWidget {
  const _TierRoadCard({required this.season, required this.tier});

  final SeasonSnapshot season;
  final SeasonTier tier;

  @override
  Widget build(BuildContext context) {
    final reached = season.charge >= tier.chargeRequired;
    final current = season.currentTier == tier.number;
    final free = tier.freeRewards.firstOrNull;
    final premium = tier.premiumRewards.firstOrNull;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tier.milestone
            ? ReactColors.lime.withValues(alpha: .035)
            : current
            ? ReactColors.electricBlueBright.withValues(alpha: .035)
            : const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tier.milestone
              ? ReactColors.lime.withValues(alpha: .38)
              : current
              ? ReactColors.electricBlueBright.withValues(alpha: .42)
              : Colors.white.withValues(alpha: .065),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached
                        ? ReactColors.electricBlueBright.withValues(alpha: .11)
                        : Colors.white.withValues(alpha: .025),
                    border: Border.all(
                      color: reached
                          ? ReactColors.electricBlueBright.withValues(alpha: .5)
                          : Colors.white.withValues(alpha: .1),
                    ),
                  ),
                  child: Text(
                    '${tier.number}',
                    style: TextStyle(
                      color: reached
                          ? ReactColors.textPrimary
                          : ReactColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${tier.chargeRequired}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 6.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (tier.milestone) ...[
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: ReactColors.lime,
                    size: 15,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _RewardTile(
              reward: free,
              reached: reached,
              unlocked: free != null && season.isUnlocked(free),
              premiumOwned: true,
              color: ReactColors.electricBlueBright,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RewardTile(
              reward: premium,
              reached: reached,
              unlocked: premium != null && season.isUnlocked(premium),
              premiumOwned: season.premiumOwned,
              color: ReactColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.reward,
    required this.reached,
    required this.unlocked,
    required this.premiumOwned,
    required this.color,
  });

  final SeasonReward? reward;
  final bool reached;
  final bool unlocked;
  final bool premiumOwned;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final item = reward;
    if (item == null) return const SizedBox.shrink();
    final lockedPremium = item.isPremium && !premiumOwned;
    final stateLabel = unlocked
        ? 'OWNED'
        : lockedPremium && reached
        ? 'REACHED • PREMIUM'
        : reached
        ? 'REACHED'
        : 'LOCKED';
    final stateColor = unlocked
        ? ReactColors.lime
        : lockedPremium
        ? ReactColors.purple
        : reached
        ? color
        : ReactColors.textSecondary;

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: unlocked ? .075 : .035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: unlocked ? .32 : .12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: color.withValues(alpha: .10),
                ),
                child: Icon(_rewardIcon(item.kind), color: color, size: 15),
              ),
              const Spacer(),
              Icon(
                unlocked
                    ? Icons.check_circle_rounded
                    : lockedPremium
                    ? Icons.lock_outline_rounded
                    : reached
                    ? Icons.redeem_rounded
                    : Icons.lock_clock_outlined,
                color: stateColor,
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: .25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _rewardKindLabel(item.kind),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 6.8,
              fontWeight: FontWeight.w900,
              letterSpacing: .55,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 6),
          Text(
            stateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: stateColor,
              fontSize: 6.8,
              fontWeight: FontWeight.w900,
              letterSpacing: .45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionsTab extends StatelessWidget {
  const _MissionsTab({required this.season, required this.onRefresh});

  final SeasonSnapshot season;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          const _MissionIntro(),
          const SizedBox(height: 16),
          for (final cadence in SeasonMissionCadence.values) ...[
            _MissionSectionTitle(cadence: cadence),
            const SizedBox(height: 8),
            for (final mission in season.missions.where(
              (item) => item.cadence == cadence,
            )) ...[
              _MissionCard(mission: mission),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _MissionIntro extends StatelessWidget {
  const _MissionIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071A2C), Color(0xFF0E0A20)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ReactColors.electricBlueBright.withValues(alpha: .22),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: ReactColors.electricBlueBright,
            size: 25,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSIONS = EXTRA CHARGE',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .65,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'DAILY, WEEKLY AND SEASON GOALS FEED THE SAME PASS PROGRESSION.',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7.8,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
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

class _MissionSectionTitle extends StatelessWidget {
  const _MissionSectionTitle({required this.cadence});

  final SeasonMissionCadence cadence;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (cadence) {
      SeasonMissionCadence.daily => (
          'DAILY MISSIONS',
          ReactColors.electricBlueBright,
          Icons.today_rounded,
        ),
      SeasonMissionCadence.weekly => (
          'WEEKLY MISSIONS',
          ReactColors.purple,
          Icons.date_range_rounded,
        ),
      SeasonMissionCadence.season => (
          'SEASON MISSIONS',
          ReactColors.lime,
          Icons.flag_rounded,
        ),
    };
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(child: Divider(color: color.withValues(alpha: .22))),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final SeasonMission mission;

  @override
  Widget build(BuildContext context) {
    final color = switch (mission.cadence) {
      SeasonMissionCadence.daily => ReactColors.electricBlueBright,
      SeasonMissionCadence.weekly => ReactColors.purple,
      SeasonMissionCadence.season => ReactColors.lime,
    };
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mission.completed
              ? ReactColors.lime.withValues(alpha: .38)
              : color.withValues(alpha: .16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: .08),
                ),
                child: Icon(
                  mission.completed
                      ? Icons.check_rounded
                      : Icons.bolt_rounded,
                  color: mission.completed ? ReactColors.lime : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.name,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mission.description,
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: ReactColors.electricBlueBright.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: ReactColors.electricBlueBright.withValues(alpha: .22),
                  ),
                ),
                child: Text(
                  '+${mission.chargeReward}',
                  style: const TextStyle(
                    color: ReactColors.electricBlueBright,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: mission.progressFraction,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: .06),
                    color: mission.completed ? ReactColors.lime : color,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '${mission.progress.clamp(0, mission.target)}/${mission.target}',
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeasonInfoTab extends StatelessWidget {
  const _SeasonInfoTab({required this.season});

  final SeasonSnapshot season;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
      children: [
        _SeasonWindowCard(season: season),
        const SizedBox(height: 11),
        const _InfoCard(
          icon: Icons.bolt_rounded,
          title: 'HOW YOU PROGRESS',
          body:
              'Runs earn CHARGE. Personal bests, Daily runs, your first play of the day, and mission completions add bonus CHARGE.',
          color: ReactColors.electricBlueBright,
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.workspace_premium_rounded,
          title: 'FREE + PREMIUM',
          body:
              'Both tracks use the same tier progress. If Premium is activated later, Premium rewards from tiers you already reached unlock retroactively.',
          color: ReactColors.purple,
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.shield_outlined,
          title: 'NO PAY-TO-WIN',
          body:
              'Every season reward is cosmetic. Nothing changes score rules, timers, lives, command difficulty, reaction windows, or leaderboard eligibility.',
          color: ReactColors.lime,
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.checkroom_rounded,
          title: 'WHAT THE LOCKER DOES',
          body:
              'The Locker stores unlocked cosmetics. Each item tells you exactly what it changes, where it appears, and whether it is currently equipped.',
          color: ReactColors.coral,
        ),
      ],
    );
  }
}

class _SeasonWindowCard extends StatelessWidget {
  const _SeasonWindowCard({required this.season});

  final SeasonSnapshot season;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08172B), Color(0xFF0D0A1F)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ReactColors.electricBlueBright.withValues(alpha: .24),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: ReactColors.electricBlueBright,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '21-DAY SEASON WINDOW',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .65,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_date(season.startsAt)}  →  ${_date(season.endsAt)} UTC',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: .08),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
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

class _LoadingSeason extends StatelessWidget {
  const _LoadingSeason();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'LOADING SEASON PASS',
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSeason extends StatelessWidget {
  const _NoSeason({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              color: ReactColors.textPrimary,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: ReactColors.coral,
                    size: 38,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SEASON PASS UNAVAILABLE',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: onRetry, child: const Text('RETRY')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _rewardIcon(String kind) => switch (kind) {
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

String _rewardKindLabel(String kind) => switch (kind) {
      'reaction_pack' => 'REACTION COLOUR',
      'command_style' => 'COMMAND STYLE',
      'countdown_style' => 'COUNTDOWN',
      'sound_pack' => 'SOUND PACK',
      'share_style' => 'SHARE STYLE',
      'profile_frame' => 'PROFILE FRAME',
      'profile_badge' => 'PROFILE BADGE',
      'player_code_style' => 'PLAYER CODE',
      'home_theme' => 'HOME THEME',
      'score_effect' => 'SCORE EFFECT',
      'success_effect' => 'SUCCESS EFFECT',
      'failure_effect' => 'FAILURE EFFECT',
      'mode_card_skin' => 'MODE CARD SKIN',
      'title' => 'PLAYER TITLE',
      'emblem' => 'EMBLEM',
      _ => kind.replaceAll('_', ' ').toUpperCase(),
    };

String _date(DateTime value) {
  const months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}
