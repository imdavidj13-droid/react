import 'package:flutter/material.dart';

import '../core/theme/react_theme.dart';
import '../features/home/presentation/home_screen.dart';

class ReactApp extends StatelessWidget {
  const ReactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'React',
      debugShowCheckedModeBanner: false,
      theme: ReactTheme.dark,
      home: const HomeScreen(),
    );
  }
}
