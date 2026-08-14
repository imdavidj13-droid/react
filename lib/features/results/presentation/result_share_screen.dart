import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/react_colors.dart';
import '../../gameplay/domain/react_run_result.dart';

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
      final box = originContext.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: [
            'react-${widget.result.mode.name.toLowerCase()}-result.png',
          ],
          title: 'Share RE△CT result',
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const Expanded(
                    child: Center(
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
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'PREVIEW • THE CARD BELOW IS THE IMAGE THAT WILL BE SHARED',
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
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
                      disabledBackgroundColor:
                          ReactColors.electricBlueBright.withValues(alpha: .35),
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
    final scoreLabel = isPassIt ? 'COMMANDS CLEARED' : 'FINAL SCORE';
    final outcomeDetail = switch (result.outcome) {
      ReactRunOutcome.missedCommand => result.failedCommand?.title ?? 'MISSED COMMAND',
      ReactRunOutcome.timeUp => '60 SECOND RUN COMPLETE',
      ReactRunOutcome.completed => 'ALL ${result.successfulCommands} COMMANDS CLEARED',
      ReactRunOutcome.winner => 'PLAYER ${result.winnerPlayer ?? '-'} WINS',
      ReactRunOutcome.quit => 'RUN ENDED',
    };

    return SizedBox(
      width: 360,
      height: 450,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF03070D),
              Color(0xFF081525),
              Color(0xFF040810),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: .76), width: 1.4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: Stack(
            children: [
              Positioned(
                top: -72,
                right: -58,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: .18),
                        color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -95,
                left: -70,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ReactColors.purple.withValues(alpha: .12),
                        ReactColors.purple.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: color.withValues(alpha: .55),
                            ),
                          ),
                          child: Text(
                            result.mode.label,
                            style: TextStyle(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      result.outcomeLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      scoreLabel,
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
                        height: .95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                      ),
                    ),
                    if (newBest && !isPassIt) ...[
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ReactColors.lime.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ReactColors.lime.withValues(alpha: .48),
                          ),
                        ),
                        child: const Text(
                          'NEW PERSONAL BEST',
                          style: TextStyle(
                            color: ReactColors.lime,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: _ShareMetric(
                            label: 'CLEARS',
                            value: '${result.successfulCommands}',
                            color: ReactColors.electricBlueBright,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ShareMetric(
                            label: 'MISSES',
                            value: '${result.misses}',
                            color: ReactColors.coral,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ShareMetric(
                            label: 'AVG',
                            value: result.averageTimeSeconds == 0
                                ? '--'
                                : '${result.averageTimeSeconds.toStringAsFixed(2)}s',
                            color: ReactColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xAA07111D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: .32)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            result.outcome == ReactRunOutcome.winner
                                ? Icons.emoji_events_rounded
                                : Icons.bolt_rounded,
                            color: color,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              outcomeDetail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ReactColors.textPrimary,
                                fontSize: 9,
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
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'REACTION • REFLEX • SPEED',
                          style: TextStyle(
                            color: ReactColors.textSecondary,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'CAN YOU BEAT IT?',
                          style: TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ],
                    ),
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

class _ShareMetric extends StatelessWidget {
  const _ShareMetric({
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
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xAA07111D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

Color _modeColor(ReactGameMode mode) => switch (mode) {
      ReactGameMode.classic => ReactColors.electricBlueBright,
      ReactGameMode.blitz => ReactColors.coral,
      ReactGameMode.endless => ReactColors.lime,
      ReactGameMode.daily => ReactColors.purple,
      ReactGameMode.passIt => const Color(0xFFFFB85A),
    };
