import 'package:flutter/material.dart';

import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';
import '../../gameplay/presentation/react_run_screen.dart';

enum ReactRunMode { blitz, endless, daily, passIt }

extension ReactRunModeMapping on ReactRunMode {
  ReactGameMode get gameMode => switch (this) {
        ReactRunMode.blitz => ReactGameMode.blitz,
        ReactRunMode.endless => ReactGameMode.endless,
        ReactRunMode.daily => ReactGameMode.daily,
        ReactRunMode.passIt => ReactGameMode.passIt,
      };
}

class ModeRunScreen extends StatelessWidget {
  const ModeRunScreen({required this.mode, super.key});

  final ReactRunMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == ReactRunMode.passIt) {
      return const ReactRunScreen(mode: ReactGameMode.passIt);
    }

    return ReactRunLaunchScreen(mode: mode.gameMode);
  }
}
