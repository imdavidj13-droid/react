import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/settings/react_settings.dart';
import '../core/theme/react_colors.dart';
import '../core/theme/react_theme.dart';
import '../features/daily/presentation/daily_dev_screen.dart';
import '../features/friends/presentation/friends_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/player/presentation/player_profile_screen.dart';
import '../features/season/presentation/home_season_strip.dart';
import '../features/season/presentation/season_cosmetic_layers.dart';
import '../features/season/presentation/season_locker_screen.dart';
import '../features/tutorial/presentation/how_to_play_screen.dart';

class ReactApp extends StatelessWidget {
  const ReactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'React',
      debugShowCheckedModeBanner: false,
      theme: ReactTheme.dark,
      home: const _FirstRunShell(),
    );
  }
}

class _FirstRunShell extends StatefulWidget {
  const _FirstRunShell();

  @override
  State<_FirstRunShell> createState() => _FirstRunShellState();
}

class _FirstRunShellState extends State<_FirstRunShell> {
  late bool _showTutorial;

  @override
  void initState() {
    super.initState();
    _showTutorial = !ReactSettings.howToPlayCompleted;
  }

  @override
  Widget build(BuildContext context) {
    if (_showTutorial) {
      return HowToPlayScreen(
        firstRun: true,
        onFinished: () => setState(() => _showTutorial = false),
      );
    }

    return kDebugMode ? const _DebugHome() : const _HomeShell();
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell();

  void _openLocker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SeasonLockerScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SeasonProfileLayer(
          child: PlayerProfileScreen(),
        ),
      ),
    );
  }

  void _openFriends(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SeasonFriendsLayer(
          child: FriendsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SeasonCosmeticLayers.home(
          child: const Column(
            children: [
              Expanded(child: HomeScreen()),
              SafeArea(top: false, child: HomeSeasonStrip()),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: MediaQuery.paddingOf(context).top + 10,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              tooltip: 'Locker',
              onPressed: () => _openLocker(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF07101E),
                foregroundColor: ReactColors.electricBlueBright,
                side: BorderSide(
                  color: ReactColors.electricBlueBright.withValues(alpha: .75),
                ),
              ),
              icon: const Icon(Icons.inventory_2_outlined, size: 22),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: MediaQuery.paddingOf(context).top + 10,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              tooltip: 'Player profile',
              onPressed: () => _openProfile(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF07101E),
                foregroundColor: ReactColors.textPrimary,
                side: BorderSide(
                  color: ReactColors.electricBlue.withValues(alpha: .75),
                ),
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 22),
            ),
          ),
        ),
        Positioned(
          right: 62,
          top: MediaQuery.paddingOf(context).top + 10,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              tooltip: 'Friends',
              onPressed: () => _openFriends(context),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(42),
                maximumSize: const Size.square(42),
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF07111D),
                foregroundColor: ReactColors.lime,
                side: BorderSide(
                  color: ReactColors.lime.withValues(alpha: .72),
                ),
              ),
              icon: const Icon(Icons.group_outlined, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _DebugHome extends StatelessWidget {
  const _DebugHome();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _HomeShell(),
        Positioned(
          left: 62,
          top: MediaQuery.paddingOf(context).top + 10,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              tooltip: 'Daily developer tester',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DailyDevScreen(),
                  ),
                );
              },
              style: IconButton.styleFrom(
                minimumSize: const Size.square(42),
                maximumSize: const Size.square(42),
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF07111D),
                foregroundColor: ReactColors.coral,
                side: const BorderSide(color: ReactColors.coral),
              ),
              icon: const Icon(Icons.science_rounded, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
