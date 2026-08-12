import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/theme/react_colors.dart';
import '../data/local_player_stats.dart';
import '../domain/react_run_result.dart';
import 'react_run_screen.dart';

class ReactRunLaunchScreen extends StatefulWidget {
  const ReactRunLaunchScreen({required this.mode, super.key});

  final ReactGameMode mode;

  @override
  State<ReactRunLaunchScreen> createState() => _ReactRunLaunchScreenState();
}

class _ReactRunLaunchScreenState extends State<ReactRunLaunchScreen> {
  Timer? _timer;
  int _count = 3;
  bool _go = false;

  Color get _accent => switch (widget.mode) {
        ReactGameMode.classic => ReactColors.electricBlueBright,
        ReactGameMode.blitz => ReactColors.coral,
        ReactGameMode.endless => ReactColors.lime,
        ReactGameMode.daily => ReactColors.electricBlueBright,
        ReactGameMode.passIt => ReactColors.purple,
      };

  @override
  void initState() {
    super.initState();
    unawaited(ReactAudio.play(ReactSoundCue.command));
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted) return;

      if (_count > 1) {
        setState(() => _count -= 1);
        unawaited(ReactAudio.play(ReactSoundCue.command));
        return;
      }

      if (!_go) {
        setState(() => _go = true);
        unawaited(ReactAudio.play(ReactSoundCue.success));
        return;
      }

      _timer?.cancel();
      unawaited(_beginRun());
    });
  }

  Future<void> _beginRun() async {
    if (widget.mode == ReactGameMode.daily) {
      await LocalPlayerStats.markDailyAttemptStarted();
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReactRunScreen(mode: widget.mode),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.mode.label,
                style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 26),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  _go ? 'GO' : '$_count',
                  key: ValueKey<String>(_go ? 'go' : '$_count'),
                  style: TextStyle(
                    color: _go ? ReactColors.lime : ReactColors.textPrimary,
                    fontSize: _go ? 86 : 118,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: _go ? 5 : -3,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 184,
                height: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: _go ? 1 : (4 - _count) / 3,
                    backgroundColor: const Color(0xFF102039),
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'GET READY',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
