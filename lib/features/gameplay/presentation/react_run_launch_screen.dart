import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/audio/react_audio.dart';
import '../../../core/cosmetics/react_cosmetics.dart';
import '../../../core/theme/react_colors.dart';
import '../../daily/presentation/daily_run_screen.dart';
import '../../dot_sequence/presentation/dot_sequence_screen.dart';
import '../data/local_player_stats.dart';
import '../domain/react_run_result.dart';
import 'react_run_screen.dart';

class ReactRunLaunchScreen extends StatefulWidget {
  const ReactRunLaunchScreen({
    required this.mode,
    this.consumeDailyAttempt = true,
    super.key,
  });

  final ReactGameMode mode;
  final bool consumeDailyAttempt;

  @override
  State<ReactRunLaunchScreen> createState() => _ReactRunLaunchScreenState();
}

class _ReactRunLaunchScreenState extends State<ReactRunLaunchScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _count = 3;
  bool _go = false;
  bool _suspended = false;
  bool _launching = false;

  Color get _baseAccent => switch (widget.mode) {
        ReactGameMode.classic => ReactColors.electricBlueBright,
        ReactGameMode.blitz => ReactColors.coral,
        ReactGameMode.endless => ReactColors.lime,
        ReactGameMode.daily => ReactColors.electricBlueBright,
        ReactGameMode.passIt => ReactColors.purple,
        ReactGameMode.sequence => ReactColors.electricBlueBright,
      };

  Color get _accent => ReactCosmetics.effectAccentFor(_baseAccent);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ReactAudio.play(ReactSoundCue.countdownTick));
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _suspended || _launching) return;

      if (_count > 1) {
        setState(() => _count -= 1);
        unawaited(ReactAudio.play(ReactSoundCue.countdownTick));
        return;
      }

      if (!_go) {
        setState(() => _go = true);
        unawaited(ReactAudio.play(ReactSoundCue.countdownGo));
        return;
      }

      _timer?.cancel();
      _launching = true;
      unawaited(_beginRun());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _suspended = state != AppLifecycleState.resumed;
  }

  Future<void> _beginRun() async {
    if (widget.mode == ReactGameMode.daily && widget.consumeDailyAttempt) {
      await LocalPlayerStats.markDailyAttemptStarted();
    }
    if (!mounted) return;

    // Daily persistence above is asynchronous. If the app backgrounds during
    // that await, do not replace the route while inactive. The periodic timer
    // will retry once the lifecycle is resumed.
    if (_suspended) {
      _launching = false;
      if (_timer?.isActive != true) {
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (_suspended || _launching) return;
          timer.cancel();
          _launching = true;
          unawaited(_beginRun());
        });
      }
      return;
    }

    final screen = switch (widget.mode) {
      ReactGameMode.daily => const DailyRunScreen(),
      ReactGameMode.sequence => const DotSequenceScreen(),
      _ => ReactRunScreen(mode: widget.mode),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    return Scaffold(
      backgroundColor: palette.background,
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
                    color: _go ? palette.secondary : ReactColors.textPrimary,
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
                    backgroundColor: palette.primary.withValues(alpha: .14),
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _suspended ? 'PAUSED' : 'GET READY',
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 10,
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
