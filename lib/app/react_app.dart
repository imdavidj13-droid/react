import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/settings/react_settings.dart';
import '../core/theme/react_colors.dart';
import '../core/theme/react_theme.dart';
import '../features/daily/presentation/daily_dev_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/shop/presentation/shop_screen.dart';
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

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        Positioned(
          left: 12,
          top: MediaQuery.paddingOf(context).top + 10,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              tooltip: 'Shop',
              onPressed: () => _openShop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF07101E),
                foregroundColor: ReactColors.electricBlueBright,
                side: BorderSide(
                  color: ReactColors.electricBlueBright.withValues(alpha: .75),
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, size: 22),
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
          left: 12,
          top: MediaQuery.paddingOf(context).top + 66,
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
                backgroundColor: const Color(0xFF07111D),
                foregroundColor: ReactColors.coral,
                side: const BorderSide(color: ReactColors.coral),
              ),
              icon: const Icon(Icons.science_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
