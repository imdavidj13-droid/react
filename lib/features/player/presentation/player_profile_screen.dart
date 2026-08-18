import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/backend/react_supabase.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_command_performance.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../leaderboard/data/local_leaderboard_repository.dart';
import '../../leaderboard/domain/leaderboard_query.dart';
import '../../leaderboard/domain/leaderboard_snapshot.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/local_player_profile.dart';
import '../data/player_profile_repository.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  static const _repository = PlayerProfileRepository();

  late Future<_ProfileViewData> _data;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = _ProfileViewData.load(_repository);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _data;
  }

  Future<void> _editName(PlayerProfileData profile) async {
    final controller = TextEditingController(text: profile.displayName);
    String? errorText;

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF07111D),
          title: const Text('EDIT PLAYER NAME'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Display name',
              hintText: 'PLAYER NAME',
              errorText: errorText,
            ),
            onSubmitted: (_) {
              final validation =
                  LocalPlayerProfile.validateDisplayName(controller.text);
              if (validation != null) {
                setDialogState(() => errorText = validation);
                return;
              }
              Navigator.of(dialogContext).pop(controller.text);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                final validation =
                    LocalPlayerProfile.validateDisplayName(controller.text);
                if (validation != null) {
                  setDialogState(() => errorText = validation);
                  return;
                }
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value == null || value.trim() == profile.displayName) return;

    setState(() => _busy = true);
    try {
      await _repository.updateDisplayName(profile, value);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player name updated.')),
      );
    } on DisplayNameUnavailableException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That player name is already in use.')),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${error.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the player name.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choosePhoto(PlayerProfileData profile) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (image == null) return;

    final extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a JPG, PNG or WebP image.')),
      );
      return;
    }

    final contentType = image.mimeType ?? switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    setState(() => _busy = true);
    try {
      final bytes = await image.readAsBytes();
      await _repository.uploadAvatar(
        current: profile,
        bytes: bytes,
        extension: extension,
        contentType: contentType,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${error.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload the profile photo.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto(PlayerProfileData profile) async {
    setState(() => _busy = true);
    try {
      await _repository.removeAvatar(profile);
      if (!mounted) return;
      setState(_reload);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<_ProfileViewData>(
          future: _data,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                children: [
                  _Header(
                    onBack: () => Navigator.of(context).pop(),
                    onSettings: _openSettings,
                  ),
                  const SizedBox(height: 20),
                  if (data == null)
                    const SizedBox(
                      height: 420,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _IdentityHero(
                      profile: data.profile,
                      busy: _busy,
                      onEditName: () => _editName(data.profile),
                      onPhoto: () => _choosePhoto(data.profile),
                      onRemovePhoto: data.profile.avatarUrl == null
                          ? null
                          : () => _removePhoto(data.profile),
                    ),
                    const SizedBox(height: 14),
                    _IdentityPanel(profile: data.profile),
                    const SizedBox(height: 18),
                    const _SectionTitle('LIFETIME PERFORMANCE'),
                    const SizedBox(height: 9),
                    _LifetimeGrid(stats: data.stats),
                    const SizedBox(height: 18),
                    const _SectionTitle('SKILL SNAPSHOT'),
                    const SizedBox(height: 9),
                    _SkillSnapshot(stats: data.stats),
                    const SizedBox(height: 18),
                    const _SectionTitle('GLOBAL PLACEMENTS'),
                    const SizedBox(height: 9),
                    _PlacementsCard(stats: data.stats),
                    const SizedBox(height: 18),
                    const _SectionTitle('PERSONAL BESTS'),
                    const SizedBox(height: 9),
                    _PersonalBests(stats: data.stats),
                    const SizedBox(height: 18),
                    _AccountCard(profile: data.profile),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileViewData {
  const _ProfileViewData({required this.profile, required this.stats});

  final PlayerProfileData profile;
  final _PlayerStats stats;

  static Future<_ProfileViewData> load(PlayerProfileRepository repository) async {
    final values = await Future.wait<Object>([
      repository.load(),
      _PlayerStats.load(),
    ]);
    return _ProfileViewData(
      profile: values[0] as PlayerProfileData,
      stats: values[1] as _PlayerStats,
    );
  }
}

class _PlayerStats {
  const _PlayerStats({
    required this.runs,
    required this.commands,
    required this.accuracy,
    required this.averageReactionSeconds,
    required this.bestStreak,
    required this.bestSequenceStreak,
    required this.dailyStreak,
    required this.favoriteMode,
    required this.strongestCommand,
    required this.classic,
    required this.blitz,
    required this.endless,
    required this.daily,
    required this.sequence,
    required this.placements,
    required this.onlineRanksAvailable,
  });

  final int runs;
  final int commands;
  final double accuracy;
  final double averageReactionSeconds;
  final int bestStreak;
  final int bestSequenceStreak;
  final int dailyStreak;
  final String favoriteMode;
  final String strongestCommand;
  final int classic;
  final int blitz;
  final int endless;
  final int daily;
  final int sequence;
  final List<_Placement> placements;
  final bool onlineRanksAvailable;

  static Future<_PlayerStats> load() async {
    const leaderboard = LocalLeaderboardRepository();
    const competitiveModes = <ReactGameMode>[
      ReactGameMode.classic,
      ReactGameMode.blitz,
      ReactGameMode.endless,
      ReactGameMode.sequence,
    ];

    final modeRuns = await Future.wait<int>([
      for (final mode in competitiveModes) LocalPlayerStats.runsFor(mode),
    ]);
    final modeCommands = await Future.wait<int>([
      for (final mode in competitiveModes)
        LocalPlayerStats.successfulCommandsFor(mode),
    ]);
    final modeAverages = await Future.wait<double>([
      for (final mode in competitiveModes)
        LocalPlayerStats.averageReactionSecondsFor(mode),
    ]);
    final commandPerformance = await LocalPlayerStats.commandPerformance();
    final lifetimeAccuracy = await LocalPlayerStats.lifetimeAccuracy();

    final placementSnapshots = await Future.wait<LeaderboardSnapshot>([
      for (final mode in competitiveModes)
        leaderboard.load(
          LeaderboardQuery(scope: LeaderboardScope.global, mode: mode),
        ),
      leaderboard.load(
        LeaderboardQuery(
          scope: LeaderboardScope.daily,
          mode: ReactGameMode.daily,
          dailyDate: DateTime.now(),
        ),
      ),
    ]);

    var weightedReaction = 0.0;
    var weightedCommands = 0;
    for (var index = 0; index < competitiveModes.length; index++) {
      final count = modeCommands[index];
      final average = modeAverages[index];
      if (count <= 0 || average <= 0) continue;
      weightedReaction += average * count;
      weightedCommands += count;
    }

    final rankedCommands = commandPerformance
        .where((item) => item.attempts >= 3)
        .toList(growable: false)
      ..sort((a, b) {
        final accuracyOrder = b.accuracy.compareTo(a.accuracy);
        if (accuracyOrder != 0) return accuracyOrder;
        return b.attempts.compareTo(a.attempts);
      });

    var favoriteMode = 'NOT ENOUGH DATA';
    var favoriteRuns = 0;
    for (var index = 0; index < competitiveModes.length; index++) {
      if (modeRuns[index] > favoriteRuns) {
        favoriteRuns = modeRuns[index];
        favoriteMode = competitiveModes[index].label;
      }
    }

    final placements = <_Placement>[
      for (var index = 0; index < competitiveModes.length; index++)
        _Placement(
          label: competitiveModes[index].label,
          rank: placementSnapshots[index].isLocalPreview
              ? null
              : placementSnapshots[index].currentPlayerRank,
        ),
      _Placement(
        label: 'DAILY',
        rank: placementSnapshots.last.isLocalPreview
            ? null
            : placementSnapshots.last.currentPlayerRank,
      ),
    ];

    return _PlayerStats(
      runs: await LocalPlayerStats.runsPlayed(),
      commands: await LocalPlayerStats.totalSuccessfulCommands(),
      accuracy: lifetimeAccuracy,
      averageReactionSeconds:
          weightedCommands == 0 ? 0 : weightedReaction / weightedCommands,
      bestStreak: await LocalPlayerStats.bestCommandStreak(),
      bestSequenceStreak: await LocalPlayerStats.bestSequenceStreak(),
      dailyStreak: await LocalPlayerStats.dailyStreak(),
      favoriteMode: favoriteMode,
      strongestCommand: rankedCommands.isEmpty
          ? 'NOT ENOUGH DATA'
          : _commandLabel(rankedCommands.first),
      classic: await LocalPlayerStats.bestFor(ReactGameMode.classic),
      blitz: await LocalPlayerStats.bestFor(ReactGameMode.blitz),
      endless: await LocalPlayerStats.bestFor(ReactGameMode.endless),
      daily: await LocalPlayerStats.bestFor(ReactGameMode.daily),
      sequence: await LocalPlayerStats.bestFor(ReactGameMode.sequence),
      placements: placements,
      onlineRanksAvailable:
          placementSnapshots.any((snapshot) => !snapshot.isLocalPreview),
    );
  }

  static String _commandLabel(ReactCommandPerformance performance) {
    final raw = performance.command.name;
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      final char = raw[index];
      if (index > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
        buffer.write(' ');
      }
      buffer.write(char.toUpperCase());
    }
    return buffer.toString();
  }
}

class _Placement {
  const _Placement({required this.label, required this.rank});

  final String label;
  final int? rank;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            side: const BorderSide(color: Color(0xFF203854)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'PLAYER PROFILE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            side: const BorderSide(color: Color(0xFF203854)),
          ),
          icon: const Icon(Icons.settings_outlined, size: 21),
        ),
      ],
    );
  }
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.profile,
    required this.busy,
    required this.onEditName,
    required this.onPhoto,
    required this.onRemovePhoto,
  });

  final PlayerProfileData profile;
  final bool busy;
  final VoidCallback onEditName;
  final VoidCallback onPhoto;
  final VoidCallback? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: ReactColors.electricBlueBright.withValues(alpha: .52),
        ),
        boxShadow: [
          BoxShadow(
            color: ReactColors.electricBlueBright.withValues(alpha: .08),
            blurRadius: 26,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _Avatar(url: profile.avatarUrl),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: ReactColors.electricBlueBright,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: busy ? null : onPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: Color(0xFF020711),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Edit player name',
                onPressed: busy ? null : onEditName,
                icon: const Icon(Icons.edit_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            profile.playerCode,
            style: const TextStyle(
              color: ReactColors.electricBlueBright,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _StatusPill(profile: profile),
          if (onRemovePhoto != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: busy ? null : onRemovePhoto,
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('REMOVE PHOTO'),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.profile});

  final PlayerProfileData profile;

  @override
  Widget build(BuildContext context) {
    final color = profile.isAnonymous ? ReactColors.purple : ReactColors.lime;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Text(
        profile.isAnonymous ? 'GUEST PLAYER' : 'SECURED PLAYER',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF040A13),
        border: Border.all(color: ReactColors.electricBlueBright, width: 2.5),
      ),
      child: url == null
          ? const Icon(
              Icons.person_rounded,
              color: ReactColors.electricBlueBright,
              size: 58,
            )
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person_rounded,
                color: ReactColors.electricBlueBright,
                size: 58,
              ),
            ),
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({required this.profile});

  final PlayerProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          _InfoRow(
            label: 'PLAYER ID',
            value: profile.playerCode,
            icon: Icons.fingerprint_rounded,
          ),
          const Divider(color: Color(0xFF1B3048)),
          _InfoRow(
            label: 'JOINED',
            value: _formatDate(profile.createdAt),
            icon: Icons.calendar_today_outlined,
          ),
          const Divider(color: Color(0xFF1B3048)),
          _InfoRow(
            label: 'PROFILE SYNC',
            value: profile.isCloudBacked ? 'CONNECTED' : 'OFFLINE',
            icon: profile.isCloudBacked
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            valueColor:
                profile.isCloudBacked ? ReactColors.lime : ReactColors.coral,
          ),
        ],
      ),
    );
  }
}

class _LifetimeGrid extends StatelessWidget {
  const _LifetimeGrid({required this.stats});

  final _PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 45) / 2;
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        _MetricCard(
          width: width,
          label: 'RUNS PLAYED',
          value: '${stats.runs}',
          color: ReactColors.electricBlueBright,
        ),
        _MetricCard(
          width: width,
          label: 'COMMANDS CLEARED',
          value: '${stats.commands}',
          color: ReactColors.lime,
        ),
        _MetricCard(
          width: width,
          label: 'LIFETIME ACCURACY',
          value: stats.accuracy <= 0
              ? '--'
              : '${(stats.accuracy * 100).toStringAsFixed(1)}%',
          color: ReactColors.purple,
        ),
        _MetricCard(
          width: width,
          label: 'AVG REACTION',
          value: stats.averageReactionSeconds <= 0
              ? '--'
              : '${stats.averageReactionSeconds.toStringAsFixed(2)}s',
          color: ReactColors.coral,
        ),
      ],
    );
  }
}

class _SkillSnapshot extends StatelessWidget {
  const _SkillSnapshot({required this.stats});

  final _PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          _InfoRow(
            label: 'BEST COMMAND STREAK',
            value: '${stats.bestStreak}',
            icon: Icons.bolt_rounded,
            valueColor: ReactColors.lime,
          ),
          const Divider(color: Color(0xFF1B3048)),
          _InfoRow(
            label: 'BEST SEQUENCE STREAK',
            value: '${stats.bestSequenceStreak}',
            icon: Icons.blur_on_rounded,
            valueColor: ReactColors.electricBlueBright,
          ),
          const Divider(color: Color(0xFF1B3048)),
          _InfoRow(
            label: 'DAILY STREAK',
            value: '${stats.dailyStreak}',
            icon: Icons.local_fire_department_outlined,
            valueColor: ReactColors.coral,
          ),
          const Divider(color: Color(0xFF1B3048)),
          _InfoRow(
            label: 'FAVOURITE MODE',
            value: stats.favoriteMode,
            icon: Icons.favorite_border_rounded,
          ),
          const Divider(color: Color(0xFF1B3048)),
          _InfoRow(
            label: 'STRONGEST COMMAND',
            value: stats.strongestCommand,
            icon: Icons.auto_graph_rounded,
          ),
        ],
      ),
    );
  }
}

class _PlacementsCard extends StatelessWidget {
  const _PlacementsCard({required this.stats});

  final _PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                stats.onlineRanksAvailable
                    ? Icons.public_rounded
                    : Icons.cloud_off_rounded,
                size: 18,
                color: stats.onlineRanksAvailable
                    ? ReactColors.lime
                    : ReactColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats.onlineRanksAvailable
                      ? 'LIVE COMPETITIVE RANKS'
                      : 'ONLINE RANKS UNAVAILABLE',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final placement in stats.placements)
                _PlacementChip(placement: placement),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlacementChip extends StatelessWidget {
  const _PlacementChip({required this.placement});

  final _Placement placement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 70) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF091523),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              placement.label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
          Text(
            placement.rank == null ? 'UNRANKED' : '#${placement.rank}',
            style: TextStyle(
              color: placement.rank == null
                  ? ReactColors.textSecondary
                  : ReactColors.lime,
              fontSize: placement.rank == null ? 8 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalBests extends StatelessWidget {
  const _PersonalBests({required this.stats});

  final _PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int, Color)>[
      ('CLASSIC', stats.classic, ReactColors.electricBlueBright),
      ('BLITZ', stats.blitz, ReactColors.coral),
      ('ENDLESS', stats.endless, ReactColors.lime),
      ('DAILY', stats.daily, ReactColors.purple),
      ('SEQUENCE', stats.sequence, ReactColors.electricBlueBright),
    ];

    return _Panel(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 70) / 2,
              child: _BestTile(
                label: item.$1,
                value: item.$2,
                color: item.$3,
              ),
            ),
        ],
      ),
    );
  }
}

class _BestTile extends StatelessWidget {
  const _BestTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF091523),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = ReactColors.textPrimary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: ReactColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 10,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF223750)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ReactColors.textSecondary,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});

  final PlayerProfileData profile;

  @override
  Widget build(BuildContext context) {
    final color = profile.isAnonymous ? ReactColors.purple : ReactColors.lime;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            profile.isAnonymous
                ? Icons.shield_outlined
                : Icons.verified_user_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.isAnonymous ? 'GUEST PROFILE' : 'SECURED PROFILE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.isAnonymous
                      ? 'Your identity, name, photo and competitive record work without a login. Google and Apple linking can secure this same player later without creating a new profile.'
                      : 'This player identity is linked to a permanent sign-in method and can be restored on another device.',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9.5,
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
}

String _formatDate(DateTime value) {
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
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
}
