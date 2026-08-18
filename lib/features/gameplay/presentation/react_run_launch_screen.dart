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
    final progress = _go ? 1.0 : (4 - _count) / 3;
    final label = _go ? 'GO' : '$_count';
    final style = ReactCosmetics.currentCountdownStyle;

    return Scaffold(
      key: ValueKey<String>('countdown-style-${style.name}'),
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: _CountdownPresentation(
            style: style,
            modeLabel: widget.mode.label,
            label: label,
            go: _go,
            suspended: _suspended,
            progress: progress,
            accent: _accent,
            palette: palette,
          ),
        ),
      ),
    );
  }
}

class _CountdownPresentation extends StatelessWidget {
  const _CountdownPresentation({
    required this.style,
    required this.modeLabel,
    required this.label,
    required this.go,
    required this.suspended,
    required this.progress,
    required this.accent,
    required this.palette,
  });

  final ReactCountdownStyle style;
  final String modeLabel;
  final String label;
  final bool go;
  final bool suspended;
  final double progress;
  final Color accent;
  final ReactCosmeticPalette palette;

  @override
  Widget build(BuildContext context) => switch (style) {
        ReactCountdownStyle.core => _CoreCountdown(
            modeLabel: modeLabel,
            label: label,
            go: go,
            suspended: suspended,
            progress: progress,
            accent: accent,
            palette: palette,
          ),
        ReactCountdownStyle.rings => _RingsCountdown(
            modeLabel: modeLabel,
            label: label,
            go: go,
            suspended: suspended,
            progress: progress,
            accent: accent,
            palette: palette,
          ),
        ReactCountdownStyle.cards => _CardsCountdown(
            modeLabel: modeLabel,
            label: label,
            go: go,
            suspended: suspended,
            progress: progress,
            accent: accent,
            palette: palette,
          ),
        ReactCountdownStyle.terminal => _TerminalCountdown(
            modeLabel: modeLabel,
            label: label,
            go: go,
            suspended: suspended,
            progress: progress,
            accent: accent,
            palette: palette,
          ),
        ReactCountdownStyle.pulse => _PulseCountdown(
            modeLabel: modeLabel,
            label: label,
            go: go,
            suspended: suspended,
            progress: progress,
            accent: accent,
            palette: palette,
          ),
      };
}

class _CoreCountdown extends StatelessWidget {
  const _CoreCountdown({
    required this.modeLabel,
    required this.label,
    required this.go,
    required this.suspended,
    required this.progress,
    required this.accent,
    required this.palette,
  });

  final String modeLabel;
  final String label;
  final bool go;
  final bool suspended;
  final double progress;
  final Color accent;
  final ReactCosmeticPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeLabel(modeLabel: modeLabel, accent: accent),
        const SizedBox(height: 26),
        _AnimatedCount(
          label: label,
          go: go,
          color: go ? palette.secondary : ReactColors.textPrimary,
          fontSize: go ? 86 : 118,
          letterSpacing: go ? 5 : -3,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 184,
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: palette.primary.withValues(alpha: .14),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ReadyLabel(suspended: suspended),
      ],
    );
  }
}

class _RingsCountdown extends StatelessWidget {
  const _RingsCountdown({
    required this.modeLabel,
    required this.label,
    required this.go,
    required this.suspended,
    required this.progress,
    required this.accent,
    required this.palette,
  });

  final String modeLabel;
  final String label;
  final bool go;
  final bool suspended;
  final double progress;
  final Color accent;
  final ReactCosmeticPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeLabel(modeLabel: modeLabel, accent: accent),
        const SizedBox(height: 24),
        SizedBox.square(
          dimension: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: 210,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  backgroundColor: accent.withValues(alpha: .10),
                  color: accent,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: 166,
                height: 166,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .38), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .16),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _AnimatedCount(
                    label: label,
                    go: go,
                    color: go ? palette.secondary : ReactColors.textPrimary,
                    fontSize: go ? 60 : 92,
                    letterSpacing: go ? 4 : -2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _ReadyLabel(suspended: suspended),
      ],
    );
  }
}

class _CardsCountdown extends StatelessWidget {
  const _CardsCountdown({
    required this.modeLabel,
    required this.label,
    required this.go,
    required this.suspended,
    required this.progress,
    required this.accent,
    required this.palette,
  });

  final String modeLabel;
  final String label;
  final bool go;
  final bool suspended;
  final double progress;
  final Color accent;
  final ReactCosmeticPalette palette;

  @override
  Widget build(BuildContext context) {
    final activeSegments = (progress * 3).ceil().clamp(0, 3);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeLabel(modeLabel: modeLabel, accent: accent),
        const SizedBox(height: 24),
        Container(
          width: 230,
          height: 190,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withValues(alpha: .52), width: 2),
          ),
          child: Center(
            child: _AnimatedCount(
              label: label,
              go: go,
              color: go ? palette.secondary : ReactColors.textPrimary,
              fontSize: go ? 64 : 104,
              letterSpacing: go ? 4 : -3,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 54,
                height: 8,
                decoration: BoxDecoration(
                  color: i < activeSegments
                      ? accent
                      : accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              if (i < 2) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _ReadyLabel(suspended: suspended),
      ],
    );
  }
}

class _TerminalCountdown extends StatelessWidget {
  const _TerminalCountdown({
    required this.modeLabel,
    required this.label,
    required this.go,
    required this.suspended,
    required this.progress,
    required this.accent,
    required this.palette,
  });

  final String modeLabel;
  final String label;
  final bool go;
  final bool suspended;
  final double progress;
  final Color accent;
  final ReactCosmeticPalette palette;

  @override
  Widget build(BuildContext context) {
    final terminalValue = go ? 'EXECUTE' : label.padLeft(2, '0');
    return Container(
      width: 300,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF020806),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: .65)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REACT://$modeLabel',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 26),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              '> $terminalValue',
              key: ValueKey<String>(terminalValue),
              style: TextStyle(
                color: go ? palette.secondary : ReactColors.textPrimary,
                fontSize: go ? 42 : 72,
                fontWeight: FontWeight.w800,
                letterSpacing: go ? 1 : -1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: accent.withValues(alpha: .10),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
          const SizedBox(height: 14),
          Text(
            suspended ? '[ PAUSED ]' : '[ SYSTEM ARMED ]',
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseCountdown extends StatelessWidget {
  const _PulseCountdown({
    required this.modeLabel,
    required this.label,
    required this.go,
    required this.suspended,
    required this.progress,
    required this.accent,
    required this.palette,
  });

  final String modeLabel;
  final String label;
  final bool go;
  final bool suspended;
  final double progress;
  final Color accent;
  final ReactCosmeticPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeLabel(modeLabel: modeLabel, accent: accent),
        const SizedBox(height: 18),
        SizedBox.square(
          dimension: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 224,
                height: 224,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .12), width: 2),
                ),
              ),
              Container(
                width: 184,
                height: 184,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .28), width: 3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: go ? 156 : 146,
                height: go ? 156 : 146,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: go ? .18 : .08),
                  border: Border.all(color: accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: go ? .34 : .18),
                      blurRadius: go ? 38 : 24,
                      spreadRadius: go ? 8 : 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _AnimatedCount(
                    label: label,
                    go: go,
                    color: go ? palette.secondary : ReactColors.textPrimary,
                    fontSize: go ? 52 : 84,
                    letterSpacing: go ? 3 : -2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 190,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: accent.withValues(alpha: .10),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 18),
        _ReadyLabel(suspended: suspended),
      ],
    );
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({required this.modeLabel, required this.accent});
  final String modeLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) => Text(
        modeLabel,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.4,
        ),
      );
}

class _ReadyLabel extends StatelessWidget {
  const _ReadyLabel({required this.suspended});
  final bool suspended;

  @override
  Widget build(BuildContext context) => Text(
        suspended ? 'PAUSED' : 'GET READY',
        style: const TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      );
}

class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({
    required this.label,
    required this.go,
    required this.color,
    required this.fontSize,
    required this.letterSpacing,
  });

  final String label;
  final bool go;
  final Color color;
  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          label,
          key: ValueKey<String>(label),
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
          ),
        ),
      );
}
