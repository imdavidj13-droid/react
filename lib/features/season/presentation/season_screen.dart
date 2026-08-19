import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/season_repository.dart';
import '../domain/season_models.dart';

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

  void _reload() {
    _season = _repository.loadActiveSeason();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _season;
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
              return const Center(child: CircularProgressIndicator());
            }

            final season = snapshot.data;
            if (season == null) {
              return _NoSeason(onBack: () => Navigator.of(context).pop());
            }

            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _SeasonHeader(
                    season: season,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: TabBar(
                      indicatorColor: ReactColors.electricBlueBright,
                      labelColor: ReactColors.textPrimary,
                      unselectedLabelColor: ReactColors.textSecondary,
                      labelStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                      tabs: [
                        Tab(text: 'PASS'),
                        Tab(text: 'MISSIONS'),
                        Tab(text: 'SEASON INFO'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PassTab(season: season, onRefresh: _refresh),
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

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({required this.season, required this.onBack});

  final SeasonSnapshot season;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final days = (season.remaining.inHours / 24).ceil();
    final next = season.nextTierCharge;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: ReactColors.textPrimary,
              ),
              const SizedBox(width: 4),
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
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${season.subtitle}  •  $days DAYS LEFT',
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              _ChargePill(value: season.charge),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'TIER ${season.currentTier.clamp(1, 30)}',
                style: const TextStyle(
                  color: ReactColors.electricBlueBright,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: season.tierProgress,
                    minHeight: 7,
                    backgroundColor: ReactColors.electricBlueBright.withValues(
                      alpha: .12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                next == null ? 'MAX' : '$next CHARGE',
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassTab extends StatelessWidget {
  const _PassTab({required this.season, required this.onRefresh});

  final SeasonSnapshot season;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        itemCount: season.tiers.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 9),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TrackLegend(premiumOwned: season.premiumOwned);
          }
          final tier = season.tiers[index - 1];
          return _TierCard(season: season, tier: tier);
        },
      ),
    );
  }
}

class _TrackLegend extends StatelessWidget {
  const _TrackLegend({required this.premiumOwned});

  final bool premiumOwned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF09121E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _LegendItem(
              icon: Icons.bolt_rounded,
              label: 'FREE TRACK',
              color: ReactColors.electricBlueBright,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withValues(alpha: .08),
          ),
          Expanded(
            child: _LegendItem(
              icon: premiumOwned
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_outline_rounded,
              label: premiumOwned ? 'PREMIUM ACTIVE' : 'PREMIUM TRACK',
              color: ReactColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
      ),
    ],
  );
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.season, required this.tier});

  final SeasonSnapshot season;
  final SeasonTier tier;

  @override
  Widget build(BuildContext context) {
    final reached = season.charge >= tier.chargeRequired;
    final borderColor = tier.milestone
        ? ReactColors.lime.withValues(alpha: .55)
        : reached
        ? ReactColors.electricBlueBright.withValues(alpha: .38)
        : Colors.white.withValues(alpha: .07);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tier.milestone
            ? ReactColors.lime.withValues(alpha: .045)
            : const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 45,
            child: Column(
              children: [
                Text(
                  '${tier.number}',
                  style: TextStyle(
                    color: reached
                        ? ReactColors.textPrimary
                        : ReactColors.textSecondary,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${tier.chargeRequired}',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (tier.milestone) ...[
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: ReactColors.lime,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              children: [
                _RewardLane(
                  label: 'FREE',
                  rewards: tier.freeRewards.toList(),
                  season: season,
                  reached: reached,
                  color: ReactColors.electricBlueBright,
                  premiumLocked: false,
                ),
                const SizedBox(height: 8),
                _RewardLane(
                  label: 'PREMIUM',
                  rewards: tier.premiumRewards.toList(),
                  season: season,
                  reached: reached,
                  color: ReactColors.purple,
                  premiumLocked: !season.premiumOwned,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardLane extends StatelessWidget {
  const _RewardLane({
    required this.label,
    required this.rewards,
    required this.season,
    required this.reached,
    required this.color,
    required this.premiumLocked,
  });

  final String label;
  final List<SeasonReward> rewards;
  final SeasonSnapshot season;
  final bool reached;
  final Color color;
  final bool premiumLocked;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) return const SizedBox.shrink();
    final reward = rewards.first;
    final unlocked = season.isUnlocked(reward);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(
            unlocked
                ? Icons.check_circle_rounded
                : premiumLocked
                ? Icons.lock_outline_rounded
                : reached
                ? Icons.redeem_rounded
                : Icons.circle_outlined,
            size: 17,
            color: unlocked ? ReactColors.lime : color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label  •  ${reward.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  premiumLocked && reached
                      ? 'UNLOCKS RETROACTIVELY WITH PREMIUM'
                      : reward.description.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
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

class _MissionsTab extends StatelessWidget {
  const _MissionsTab({required this.season, required this.onRefresh});

  final SeasonSnapshot season;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          for (final cadence in SeasonMissionCadence.values) ...[
            _MissionSectionTitle(cadence: cadence),
            const SizedBox(height: 8),
            for (final mission in season.missions.where(
              (mission) => mission.cadence == cadence,
            )) ...[
              _MissionCard(mission: mission),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
          ],
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
    final label = switch (cadence) {
      SeasonMissionCadence.daily => 'DAILY MISSIONS',
      SeasonMissionCadence.weekly => 'WEEKLY MISSIONS',
      SeasonMissionCadence.season => 'SEASON MISSIONS',
    };
    return Text(
      label,
      style: const TextStyle(
        color: ReactColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final SeasonMission mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF08111C),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: mission.completed
              ? ReactColors.lime.withValues(alpha: .35)
              : Colors.white.withValues(alpha: .07),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                mission.completed
                    ? Icons.check_circle_rounded
                    : Icons.bolt_rounded,
                color: mission.completed
                    ? ReactColors.lime
                    : ReactColors.electricBlueBright,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.name,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.description,
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${mission.chargeReward}',
                style: const TextStyle(
                  color: ReactColors.electricBlueBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: mission.progressFraction,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: .07),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '${mission.progress.clamp(0, mission.target)}/${mission.target}',
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
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
        _InfoCard(
          icon: Icons.calendar_month_rounded,
          title: '21-DAY SEASON',
          body:
              'Season timing is controlled by the RE△CT server. Progress closes when the season window ends.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.bolt_rounded,
          title: 'EARN CHARGE',
          body:
              'Complete runs, set personal bests, play the Daily, make your first play of the day, and finish missions.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.workspace_premium_rounded,
          title: 'FREE + PREMIUM',
          body:
              'Both tracks share the same CHARGE progression. If Premium is activated later, every Premium reward from tiers already reached unlocks automatically.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.shield_outlined,
          title: 'COSMETICS ONLY',
          body:
              'Season rewards never increase score, reaction time, lives, timers, leaderboard eligibility, or gameplay power.',
        ),
        const SizedBox(height: 18),
        Text(
          'SEASON WINDOW\n${_date(season.startsAt)} — ${_date(season.endsAt)} UTC',
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 10,
            height: 1.5,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
      ],
    );
  }

  static String _date(DateTime value) {
    const months = <String>[
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF08111C),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ReactColors.electricBlueBright, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 10,
                  height: 1.45,
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

class _ChargePill extends StatelessWidget {
  const _ChargePill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: ReactColors.electricBlueBright.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: ReactColors.electricBlueBright.withValues(alpha: .3),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.bolt_rounded,
          size: 15,
          color: ReactColors.electricBlueBright,
        ),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: const TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _NoSeason extends StatelessWidget {
  const _NoSeason({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: ReactColors.textPrimary,
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'NO ACTIVE SEASON',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
