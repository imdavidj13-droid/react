import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/react_colors.dart';
import '../core/theme/react_theme.dart';
import '../features/daily/presentation/daily_dev_screen.dart';
import '../features/home/presentation/home_screen.dart';

class ReactApp extends StatelessWidget {
  const ReactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'React',
      debugShowCheckedModeBanner: false,
      theme: ReactTheme.dark,
      home: kDebugMode ? const _DebugHome() : const HomeScreen(),
    );
  }
}

class _DebugHome extends StatelessWidget {
  const _DebugHome();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        Positioned(
          right: 12,
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
