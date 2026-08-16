import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/cosmetics/react_cosmetics.dart';
import '../../../core/theme/react_colors.dart';
import '../../gameplay/domain/react_command.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../domain/run_medal.dart';

class ResultShareScreen extends StatefulWidget {
  const ResultShareScreen({
    required this.result,
    required this.newBest,
    super.key,
  });

  final ReactRunResult result;
  final bool newBest;

  @override
  State<ResultShareScreen> createState() => _ResultShareScreenState();
}

class _ResultShareScreenState extends State<ResultShareScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(BuildContext originContext) async {
    if (_sharing) return;

    final box = originContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Share card is not ready yet.');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('Could not create result image.');
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              byteData.buffer.asUint8List(),
              mimeType: 'image/png',
            ),
          ],
          fileNameOverrides: [
            'react-${widget.result.mode.name.toLowerCase()}-result.png',
          ],
          title: 'Share RE△CT result',
          text: _shareText(widget.result),
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create the share image.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pro = ReactCosmetics.currentShareStyle == ReactShareStyle.pro;

    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF07101E),
                      foregroundColor: ReactColors.textPrimary,
                      side: const BorderSide(color: Color(0xFF1E3552)),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        pro ? 'PRO SHARE CARD' : 'SHARE RESULT',
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                pro
                    ? 'PRO STYLE • THIS CARD WILL BE SHARED AS AN IMAGE'
                    : 'PREVIEW • THIS CARD WILL BE SHARED AS AN IMAGE',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _shareCardKey,
                      child: _ShareCard(
                        result: widget.result,
                        newBest: widget.newBest,
                        pro: pro,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Builder(
                builder: (buttonContext) => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : () => _share(buttonContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: pro
                          ? ReactColors.purple
                          : ReactColors.electricBlueBright,
                      foregroundColor: const Color(0xFF020711),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF020711),
                            ),
                          )
                        : const Icon(Icons.ios_share_rounded, size: 20),
                    label: Text(
                      _sharing ? 'CREATING IMAGE...' : 'SHARE IMAGE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.result,
    required this.newBest,
    required this.pro,
  });

  final ReactRunResult result;
  final bool newBest;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(result.mode);
    final medals = earnedRunMedals(result);

    return SizedBox(
      width: 360,
      height: 450,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: pro
                ? const [
                    Color(0xFF070510),
                    Color(0xFF11132A),
                    Color(0xFF04070E),
                  ]
                : const [
                    Color(0xFF02060C),
                    Color(0xFF071628),
                    Color(0xFF030811),
                  ],
          ),
          borderRadius: BorderRadius.circular(pro ? 22 : 30),
          border: Border.all(
            color: color.withValues(alpha: pro ? .92 : .76),
            width: pro ? 2 : 1.4,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(pro ? 20 : 29),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(color: color, dense: pro),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  pro ? 22 : 24,
                  pro ? 20 : 22,
                  pro ? 22 : 24,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(mode: result.mode, color: color, pro: pro),
                    SizedBox(height: pro ? 17 : 19),
                    Text(
                      _heroEyebrow(result),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _scoreLabel(result.mode),
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      '${result.score}',
                      style: TextStyle(
                        color: pro
                            ? ReactColors.textPrimary
                            : ReactColors.lime,
                        fontSize: pro ? 82 : 76,
                        height: .92,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3.2,
                      ),
                    ),
                    if (newBest && result.mode != ReactGameMode.passIt) ...[
                      const SizedBox(height: 7),
                      _Badge(
                        label: result.mode == ReactGameMode.daily
                            ? 'NEW MODIFIER BEST'
                            : 'NEW PERSONAL BEST',
                        color: ReactColors.lime,
                      ),
                    ],
                    if (medals.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      _MedalStrip(medals: medals),
                    ],
                    const Spacer(),
                    if (result.mode == ReactGameMode.daily) ...[
                      _DailySummary(result: result, color: color, pro: pro),
                      const SizedBox(height: 9),
                    ] else if (result.mode == ReactGameMode.passIt) ...[
                      _PassItSummary(result: result, color: color, pro: pro),
                      const SizedBox(height: 9),
                    ],
                    pro
                        ? _ProMetrics(result: result, color: color)
                        : _Metrics(result: result),
                    const SizedBox(height: 9),
                    _Outcome(result: result, color: color),
                    const SizedBox(height: 10),
                    _Footer(color: color, pro: pro),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.color,
    required this.pro,
  });

  final ReactGameMode mode;
  final Color color;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'RE△CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const Spacer(),
        if (pro) ...[
          const _Badge(label: 'PRO', color: ReactColors.purple),
          const SizedBox(width: 6),
        ],
        _Badge(label: mode.label, color: color),
      ],
    );
  }
}

class _MedalStrip extends StatelessWidget {
  const _MedalStrip({required this.medals});

  final List<RunMedal> medals;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final medal in medals)
          _Badge(label: _medalLabel(medal), color: _medalColor(medal)),
      ],
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({
    required this.result,
    required this.color,
    required this.pro,
  });

  final ReactRunResult result;
  final Color color;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final date = result.dailyDate;
    final dateLabel = date == null ? 'DATE UNAVAILABLE' : _dailyDateLabel(date);
    final modifier = result.dailyModifierLabel ?? 'DAILY CHALLENGE';
    final rule = result.dailyModifierRule ?? 'ONE MISS ENDS THE ATTEMPT';

    return _InfoStrip(
      color: color,
      icon: Icons.calendar_today_rounded,
      title: modifier,
      subtitle: '$dateLabel  •  $rule',
      emphasized: pro,
    );
  }
}

class _PassItSummary extends StatelessWidget {
  const _PassItSummary({
    required this.result,
    required this.color,
    required this.pro,
  });

  final ReactRunResult result;
  final Color color;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final lives = result.playerLives ?? const <int>[];
    final lifeSummary = lives.isEmpty
        ? 'LOCAL MULTIPLAYER'
        : [
            for (var index = 0; index < lives.length; index++)
              'P${index + 1} ${lives[index]}♥',
          ].join('  •  ');

    return _InfoStrip(
      color: color,
      icon: Icons.emoji_events_rounded,
      title: result.winnerPlayer == null
          ? 'PASS IT COMPLETE'
          : 'PLAYER ${result.winnerPlayer} WINS',
      subtitle: lifeSummary,
      emphasized: pro,
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.result});

  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    final sequence = result.mode == ReactGameMode.sequence;
    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: sequence ? 'SEQUENCES' : 'CLEARS',
            value: '${result.successfulCommands}',
            color: ReactColors.electricBlueBright,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _Metric(
            label: sequence ? 'MISTAKES' : 'MISSES',
            value: '${result.misses}',
            color: ReactColors.coral,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _Metric(
            label: sequence ? 'AVG CLEAR' : 'AVG',
            value: _average(result),
            color: ReactColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ProMetrics extends StatelessWidget {
  const _ProMetrics({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sequence = result.mode == ReactGameMode.sequence;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xB5070A12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FlatMetric(
              label: sequence ? 'SEQUENCES' : 'CLEARS',
              value: '${result.successfulCommands}',
              color: color,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _FlatMetric(
              label: sequence ? 'AVG CLEAR' : 'AVG TIME',
              value: _average(result),
              color: ReactColors.textPrimary,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _FlatMetric(
              label: sequence ? 'SEQ STREAK' : 'STREAK',
              value: '${result.maxStreak}',
              color: ReactColors.lime,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xC007111D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 6.2,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatMetric extends StatelessWidget {
  const _FlatMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          child: Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 5.8,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 25, color: ReactColors.border);
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emphasized,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized
            ? color.withValues(alpha: .08)
            : const Color(0xC007111D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: emphasized ? .48 : .30),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 8.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 6.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
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

class _Outcome extends StatelessWidget {
  const _Outcome({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _InfoStrip(
      color: color,
      icon: _outcomeIcon(result),
      title: result.mode == ReactGameMode.sequence
          ? 'OUT OF LIVES'
          : result.outcomeLabel,
      subtitle: _outcomeDetail(result),
      emphasized: false,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 6.8,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.color, required this.pro});

  final Color color;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 2, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            pro ? 'PERFORMANCE CARD' : 'REACTION • REFLEX • SPEED',
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 6.4,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ),
        Text(
          pro ? 'BEAT THIS.' : 'CAN YOU BEAT IT?',
          style: const TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 6.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color, required this.dense});

  final Color color;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: dense ? .045 : .035)
      ..strokeWidth = .6;
    final gap = dense ? 22.0 : 28.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dense != dense;
}

String _average(ReactRunResult result) => result.averageTimeSeconds == 0
    ? '--'
    : '${result.averageTimeSeconds.toStringAsFixed(2)}s';

String _medalLabel(RunMedal medal) => switch (medal) {
      RunMedal.perfectRun => 'PERFECT RUN',
      RunMedal.lightning => 'LIGHTNING',
      RunMedal.survivor => 'SURVIVOR',
      RunMedal.dailyMaster => 'DAILY MASTER',
      RunMedal.clutch => 'CLUTCH',
    };

Color _medalColor(RunMedal medal) => switch (medal) {
      RunMedal.perfectRun => ReactColors.lime,
      RunMedal.lightning => ReactColors.electricBlueBright,
      RunMedal.survivor => ReactColors.lime,
      RunMedal.dailyMaster => ReactColors.purple,
      RunMedal.clutch => ReactColors.coral,
    };

String _dailyDateLabel(DateTime date) {
  const months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]} ${date.year}';
}

String _scoreLabel(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => 'FINAL SCORE',
      ReactGameMode.blitz => '60 SECOND SCORE',
      ReactGameMode.endless => 'COMMANDS SURVIVED',
      ReactGameMode.daily => 'DAILY SCORE',
      ReactGameMode.passIt => 'MATCH COMMANDS',
      ReactGameMode.sequence => 'SEQUENCES CLEARED',
    };

String _heroEyebrow(ReactRunResult result) {
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {
    return 'PLAYER ${result.winnerPlayer} WINS';
  }
  if (result.mode == ReactGameMode.sequence) return 'OUT OF LIVES';
  return result.outcomeLabel;
}

String _outcomeDetail(ReactRunResult result) {
  if (result.mode == ReactGameMode.sequence) {
    return '${result.successfulCommands} SEQUENCES • ${result.misses} MISTAKES';
  }
  return switch (result.outcome) {
    ReactRunOutcome.missedCommand =>
      result.failedCommand?.title ?? 'MISSED COMMAND',
    ReactRunOutcome.timeUp => '60 SECOND RUN COMPLETE',
    ReactRunOutcome.completed =>
      '${result.successfulCommands} COMMANDS CLEARED',
    ReactRunOutcome.winner => result.winnerPlayer == null
        ? 'LAST PLAYER STANDING'
        : 'PLAYER ${result.winnerPlayer} WINS',
    ReactRunOutcome.quit => 'RUN ENDED',
  };
}

IconData _outcomeIcon(ReactRunResult result) {
  if (result.mode == ReactGameMode.sequence) {
    return Icons.blur_circular_rounded;
  }
  return switch (result.outcome) {
    ReactRunOutcome.winner || ReactRunOutcome.completed =>
      Icons.emoji_events_rounded,
    ReactRunOutcome.timeUp => Icons.timer_rounded,
    ReactRunOutcome.missedCommand => Icons.bolt_rounded,
    ReactRunOutcome.quit => Icons.stop_circle_outlined,
  };
}

String _shareText(ReactRunResult result) {
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {
    return 'RE△CT PASS IT — Player ${result.winnerPlayer} wins with '
        '${result.successfulCommands} commands cleared.';
  }
  if (result.mode == ReactGameMode.daily) {
    final modifier = result.dailyModifierLabel ?? 'CHALLENGE';
    return 'RE△CT DAILY $modifier — ${result.score}. Can you beat it?';
  }
  if (result.mode == ReactGameMode.sequence) {
    return 'RE△CT SEQUENCE — ${result.score} sequences cleared. Can you beat it?';
  }
  return 'RE△CT ${result.mode.label} — ${result.score} points. Can you beat it?';
}

Color _modeColor(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => ReactColors.electricBlueBright,
      ReactGameMode.blitz => ReactColors.coral,
      ReactGameMode.endless => ReactColors.lime,
      ReactGameMode.daily => ReactColors.purple,
      ReactGameMode.passIt => const Color(0xFFFFB85A),
      ReactGameMode.sequence => ReactColors.electricBlueBright,
    };
