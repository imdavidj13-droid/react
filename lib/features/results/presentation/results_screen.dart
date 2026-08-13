import 'package:flutter/material.dart';

import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../../core/widgets/neon_button.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';
import '../../gameplay/presentation/react_run_screen.dart';
import '../../home/presentation/home_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({required this.result, super.key});

  final ReactRunResult result;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _newBest = false;
  late final Future<void> _recordFuture;

  ReactRunResult get result => widget.result;

  bool get _isDailyDevRun =>
      result.mode == ReactGameMode.daily && ReactSettings.dailyDevRunActive;

  Color get _modeColor => switch (result.mode) {
        ReactGameMode.classic => ReactColors.electricBlueBright,
        ReactGameMode.blitz => ReactColors.coral,
        ReactGameMode.endless => ReactColors.lime,
        ReactGameMode.daily => ReactColors.electricBlueBright,
        ReactGameMode.passIt => ReactColors.purple,
      };

  @override
  void initState() {
    super.initState();
    _recordFuture = _recordResult();
  }

  Future<void> _recordResult() async {
    final newBest = await LocalPlayerStats.recordResult(result);
    if (!mounted || !newBest) return;
    setState(() => _newBest = true);
  }

  Widget _replayScreen() {
    if (result.mode == ReactGameMode.passIt) {
      return const ReactRunScreen(mode: ReactGameMode.passIt);
    }
    if (_isDailyDevRun) {
      return const ReactRunLaunchScreen(
        mode: ReactGameMode.daily,
        consumeDailyAttempt: false,
      );
    }
    return ReactRunLaunchScreen(mode: result.mode);
  }

  Future<void> _playAgain() async {
    await _recordFuture;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => _replayScreen()),
    );
  }

  Future<void> _backHome() async {
    await _recordFuture;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _backToDevTester() async {
    await _recordFuture;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
                child: Column(
                  children: [
                    _ResultsHeader(result: result, color: _modeColor),
                    SizedBox(height: compact ? 24 : 34),
                    _ScoreHero(
                      result: result,
                      color: _modeColor,
                      newBest: _newBest,
                    ),
                    SizedBox(height: compact ? 22 : 30),
                    _StatsStrip(result: result),
                    const SizedBox(height: 16),
                    _OutcomeCard(result: result, color: _modeColor),
                    if (result.mode == ReactGameMode.passIt &&
                        result.playerLives != null) ...[
                      const SizedBox(height: 14),
                      _PassItSummary(result: result),
                    ],
                    SizedBox(height: compact ? 24 : 32),
                    if (_isDailyDevRun)
                      NeonButton(
                        label: 'TEST AGAIN',
                        icon: Icons.science_rounded,
                        onPressed: _playAgain,
                      )
                    else if (result.mode == ReactGameMode.daily)
                      const _DailyLockedButton()
                    else
                      NeonButton(
                        label: 'PLAY AGAIN',
                        icon: Icons.replay_rounded,
                        onPressed: _playAgain,
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        onPressed: _isDailyDevRun ? _backToDevTester : _backHome,
                        icon: Icon(
                          _isDailyDevRun
                              ? Icons.science_outlined
                              : Icons.home_outlined,
                          size: 17,
                        ),
                        label: Text(
                          _isDailyDevRun
                              ? 'BACK TO DEV TESTER'
                              : 'BACK TO HOME',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: ReactColors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DailyLockedButton extends StatelessWidget {
  const _DailyLockedButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1422),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: ReactColors.lime.withValues(alpha: .42)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: ReactColors.lime, size: 21),
          SizedBox(width: 10),
          Text(
            'DAILY ATTEMPT COMPLETE',
            style: TextStyle(
              color: ReactColors.lime,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          result.mode.label,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const Spacer(),
        Text(
          result.outcomeLabel,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({
    required this.result,
    required this.color,
    required this.newBest,
  });

  final ReactRunResult result;
  final Color color;
  final bool newBest;

  @override
  Widget build(BuildContext context) {
    final isPassIt = result.mode == ReactGameMode.passIt;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A101D),
            border: Border.all(color: color.withValues(alpha: .62)),
          ),
          child: Icon(
            isPassIt ? Icons.groups_2_rounded : Icons.bolt_rounded,
            color: color,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          isPassIt ? 'COMMANDS CLEARED' : 'FINAL SCORE',
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${result.score}',
          style: const TextStyle(
            color: ReactColors.lime,
            fontSize: 82,
            height: .95,
            fontWeight: FontWeight.w900,
            letterSpacing: -3.2,
          ),
        ),
        if (newBest) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: ReactColors.lime.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ReactColors.lime.withValues(alpha: .55)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, color: ReactColors.lime, size: 17),
                SizedBox(width: 7),
                Text(
                  'NEW BEST',
                  style: TextStyle(
                    color: ReactColors.lime,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.result});

  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF17304E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResultStat(
              label: 'SUCCESS',
              value: '${result.successfulCommands}',
              color: ReactColors.electricBlueBright,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: 'MISSES',
              value: '${result.misses}',
              color: ReactColors.coral,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: 'AVG TIME',
              value: result.averageTimeSeconds == 0
                  ? '--'
                  : '${result.averageTimeSeconds.toStringAsFixed(2)}s',
              color: ReactColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final title = switch (result.outcome) {
      ReactRunOutcome.missedCommand => 'MISSED COMMAND',
      ReactRunOutcome.timeUp => 'CLOCK EXPIRED',
      ReactRunOutcome.completed => 'CHALLENGE COMPLETE',
      ReactRunOutcome.winner => 'MATCH WINNER',
      ReactRunOutcome.quit => 'RUN ENDED',
    };

    final value = switch (result.outcome) {
      ReactRunOutcome.missedCommand => result.failedCommand?.title ?? 'MISS',
      ReactRunOutcome.timeUp => '60 SECONDS COMPLETE',
      ReactRunOutcome.completed => '${result.successfulCommands} COMMANDS CLEARED',
      ReactRunOutcome.winner => 'PLAYER ${result.winnerPlayer ?? '-'}',
      ReactRunOutcome.quit => result.mode.label,
    };

    final icon = switch (result.outcome) {
      ReactRunOutcome.missedCommand => result.failedCommand?.icon ?? Icons.close_rounded,
      ReactRunOutcome.timeUp => Icons.timer_rounded,
      ReactRunOutcome.completed => Icons.emoji_events_rounded,
      ReactRunOutcome.winner => Icons.emoji_events_rounded,
      ReactRunOutcome.quit => Icons.stop_circle_outlined,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .62)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .08),
              border: Border.all(color: color.withValues(alpha: .28)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassItSummary extends StatelessWidget {
  const _PassItSummary({required this.result});

  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    final lives = result.playerLives ?? const <int>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FINAL PLAYER STATUS',
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < lives.length; i++) ...[
            _PassItPlayerRow(
              player: i + 1,
              lives: lives[i],
              winner: result.winnerPlayer == i + 1,
            ),
            if (i != lives.length - 1) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _PassItPlayerRow extends StatelessWidget {
  const _PassItPlayerRow({
    required this.player,
    required this.lives,
    required this.winner,
  });

  final int player;
  final int lives;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final color = winner ? ReactColors.lime : ReactColors.textSecondary;
    final hearts = lives == 0 ? 'OUT' : List.filled(lives, '♥').join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090F1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: winner
              ? ReactColors.lime.withValues(alpha: .48)
              : const Color(0xFF24364E),
        ),
      ),
      child: Row(
        children: [
          Icon(
            winner ? Icons.emoji_events_rounded : Icons.person_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Text(
            'PLAYER $player',
            style: TextStyle(
              color: winner ? ReactColors.textPrimary : ReactColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            winner ? 'WINNER  •  $hearts' : hearts,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0xFF1A2B45));
  }
}
