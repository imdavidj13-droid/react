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
                      child: pro
                          ? _ProShareCard(
                              result: widget.result,
                              newBest: widget.newBest,
                            )
                          : _CoreShareCard(
                              result: widget.result,
                              newBest: widget.newBest,
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

class _CoreShareCard extends StatelessWidget {
  const _CoreShareCard({required this.result, required this.newBest});

  final ReactRunResult result;
  final bool newBest;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(result.mode);
    return _CardFrame(
      color: color,
      background: const [Color(0xFF02060C), Color(0xFF071628), Color(0xFF030811)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(mode: result.mode, color: color),
            const SizedBox(height: 20),
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
            if (newBest && result.mode != ReactGameMode.passIt) ...[
              const SizedBox(height: 8),
              _Badge(
                label: result.mode == ReactGameMode.daily
                    ? 'NEW DAILY BEST'
                    : 'NEW PERSONAL BEST',
                color: ReactColors.lime,
              ),
            ],
            const Spacer(),
            if (result.mode == ReactGameMode.daily) ...[
              _DailyRule(result: result, color: color),
              const SizedBox(height: 10),
            ],
            _Metrics(result: result),
            const SizedBox(height: 11),
            _Outcome(result: result, color: color),
            const SizedBox(height: 13),
            _Footer(color: color),
          ],
        ),
      ),
    );
  }
}

class _ProShareCard extends StatelessWidget {
  const _ProShareCard({required this.result, required this.newBest});

  final ReactRunResult result;
  final bool newBest;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(result.mode);
    final medals = earnedRunMedals(result);

    return _CardFrame(
      color: color,
      background: const [Color(0xFF070510), Color(0xFF11132A), Color(0xFF04070E)],
      pro: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'RE△CT',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.2,
                  ),
                ),
                const Spacer(),
                const _Badge(label: 'PRO', color: ReactColors.purple),
                const SizedBox(width: 6),
                _Badge(label: result.mode.label, color: color),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scoreLabel(result.mode),
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.score}',
                        style: const TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 92,
                          height: .88,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .08),
                    border: Border.all(color: color.withValues(alpha: .65)),
                  ),
                  child: Icon(_modeIcon(result.mode), color: color, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                if (newBest && result.mode != ReactGameMode.passIt)
                  const _Badge(label: 'NEW BEST', color: ReactColors.lime),
                if (newBest && result.mode != ReactGameMode.passIt)
                  const SizedBox(width: 6),
                if (medals.isNotEmpty)
                  _Badge(
                    label: '${medals.length} MEDAL${medals.length == 1 ? '' : 'S'}',
                    color: ReactColors.purple,
                  ),
              ],
            ),
            const Spacer(),
            if (result.mode == ReactGameMode.daily) ...[
              _DailyRule(result: result, color: color, pro: true),
              const SizedBox(height: 10),
            ],
            _ProMetrics(result: result, color: color),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xD9080A12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withValues(alpha: .30)),
              ),
              child: Row(
                children: [
                  Icon(_outcomeIcon(result), color: color, size: 17),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${result.outcomeLabel}  •  ${_outcomeDetail(result)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Container(width: 24, height: 2, color: color),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'REACTION PERFORMANCE CARD',
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Text(
                  'BEAT THIS.',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.color,
    required this.background,
    required this.child,
    this.pro = false,
  });

  final Color color;
  final List<Color> background;
  final Widget child;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 450,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: background,
          ),
          borderRadius: BorderRadius.circular(pro ? 22 : 30),
          border: Border.all(
            color: color.withValues(alpha: pro ? .92 : .76),
            width: pro ? 2 : 1.4,
          ),
          boxShadow: pro
              ? [BoxShadow(color: color.withValues(alpha: .14), blurRadius: 28)]
              : null,
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
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mode, required this.color});
  final ReactGameMode mode;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
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

class _Metrics extends StatelessWidget {
  const _Metrics({required this.result});
  final ReactRunResult result;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _Metric(label: 'CLEARS', value: '${result.successfulCommands}', color: ReactColors.electricBlueBright)),
          const SizedBox(width: 8),
          Expanded(child: _Metric(label: 'MISSES', value: '${result.misses}', color: ReactColors.coral)),
          const SizedBox(width: 8),
          Expanded(child: _Metric(label: 'AVG', value: _average(result), color: ReactColors.textPrimary)),
        ],
      );
}

class _ProMetrics extends StatelessWidget {
  const _ProMetrics({required this.result, required this.color});
  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xB5070A12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Expanded(child: _FlatMetric(label: 'CLEARS', value: '${result.successfulCommands}', color: color)),
            const _Divider(),
            Expanded(child: _FlatMetric(label: 'MISSES', value: '${result.misses}', color: ReactColors.coral)),
            const _Divider(),
            Expanded(child: _FlatMetric(label: 'AVG TIME', value: _average(result), color: ReactColors.textPrimary)),
            const _Divider(),
            Expanded(child: _FlatMetric(label: 'STREAK', value: '${result.maxStreak}', color: ReactColors.lime)),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xC007111D),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: .20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 6.3, fontWeight: FontWeight.w900, letterSpacing: .8)),
          ],
        ),
      );
}

class _FlatMetric extends StatelessWidget {
  const _FlatMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900))),
          const SizedBox(height: 3),
          FittedBox(child: Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 5.8, fontWeight: FontWeight.w900, letterSpacing: .6))),
        ],
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 26, color: ReactColors.border);
}

class _DailyRule extends StatelessWidget {
  const _DailyRule({required this.result, required this.color, this.pro = false});
  final ReactRunResult result;
  final Color color;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final modifier = result.dailyModifierLabel ?? 'DAILY CHALLENGE';
    final rule = result.dailyModifierRule ?? 'ONE MISS ENDS THE ATTEMPT';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: pro ? color.withValues(alpha: .08) : const Color(0xC007111D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: pro ? .48 : .30)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: color, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modifier, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ReactColors.textPrimary, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: .7)),
                const SizedBox(height: 2),
                Text(rule, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 6.3, fontWeight: FontWeight.w800, letterSpacing: .35)),
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
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xC007111D),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: .30)),
        ),
        child: Row(
          children: [
            Icon(_outcomeIcon(result), color: color, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${result.outcomeLabel} • ${_outcomeDetail(result)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ReactColors.textPrimary, fontSize: 8, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .50)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 7.2, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          const Expanded(child: Text('REACTION • REFLEX • SPEED', style: TextStyle(color: ReactColors.textSecondary, fontSize: 6.8, fontWeight: FontWeight.w900, letterSpacing: .9))),
          const Text('CAN YOU BEAT IT?', style: TextStyle(color: ReactColors.textPrimary, fontSize: 6.8, fontWeight: FontWeight.w900, letterSpacing: .7)),
        ],
      );
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
        '${result.successfulCommands} COMMANDS CLEARED',
      ReactRunOutcome.winner => 'LAST PLAYER STANDING',
      ReactRunOutcome.quit => 'RUN ENDED',
    };

IconData _outcomeIcon(ReactRunResult result) => switch (result.outcome) {
      ReactRunOutcome.winner || ReactRunOutcome.completed =>
        Icons.emoji_events_rounded,
      ReactRunOutcome.timeUp => Icons.timer_rounded,
      ReactRunOutcome.missedCommand => Icons.bolt_rounded,
      ReactRunOutcome.quit => Icons.stop_circle_outlined,
    };

IconData _modeIcon(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => Icons.bolt_rounded,
      ReactGameMode.blitz => Icons.timer_rounded,
      ReactGameMode.endless => Icons.all_inclusive_rounded,
      ReactGameMode.daily => Icons.calendar_today_rounded,
      ReactGameMode.passIt => Icons.groups_2_rounded,
    };

String _shareText(ReactRunResult result) {
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {
    return 'RE△CT PASS IT — Player ${result.winnerPlayer} wins with '
        '${result.successfulCommands} commands cleared.';
  }
  if (result.mode == ReactGameMode.daily) {
    final modifier = result.dailyModifierLabel ?? 'CHALLENGE';
    return 'RE△CT DAILY $modifier — ${result.score}. Can you beat it?';
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
