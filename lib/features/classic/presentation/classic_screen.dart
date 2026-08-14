import 'package:flutter/material.dart';

import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';

class ClassicScreen extends StatelessWidget {
  const ClassicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReactRunLaunchScreen(mode: ReactGameMode.classic);
  }
}
