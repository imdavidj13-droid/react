enum SeasonRewardTrack { free, premium }

enum SeasonMissionCadence { daily, weekly, season }

class SeasonReward {
  const SeasonReward({
    required this.id,
    required this.tier,
    required this.track,
    required this.kind,
    required this.rewardKey,
    required this.name,
    required this.description,
    required this.milestone,
    this.payload = const <String, dynamic>{},
  });

  final String id;
  final int tier;
  final SeasonRewardTrack track;
  final String kind;
  final String rewardKey;
  final String name;
  final String description;
  final bool milestone;
  final Map<String, dynamic> payload;

  bool get isPremium => track == SeasonRewardTrack.premium;
}

class SeasonTier {
  const SeasonTier({
    required this.number,
    required this.chargeRequired,
    required this.milestone,
    required this.rewards,
  });

  final int number;
  final int chargeRequired;
  final bool milestone;
  final List<SeasonReward> rewards;

  Iterable<SeasonReward> get freeRewards =>
      rewards.where((reward) => !reward.isPremium);

  Iterable<SeasonReward> get premiumRewards =>
      rewards.where((reward) => reward.isPremium);
}

class SeasonMission {
  const SeasonMission({
    required this.id,
    required this.cadence,
    required this.metric,
    required this.name,
    required this.description,
    required this.target,
    required this.progress,
    required this.chargeReward,
    required this.periodKey,
    required this.completed,
  });

  final String id;
  final SeasonMissionCadence cadence;
  final String metric;
  final String name;
  final String description;
  final int target;
  final int progress;
  final int chargeReward;
  final String periodKey;
  final bool completed;

  double get progressFraction {
    if (target <= 0) return 1;
    return (progress / target).clamp(0.0, 1.0).toDouble();
  }
}

class SeasonSnapshot {
  const SeasonSnapshot({
    required this.id,
    required this.code,
    required this.name,
    required this.subtitle,
    required this.themeKey,
    required this.startsAt,
    required this.endsAt,
    required this.charge,
    required this.premiumOwned,
    required this.tiers,
    required this.missions,
    required this.unlockedRewardKeys,
  });

  final String id;
  final String code;
  final String name;
  final String subtitle;
  final String themeKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final int charge;
  final bool premiumOwned;
  final List<SeasonTier> tiers;
  final List<SeasonMission> missions;
  final Set<String> unlockedRewardKeys;

  int get currentTier {
    var reached = 0;
    for (final tier in tiers) {
      if (charge >= tier.chargeRequired) reached = tier.number;
    }
    return reached.clamp(0, 30);
  }

  int? get nextTierCharge {
    for (final tier in tiers) {
      if (tier.chargeRequired > charge) return tier.chargeRequired;
    }
    return null;
  }

  int get chargeIntoTier {
    final reached = tiers
        .where((tier) => tier.chargeRequired <= charge)
        .fold<int>(0, (value, tier) => tier.chargeRequired > value
            ? tier.chargeRequired
            : value);
    return charge - reached;
  }

  int get chargeForNextTier {
    final next = nextTierCharge;
    if (next == null) return 0;
    final reached = charge - chargeIntoTier;
    return next - reached;
  }

  double get tierProgress {
    final required = chargeForNextTier;
    if (required <= 0) return 1;
    return (chargeIntoTier / required).clamp(0.0, 1.0).toDouble();
  }

  Duration get remaining {
    final value = endsAt.difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  bool isUnlocked(SeasonReward reward) =>
      unlockedRewardKeys.contains(reward.rewardKey);
}
