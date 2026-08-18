import 'package:flutter/material.dart';

import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../shop/presentation/shop_screen.dart';
import '../../tutorial/presentation/how_to_play_screen.dart';
import 'command_performance_screen.dart';
import 'milestones_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _visualEffectsEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = ReactSettings.soundEnabled;
    _visualEffectsEnabled = ReactSettings.visualEffectsEnabled;
  }

  Future<void> _setSound(bool value) async {
    setState(() => _soundEnabled = value);
    await ReactSettings.setSoundEnabled(value);
  }

  Future<void> _setVisualEffects(bool value) async {
    setState(() => _visualEffectsEnabled = value);
    await ReactSettings.setVisualEffectsEnabled(value);
  }

  Future<void> _openCommandPerformance() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CommandPerformanceScreen()),
    );
  }

  Future<void> _openMilestones() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MilestonesScreen()),
    );
  }

  Future<void> _openHowToPlay() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HowToPlayScreen()),
    );
  }

  Future<void> _openShop() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
    );
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF07111D),
        title: const Text('RESET LOCAL PROGRESS?'),
        content: const Text(
          'This permanently clears local scores, detailed run stats, command performance, Daily history and Daily streak. Your player identity, profile photo and game settings are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ReactColors.coral),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await LocalPlayerStats.resetProgress();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local progress reset.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad = MediaQuery.sizeOf(context).width < 360 ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPad, 14, horizontalPad, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 22),
              const _SectionLabel('PERFORMANCE'),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.insights_rounded,
                title: 'COMMAND PERFORMANCE',
                subtitle: 'Accuracy, misses and reaction time for every gesture.',
                color: ReactColors.lime,
                onTap: _openCommandPerformance,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.workspace_premium_outlined,
                title: 'MILESTONES',
                subtitle: 'Track meaningful records across every mode.',
                color: ReactColors.purple,
                onTap: _openMilestones,
              ),
              const SizedBox(height: 18),
              const _SectionLabel('DISCOVER'),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.menu_book_rounded,
                title: 'HOW TO PLAY',
                subtitle:
                    'Review all 9 commands, Sequence mode and core rules at any time.',
                color: ReactColors.electricBlueBright,
                onTap: _openHowToPlay,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.shopping_bag_outlined,
                title: 'SHOP',
                subtitle: 'Preview cosmetic themes, sound packs and visual styles.',
                color: ReactColors.coral,
                onTap: _openShop,
              ),
              const SizedBox(height: 18),
              const _SectionLabel('GAME SETTINGS'),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.volume_up_rounded,
                title: 'SOUND EFFECTS',
                subtitle: 'Gameplay, countdown and result sound effects.',
                value: _soundEnabled,
                color: ReactColors.electricBlueBright,
                onChanged: _setSound,
              ),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.auto_awesome_rounded,
                title: 'VISUAL EFFECTS',
                subtitle: 'Flame particles, bursts, pulses and pressure effects.',
                value: _visualEffectsEnabled,
                color: ReactColors.purple,
                onChanged: _setVisualEffects,
              ),
              const SizedBox(height: 18),
              const _SectionLabel('LOCAL DATA'),
              const SizedBox(height: 10),
              _ResetProgressTile(onPressed: _resetProgress),
              const SizedBox(height: 18),
              const _InfoCard(),
            ],
          ),
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
        const SizedBox(width: 8),
        const Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'SETTINGS',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 56),
      ],
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .34)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 9,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .30)),
      ),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 25),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 37),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 9,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: color,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, color: color, size: 25),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 9,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: color,
                ),
              ],
            ),
    );
  }
}

class _ResetProgressTile extends StatelessWidget {
  const _ResetProgressTile({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ReactColors.coral.withValues(alpha: .38)),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: ReactColors.coral, size: 25),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESET LOCAL PROGRESS',
                    style: TextStyle(
                      color: ReactColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Clear scores, detailed run stats, command performance and Daily progress from this device. Your player identity is kept.',
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 9,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ReactColors.coral),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF09101C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24364E)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_done_outlined, color: ReactColors.textSecondary, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'PLAYER IDENTITY AND COMPETITIVE PROFILE SYNC ONLINE • GAME SETTINGS REMAIN DEVICE-SPECIFIC',
              style: TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
