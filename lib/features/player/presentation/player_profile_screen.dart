import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/backend/react_supabase.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_result.dart';
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
                    const _SectionTitle('PLAYER STATS'),
                    const SizedBox(height: 9),
                    _StatsGrid(stats: data.stats),
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
    required this.streak,
    required this.classic,
    required this.blitz,
    required this.endless,
    required this.daily,
    required this.sequence,
  });

  final int runs;
  final int commands;
  final int streak;
  final int classic;
  final int blitz;
  final int endless;
  final int daily;
  final int sequence;

  static Future<_PlayerStats> load() async {
    final values = await Future.wait<int>([
      LocalPlayerStats.runsPlayed(),
      LocalPlayerStats.totalSuccessfulCommands(),
      LocalPlayerStats.dailyStreak(),
      LocalPlayerStats.bestFor(ReactGameMode.classic),
      LocalPlayerStats.bestFor(ReactGameMode.blitz),
      LocalPlayerStats.bestFor(ReactGameMode.endless),
      LocalPlayerStats.bestFor(ReactGameMode.daily),
      LocalPlayerStats.bestFor(ReactGameMode.sequence),
    ]);
    return _PlayerStats(
      runs: values[0],
      commands: values[1],
      streak: values[2],
      classic: values[3],
      blitz: values[4],
      endless: values[5],
      daily: values[6],
      sequence: values[7],
    );
  }
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: (profile.isAnonymous ? ReactColors.purple : ReactColors.lime)
                  .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: (profile.isAnonymous ? ReactColors.purple : ReactColors.lime)
                    .withValues(alpha: .55),
              ),
            ),
            child: Text(
              profile.isAnonymous ? 'GUEST PLAYER' : 'SECURED PLAYER',
              style: TextStyle(
                color: profile.isAnonymous ? ReactColors.purple : ReactColors.lime,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
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
              errorBuilder: (_, __, ___) => const Icon(
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF223750)),
      ),
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'RUNS',
            value: '${stats.runs}',
            color: ReactColors.electricBlueBright,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'COMMANDS',
            value: '${stats.commands}',
            color: ReactColors.lime,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'DAILY STREAK',
            value: '${stats.streak}',
            color: ReactColors.coral,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 4),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF223750)),
      ),
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});

  final PlayerProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (profile.isAnonymous ? ReactColors.purple : ReactColors.lime)
              .withValues(alpha: .35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            profile.isAnonymous ? Icons.shield_outlined : Icons.verified_user_outlined,
            color: profile.isAnonymous ? ReactColors.purple : ReactColors.lime,
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
                      ? 'Your player profile works now without a login. Google and Apple linking can be added later without changing the player identity.'
                      : 'This player identity is linked to a permanent sign-in method.',
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
