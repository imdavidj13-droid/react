import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

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
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
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

      final bytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SHARE RESULT',
                          style: TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'PREVIEW • THIS CARD WILL BE SHARED AS AN IMAGE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _shareCardKey,
                          child: _ShareCard(
                            result: widget.result,
                            newBest: widget.newBest,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                      backgroundColor: ReactColors.electricBlueBright,
                      foregroundColor: const Color(0xFF020711),
                      disabledBackgroundColor: ReactColors.electricBlueBright
                          .withValues(alpha: .35),
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
  const _ShareCard({required this.result, required this.newBest});

  final ReactRunResult result;
  final bool newBest;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(result.mode);
    final isPassIt = result.mode == ReactGameMode.passIt;
    final isDaily = result.mode == ReactGameMode.daily;
    final medals = _shareMedals(result);

    return SizedBox(
      width: 360,
      height: 450,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF02060C), Color(0xFF071628), Color(0xFF030811)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: .76), width: 1.4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: Stack(
            children: [
              _GlowOrb(
                top: -70,
                right: -60,
                size: 200,
                color: color,
                opacity: .18,
              ),
              const _GlowOrb(
                bottom: -100,
                left: -75,
                size: 230,
                color: ReactColors.purple,
                opacity: .12,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _ShareGridPainter(color: color)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardHeader(mode: result.mode, color: color),
                    const SizedBox(height: 19),
                    Text(
                      _heroEyebrow(result),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scoreLabel(result.mode),
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '${result.score}',
                      style: const TextStyle(
                        color: ReactColors.lime,
                        fontSize: 78,
                        height: .93,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                      ),
                    ),
                    if (newBest && !isPassIt) ...[
                      const SizedBox(height: 7),
                      _Badge(
                        label: isDaily
                            ? 'NEW MODIFIER BEST'
                            : 'NEW PERSONAL BEST',
                        color: ReactColors.lime,
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ],
                    if (medals.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      _MedalStrip(medals: medals),
                    ],
                    const Spacer(),
                    if (isDaily) ...[
                      _DailySummary(result: result, color: color),
                      const SizedBox(height: 10),
                    ] else if (isPassIt) ...[
                      _PassItSummary(result: result, color: color),
                      const SizedBox(height: 10),
                    ],
                    _MetricsRow(result: result),
                    const SizedBox(height: 11),
                    _OutcomeStrip(result: result, color: color),
                    const SizedBox(height: 13),
                    _CardFooter(color: color),
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

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.mode, required this.color});

  final ReactGameMode mode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'RE△CT',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        const Spacer(),
        _Badge(label: mode.label, color: color),
      ],
    );
  }
}

class _MedalStrip extends StatelessWidget {
  const _MedalStrip({required this.medals});

  final List<_ShareMedal> medals;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      children: [
        for (final medal in medals)
          _Badge(label: medal.label, color: medal.color, icon: medal.icon),
      ],
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final date = result.dailyDate;
    final dateLabel = date == null ? 'DATE UNAVAILABLE' : _dailyDateLabel(date);
    final modifierLabel = result.dailyModifierLabel ?? 'DAILY CHALLENGE';
    final rule =
        result.dailyModifierRule ?? '60 COMMANDS • ONE MISS ENDS THE ATTEMPT';

    return _InfoStrip(
      icon: Icons.calendar_today_rounded,
      color: color,
      title: modifierLabel,
      subtitle: '$dateLabel  •  $rule',
    );
  }
}

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
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

class _PassItSummary extends StatelessWidget {
  const _PassItSummary({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

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
      icon: Icons.emoji_events_rounded,
      color: color,
      title: result.winnerPlayer == null
          ? 'PASS IT COMPLETE'
          : 'PLAYER ${result.winnerPlayer} WINS',
      subtitle: lifeSummary,
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.result});

  final ReactRunResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: 'CLEARS',
            value: '${result.successfulCommands}',
            color: ReactColors.electricBlueBright,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(
            label: 'MISSES',
            value: '${result.misses}',
            color: ReactColors.coral,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(
            label: 'AVG',
            value: result.averageTimeSeconds == 0
                ? '--'
                : '${result.averageTimeSeconds.toStringAsFixed(2)}s',
            color: ReactColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OutcomeStrip extends StatelessWidget {
  const _OutcomeStrip({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _InfoStrip(
      icon: switch (result.outcome) {
        ReactRunOutcome.winner ||
        ReactRunOutcome.completed => Icons.emoji_events_rounded,
        ReactRunOutcome.timeUp => Icons.timer_rounded,
        ReactRunOutcome.missedCommand => Icons.bolt_rounded,
        ReactRunOutcome.quit => Icons.stop_circle_outlined,
      },
      color: color,
      title: result.outcomeLabel,
      subtitle: _outcomeDetail(result),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xC007111D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 9),
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
                    fontSize: 8.5,
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
                    fontSize: 6.3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xC007111D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 6.3,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 7.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        const Expanded(
          child: Text(
            'REACTION • REFLEX • SPEED',
            style: TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 6.8,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
        ),
        const Text(
          'CAN YOU BEAT IT?',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 6.8,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareGridPainter extends CustomPainter {
  const _ShareGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .035)
      ..strokeWidth = .6;

    const gap = 28.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShareGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ShareMedal {
  const _ShareMedal(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

List<_ShareMedal> _shareMedals(ReactRunResult result) => [
  for (final medal in earnedRunMedals(result))
    switch (medal) {
      RunMedal.perfectRun => const _ShareMedal(
        'PERFECT RUN',
        Icons.auto_awesome_rounded,
        ReactColors.lime,
      ),
      RunMedal.lightning => const _ShareMedal(
        'LIGHTNING',
        Icons.bolt_rounded,
        ReactColors.electricBlueBright,
      ),
      RunMedal.survivor => const _ShareMedal(
        'SURVIVOR',
        Icons.all_inclusive_rounded,
        ReactColors.lime,
      ),
      RunMedal.dailyMaster => const _ShareMedal(
        'DAILY MASTER',
        Icons.emoji_events_rounded,
        ReactColors.purple,
      ),
      RunMedal.clutch => const _ShareMedal(
        'CLUTCH',
        Icons.favorite_rounded,
        ReactColors.coral,
      ),
    },
];

String _scoreLabel(ReactGameMode mode) => switch (mode) {
  ReactGameMode.classic => 'FINAL SCORE',
  ReactGameMode.blitz => '60 SECOND SCORE',
  ReactGameMode.endless => 'COMMANDS SURVIVED',
  ReactGameMode.daily => 'DAILY SCORE',
  ReactGameMode.passIt => 'MATCH COMMANDS',
};

String _heroEyebrow(ReactRunResult result) {
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {
    return 'PLAYER ${result.winnerPlayer} WINS';
  }
  return result.outcomeLabel;
}

String _outcomeDetail(ReactRunResult result) => switch (result.outcome) {
  ReactRunOutcome.missedCommand =>
    result.failedCommand?.title ?? 'MISSED COMMAND',
  ReactRunOutcome.timeUp => '60 SECOND RUN COMPLETE',
  ReactRunOutcome.completed =>
    'ALL ${result.successfulCommands} COMMANDS CLEARED',
  ReactRunOutcome.winner => 'LAST PLAYER STANDING',
  ReactRunOutcome.quit => 'RUN ENDED',
};

String _shareText(ReactRunResult result) {
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {
    return 'RE△CT PASS IT — Player ${result.winnerPlayer} wins with '
        '${result.successfulCommands} commands cleared.';
  }
  if (result.mode == ReactGameMode.daily) {
    final modifier = result.dailyModifierLabel ?? 'CHALLENGE';
    return 'RE△CT DAILY $modifier — ${result.score}/60. Can you beat it?';
  }
  return 'RE△CT ${result.mode.label} — ${result.score} points. Can you beat it?';
}

Color _modeColor(ReactGameMode mode) => switch (mode) {
  ReactGameMode.classic => ReactColors.electricBlueBright,
  ReactGameMode.blitz => ReactColors.coral,
  ReactGameMode.endless => ReactColors.lime,
  ReactGameMode.daily => ReactColors.purple,
  ReactGameMode.passIt => const Color(0xFFFFB85A),
};