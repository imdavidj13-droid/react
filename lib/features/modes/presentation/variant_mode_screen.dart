import 'package:flutter/material.dart';

import '../../../core/cosmetics/react_cosmetics.dart';
import '../../../core/theme/react_colors.dart';
import '../data/local_variant_mode_stats.dart';
import '../domain/react_variant_mode.dart';
import 'variant_run_screen.dart';

class VariantModeScreen extends StatefulWidget {
  const VariantModeScreen({required this.mode, super.key});

  final ReactVariantMode mode;

  @override
  State<VariantModeScreen> createState() => _VariantModeScreenState();
}

class _VariantModeScreenState extends State<VariantModeScreen> {
  late Future<(int, int)> _stats;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _stats = Future.wait<int>([
      LocalVariantModeStats.best(widget.mode),
      LocalVariantModeStats.plays(widget.mode),
    ]).then((values) => (values[0], values[1]));
  }

  Future<void> _start() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => VariantRunScreen(mode: widget.mode)),
    );
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReactCosmetics.palette;
    final accent = ReactCosmetics.effectAccentFor(widget.mode.color);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: palette.primary.withValues(alpha: .07),
                          foregroundColor: ReactColors.textPrimary,
                          side: BorderSide(color: accent.withValues(alpha: .35)),
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        'MODE LAB',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 14 : 22),
                  Container(
                    padding: EdgeInsets.all(compact ? 18 : 22),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: .045),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: accent.withValues(alpha: .60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: compact ? 66 : 78,
                              height: compact ? 66 : 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.background,
                                border: Border.all(color: accent, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: .16),
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                              child: Icon(widget.mode.icon, color: accent, size: compact ? 31 : 37),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: accent.withValues(alpha: .55)),
                              ),
                              child: Text(
                                widget.mode.badge,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 18 : 24),
                        Text(
                          widget.mode.title,
                          style: const TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          widget.mode.subtitle,
                          style: const TextStyle(
                            color: ReactColors.textSecondary,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.mode.detail,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Container(
                    padding: EdgeInsets.all(compact ? 15 : 18),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: .035),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.primary.withValues(alpha: .18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOW IT WORKS',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          widget.mode.rules,
                          style: const TextStyle(
                            color: ReactColors.textPrimary,
                            fontSize: 12.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<(int, int)>(
                    future: _stats,
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? (0, 0);
                      return Row(
                        children: [
                          Expanded(child: _Stat(label: 'BEST', value: '${stats.$1}', color: accent)),
                          const SizedBox(width: 10),
                          Expanded(child: _Stat(label: 'RUNS', value: '${stats.$2}', color: palette.secondary)),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: compact ? 14 : 20),
                  SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: _start,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'START MODE',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: ReactColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 23, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
