import 'package:flutter/material.dart';

import '../../../core/settings/react_settings.dart';
import '../../../core/theme/react_colors.dart';
import '../../../core/widgets/neon_button.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../../gameplay/presentation/react_run_launch_screen.dart';
import '../../gameplay/presentation/react_run_screen.dart';
import '../../leaderboard/data/local_leaderboard_submission_store.dart';
import '../../season/data/season_cosmetic_state.dart';
import '../../season/presentation/season_cosmetic_layers.dart';
import '../domain/run_comparison.dart';
import '../domain/run_medal.dart';
import 'result_share_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({required this.result, super.key});

  final ReactRunResult result;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _newBest = false;
  bool _recordComplete = false;
  int? _chargeEarned;
  RunComparison? _comparison;
  late final Future<void> _recordFuture;

  ReactRunResult get result => widget.result;
  bool get _isDailyDevRun => result.isDailyDevRun;

  Color get _modeColor => switch (result.mode) {
    ReactGameMode.classic => ReactColors.electricBlueBright,
    ReactGameMode.blitz => ReactColors.coral,
    ReactGameMode.endless => ReactColors.lime,
    ReactGameMode.daily => ReactColors.electricBlueBright,
    ReactGameMode.passIt => ReactColors.purple,
    ReactGameMode.sequence => ReactColors.electricBlueBright,
  };

  @override
  void initState() {
    super.initState();
    _recordFuture = _recordResult();
  }

  Future<void> _recordResult() async {
    final recent = await LocalPlayerStats.recentRuns();
    final previous = recent.where((entry) => entry.mode == result.mode).firstOrNull;
    final comparison = RunComparison.againstPrevious(result, previous);
    final newBest = await LocalPlayerStats.recordResult(result);
    int? chargeEarned;
    if (!_isDailyDevRun) {
      await LocalLeaderboardSubmissionStore.enqueueResult(
        result,
        isPersonalBest: newBest,
        onSeasonChargeEarned: (value) => chargeEarned = value,
      );
    }
    if (!mounted) return;
    setState(() {
      _comparison = comparison;
      _newBest = newBest;
      _chargeEarned = chargeEarned;
      _recordComplete = true;
    });
  }

  Widget _replayScreen() {
    if (result.mode == ReactGameMode.passIt) {
      return const ReactRunScreen(mode: ReactGameMode.passIt);
    }
    if (_isDailyDevRun) {
      ReactSettings.dailyDevRunActive = true;
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

  Future<void> _shareResult() async {
    await _recordFuture;
    if (!mounted || _isDailyDevRun) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultShareScreen(result: result, newBest: _newBest),
      ),
    );
  }

  Future<void> _backHome() async {
    await _recordFuture;
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _backToDevTester() async {
    await _recordFuture;
    if (!mounted) return;
    ReactSettings.dailyDevRunActive = false;
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
            final contentWidth = constraints.maxWidth - 36;
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ResultsHeader(result: result, color: _modeColor),
                        SizedBox(height: compact ? 12 : 17),
                        _ScoreHero(
                          result: result,
                          color: _modeColor,
                          newBest: _newBest,
                          compact: compact,
                        ),
                        if (!_isDailyDevRun) ...[
                          const SizedBox(height: 9),
                          _ChargeAwardCard(
                            recordComplete: _recordComplete,
                            chargeEarned: _chargeEarned,
                          ),
                        ],
                        SizedBox(height: compact ? 11 : 14),
                        _StatsStrip(result: result, compact: compact),
                        if (result.maxStreak > 0 || _runMedals(result).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _RunHighlights(result: result, color: _modeColor),
                        ],
                        if (_comparison != null) ...[
                          const SizedBox(height: 8),
                          _ComparisonCard(
                            comparison: _comparison!,
                            color: _modeColor,
                          ),
                        ],
                        const SizedBox(height: 9),
                        _OutcomeCard(result: result, color: _modeColor),
                        if (result.mode == ReactGameMode.daily &&
                            result.dailyModifierLabel != null) ...[
                          const SizedBox(height: 8),
                          _DailyResultSummary(result: result),
                        ],
                        if (result.mode == ReactGameMode.passIt &&
                            result.playerLives != null) ...[
                          const SizedBox(height: 8),
                          _PassItSummary(result: result),
                        ],
                        SizedBox(height: compact ? 10 : 13),
                        if (!_isDailyDevRun) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: _shareResult,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _modeColor,
                                side: BorderSide(
                                  color: _modeColor.withValues(alpha: .72),
                                ),
                                backgroundColor: _modeColor.withValues(alpha: .055),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              icon: const Icon(Icons.ios_share_rounded, size: 18),
                              label: const Text('SHARE RESULT'),
                            ),
                          ),
                          const SizedBox(height: 7),
                        ],
                        if (_isDailyDevRun)
                          NeonButton(
                            label: 'TEST AGAIN',
                            icon: Icons.science_rounded,
                            onPressed: _playAgain,
                          )
                        else
                          NeonButton(
                            label: result.mode == ReactGameMode.daily
                                ? 'TRY AGAIN'
                                : 'PLAY AGAIN',
                            icon: Icons.replay_rounded,
                            onPressed: _playAgain,
                          ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: TextButton.icon(
                            onPressed: _isDailyDevRun
                                ? _backToDevTester
                                : _backHome,
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.result, required this.color});
  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
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

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({
    required this.result,
    required this.color,
    required this.newBest,
    required this.compact,
  });

  final ReactRunResult result;
  final Color color;
  final bool newBest;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = switch (result.mode) {
      ReactGameMode.passIt => Icons.groups_2_rounded,
      ReactGameMode.sequence => Icons.blur_circular_rounded,
      _ => Icons.bolt_rounded,
    };
    final scoreEffect = SeasonCosmeticState.equippedReward('score_effect');
    final scoreAccent = scoreEffect == null
        ? ReactColors.lime
        : SeasonCosmeticLayers.accentForReward(scoreEffect);
    final scoreKey = scoreEffect?.rewardKey ?? '';
    final scoreRadius = scoreKey.contains('arc')
        ? 8.0
        : scoreKey.contains('streak')
            ? 999.0
            : scoreKey.contains('overload')
                ? 4.0
                : 20.0;
    final scoreBorderWidth = scoreKey.contains('overload')
        ? 2.2
        : scoreKey.contains('arc')
            ? 1.7
            : 1.0;
    final scoreGlow = scoreKey.contains('overload')
        ? 34.0
        : scoreKey.contains('streak')
            ? 26.0
            : 22.0;

    return Column(
      children: [
        Container(
          width: compact ? 54 : 60,
          height: compact ? 54 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A101D),
            border: Border.all(color: color.withValues(alpha: .62)),
          ),
          child: Icon(icon, color: color, size: compact ? 26 : 29),
        ),
        SizedBox(height: compact ? 7 : 9),
        Text(
          switch (result.mode) {
            ReactGameMode.classic => 'FINAL SCORE',
            ReactGameMode.blitz => '60 SECOND SCORE',
            ReactGameMode.endless => 'COMMANDS SURVIVED',
            ReactGameMode.daily => 'DAILY SCORE',
            ReactGameMode.passIt => 'MATCH COMMANDS',
            ReactGameMode.sequence => 'SEQUENCES CLEARED',
          },
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: scoreEffect == null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
          decoration: scoreEffect == null
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(scoreRadius),
                  gradient: LinearGradient(
                    begin: scoreKey.contains('arc')
                        ? Alignment.centerLeft
                        : Alignment.topLeft,
                    end: scoreKey.contains('arc')
                        ? Alignment.centerRight
                        : Alignment.bottomRight,
                    colors: [
                      scoreAccent.withValues(
                        alpha: scoreKey.contains('overload') ? .20 : .12,
                      ),
                      scoreAccent.withValues(
                        alpha: scoreKey.contains('streak') ? .06 : .025,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: scoreAccent.withValues(
                      alpha: scoreKey.contains('overload') ? .78 : .42,
                    ),
                    width: scoreBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scoreAccent.withValues(
                        alpha: scoreKey.contains('overload') ? .30 : .18,
                      ),
                      blurRadius: scoreGlow,
                      spreadRadius: scoreKey.contains('overload') ? 3 : 1,
                    ),
                  ],
                ),
          child: Text(
            '${result.score}',
            style: TextStyle(
              color: scoreAccent,
              fontSize: compact ? 60 : 66,
              height: .92,
              fontWeight: FontWeight.w900,
              letterSpacing: -3,
              shadows: scoreEffect == null
                  ? null
                  : [
                      Shadow(
                        color: scoreAccent.withValues(alpha: .72),
                        blurRadius: 14,
                      ),
                    ],
            ),
          ),
        ),
        if (scoreEffect != null) ...[
          const SizedBox(height: 5),
          _EffectLabel(
            icon: Icons.auto_graph_rounded,
            label: scoreEffect.name,
            color: scoreAccent,
          ),
        ],
        if (newBest) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: ReactColors.lime.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ReactColors.lime.withValues(alpha: .55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: ReactColors.lime,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  result.mode == ReactGameMode.daily
                      ? 'NEW RULE BEST'
                      : 'NEW BEST',
                  style: const TextStyle(
                    color: ReactColors.lime,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
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

class _ChargeAwardCard extends StatelessWidget {
  const _ChargeAwardCard({
    required this.recordComplete,
    required this.chargeEarned,
  });

  final bool recordComplete;
  final int? chargeEarned;

  @override
  Widget build(BuildContext context) {
    final earned = chargeEarned;
    final synced = recordComplete && earned != null;
    final color = synced ? ReactColors.electricBlueBright : ReactColors.textSecondary;
    final label = !recordComplete
        ? 'CALCULATING CHARGE…'
        : earned == null
            ? 'CHARGE QUEUED • WILL SYNC WHEN ONLINE'
            : '+$earned CHARGE EARNED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, color: color, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.result, required this.compact});
  final ReactRunResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sequence = result.mode == ReactGameMode.sequence;
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF17304E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResultStat(
              label: sequence ? 'SEQUENCES' : 'CLEARS',
              value: '${result.successfulCommands}',
              color: ReactColors.electricBlueBright,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: sequence ? 'MISTAKES' : 'MISSES',
              value: '${result.misses}',
              color: ReactColors.coral,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: sequence ? 'AVG CLEAR' : 'AVG TIME',
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

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison, required this.color});
  final RunComparison comparison;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final positive = comparison.scoreDelta > 0;
    final neutral = comparison.scoreDelta == 0;
    final scoreColor = positive
        ? ReactColors.lime
        : neutral
        ? ReactColors.textPrimary
        : ReactColors.coral;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Icon(Icons.compare_arrows_rounded, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comparison.scoreLabel,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
                if (comparison.reactionLabel != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    comparison.reactionLabel!,
                    style: TextStyle(
                      color: comparison.fasterReaction
                          ? ReactColors.electricBlueBright
                          : ReactColors.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ],
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
    final isSequence = result.mode == ReactGameMode.sequence;
    final title = isSequence
        ? 'OUT OF LIVES'
        : switch (result.outcome) {
            ReactRunOutcome.missedCommand => 'MISSED COMMAND',
            ReactRunOutcome.timeUp => 'CLOCK EXPIRED',
            ReactRunOutcome.completed => 'CHALLENGE COMPLETE',
            ReactRunOutcome.winner => 'MATCH WINNER',
            ReactRunOutcome.quit => 'RUN ENDED',
          };
    final value = isSequence
        ? '${result.successfulCommands} SEQUENCES CLEARED'
        : switch (result.outcome) {
            ReactRunOutcome.missedCommand => result.failedCommand?.title ?? 'MISS',
            ReactRunOutcome.timeUp => '60 SECONDS COMPLETE',
            ReactRunOutcome.completed => '${result.successfulCommands} COMMANDS CLEARED',
            ReactRunOutcome.winner => 'PLAYER ${result.winnerPlayer ?? '-'}',
            ReactRunOutcome.quit => result.mode.label,
          };
    final icon = isSequence
        ? Icons.blur_circular_rounded
        : switch (result.outcome) {
            ReactRunOutcome.missedCommand =>
              result.failedCommand?.icon ?? Icons.close_rounded,
            ReactRunOutcome.timeUp => Icons.timer_rounded,
            ReactRunOutcome.completed || ReactRunOutcome.winner =>
              Icons.emoji_events_rounded,
            ReactRunOutcome.quit => Icons.stop_circle_outlined,
          };

    final success = result.outcome == ReactRunOutcome.completed ||
        result.outcome == ReactRunOutcome.winner ||
        result.outcome == ReactRunOutcome.timeUp;
    final failure = result.outcome == ReactRunOutcome.missedCommand;
    final effect = success
        ? SeasonCosmeticState.equippedReward('success_effect')
        : failure
            ? SeasonCosmeticState.equippedReward('failure_effect')
            : null;
    final accent = effect == null
        ? color
        : SeasonCosmeticLayers.accentForReward(effect);
    final effectKey = effect?.rewardKey ?? '';
    final effectRadius = effectKey.contains('shatter')
        ? 6.0
        : effectKey.contains('blackout')
            ? 2.0
            : effectKey.contains('red_arc')
                ? 12.0
                : effectKey.contains('flash')
                    ? 28.0
                    : effectKey.contains('overdrive')
                        ? 8.0
                        : 18.0;
    final effectBorderWidth = effectKey.contains('blackout') ||
            effectKey.contains('overdrive')
        ? 2.0
        : effectKey.contains('shatter')
            ? 1.7
            : 1.5;
    final effectGlow = effectKey.contains('flash')
        ? 30.0
        : effectKey.contains('blackout')
            ? 8.0
            : effectKey.contains('overdrive')
                ? 26.0
                : 20.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: effect == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: .13),
                  const Color(0xFF0A0D18),
                  accent.withValues(alpha: .025),
                ],
              ),
        color: effect == null ? const Color(0xFF0A0D18) : null,
        borderRadius: BorderRadius.circular(effect == null ? 18 : effectRadius),
        border: Border.all(
          color: accent.withValues(
            alpha: effect == null
                ? .62
                : effectKey.contains('blackout')
                    ? .38
                    : .78,
          ),
          width: effect == null ? 1 : effectBorderWidth,
        ),
        boxShadow: effect == null
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(
                    alpha: effectKey.contains('blackout') ? .08 : .18,
                  ),
                  blurRadius: effectGlow,
                  spreadRadius: effectKey.contains('overdrive') ? 2 : 1,
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: effectKey.contains('blackout') ? .03 : .08,
              ),
              borderRadius: BorderRadius.circular(
                effect == null
                    ? 99
                    : effectKey.contains('shatter')
                        ? 5
                        : effectKey.contains('overdrive')
                            ? 9
                            : 99,
              ),
              border: Border.all(
                color: accent.withValues(
                  alpha: effectKey.contains('blackout') ? .18 : .32,
                ),
              ),
              boxShadow: effect == null
                  ? null
                  : [
                      BoxShadow(
                        color: accent.withValues(alpha: .20),
                        blurRadius: 12,
                      ),
                    ],
            ),
            child: Icon(icon, color: accent, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (effect != null) ...[
                  const SizedBox(height: 5),
                  _EffectLabel(
                    icon: success
                        ? Icons.check_circle_outline_rounded
                        : Icons.flash_off_rounded,
                    label: effect.name,
                    color: accent,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectLabel extends StatelessWidget {
  const _EffectLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: .24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 10),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PassItSummary extends StatelessWidget {
  const _PassItSummary({required this.result});
  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    final lives = result.playerLives ?? const <int>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 7),
          for (var i = 0; i < lives.length; i++) ...[
            _PassItPlayerRow(
              player: i + 1,
              lives: lives[i],
              winner: result.winnerPlayer == i + 1,
              clears: result.playerClears != null && i < result.playerClears!.length
                  ? result.playerClears![i]
                  : null,
            ),
            if (i != lives.length - 1) const SizedBox(height: 4),
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
    this.clears,
  });
  final int player;
  final int lives;
  final bool winner;
  final int? clears;

  @override
  Widget build(BuildContext context) {
    final color = winner ? ReactColors.lime : ReactColors.textSecondary;
    final hearts = lives == 0 ? 'OUT' : List.filled(lives, '♥').join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF090F1B),
        borderRadius: BorderRadius.circular(13),
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
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER $player',
                  style: TextStyle(
                    color: winner ? ReactColors.textPrimary : ReactColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (clears != null)
                  Text(
                    '$clears CLEARS',
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            winner ? 'WINNER  •  $hearts' : hearts,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyResultSummary extends StatelessWidget {
  const _DailyResultSummary({required this.result});
  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    final date = result.dailyDate;
    final dateLabel = date == null
        ? 'TODAY'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReactColors.purple.withValues(alpha: .42)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: ReactColors.purple, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.dailyModifierLabel}  •  $dateLabel',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (result.dailyModifierRule != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    result.dailyModifierRule!,
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunHighlights extends StatelessWidget {
  const _RunHighlights({required this.result, required this.color});
  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final medals = _runMedals(result);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (result.maxStreak > 0)
            _HighlightChip(
              icon: Icons.local_fire_department_rounded,
              label: result.mode == ReactGameMode.sequence
                  ? 'SEQUENCE STREAK ${result.maxStreak}'
                  : 'STREAK ${result.maxStreak}',
              color: ReactColors.coral,
            ),
          for (final medal in medals)
            _HighlightChip(icon: medal.icon, label: medal.label, color: medal.color),
        ],
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: color.withValues(alpha: .36)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
      ],
    ),
  );
}

class _RunMedal {
  const _RunMedal(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

List<_RunMedal> _runMedals(ReactRunResult result) => [
  for (final medal in earnedRunMedals(result))
    switch (medal) {
      RunMedal.perfectRun => const _RunMedal(
        'PERFECT RUN',
        Icons.check_circle_rounded,
        ReactColors.lime,
      ),
      RunMedal.lightning => const _RunMedal(
        'LIGHTNING',
        Icons.bolt_rounded,
        ReactColors.electricBlueBright,
      ),
      RunMedal.survivor => const _RunMedal(
        'SURVIVOR',
        Icons.all_inclusive_rounded,
        ReactColors.lime,
      ),
      RunMedal.dailyMaster => const _RunMedal(
        'DAILY MASTER',
        Icons.emoji_events_rounded,
        ReactColors.purple,
      ),
      RunMedal.clutch => const _RunMedal(
        'CLUTCH',
        Icons.favorite_rounded,
        ReactColors.coral,
      ),
    },
];

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    ],
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: const Color(0xFF1A2B45));
  }
}
