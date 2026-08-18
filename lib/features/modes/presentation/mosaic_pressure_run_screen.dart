import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/react_colors.dart';

class MosaicPressureRunScreen extends StatefulWidget {
  const MosaicPressureRunScreen({super.key});

  @override
  State<MosaicPressureRunScreen> createState() => _MosaicPressureRunScreenState();
}

class _MosaicPressureRunScreenState extends State<MosaicPressureRunScreen> {
  static const _bestKey = 'variant_best_mosaic_pressure';
  static const _runsKey = 'variant_runs_mosaic_pressure';
  static const _tick = Duration(milliseconds: 50);

  final Random _random = Random();
  final List<double> _fill = List<double>.filled(9, 0);
  final List<double> _rates = List<double>.filled(9, 0);

  Timer? _ticker;
  Timer? _countdownTimer;
  int _countdown = 3;
  int _score = 0;
  int _maxDanger = 0;
  bool _go = false;
  bool _running = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _randomizeRates();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _finished) return;
      if (_countdown > 1) {
        setState(() => _countdown -= 1);
      } else if (!_go) {
        setState(() => _go = true);
      } else {
        _countdownTimer?.cancel();
        setState(() => _running = true);
        _ticker = Timer.periodic(_tick, _onTick);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _randomizeRates() {
    for (var i = 0; i < _rates.length; i++) {
      _rates[i] = .0018 + _random.nextDouble() * .0034;
    }
  }

  void _onTick(Timer timer) {
    if (!mounted || !_running || _finished) return;
    final pressure = 1 + min(.85, _score * .012);
    for (var i = 0; i < _fill.length; i++) {
      _fill[i] = min(1.0, _fill[i] + _rates[i] * pressure);
    }
    final fullCount = _fill.where((value) => value >= 1).length;
    _maxDanger = max(_maxDanger, fullCount);
    if (fullCount == 9) {
      _finish();
      return;
    }
    setState(() {});
  }

  void _tapTile(int index) {
    if (!_running || _finished) return;
    final value = _fill[index];
    if (value < .08) return;
    setState(() {
      _fill[index] = 0;
      _rates[index] = .0018 + _random.nextDouble() * .0038;
      _score += 1;
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final oldBest = prefs.getInt(_bestKey) ?? 0;
    final newBest = _score > oldBest;
    await prefs.setInt(_bestKey, max(oldBest, _score));
    await prefs.setInt(_runsKey, (prefs.getInt(_runsKey) ?? 0) + 1);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _MosaicPressureResultScreen(
          score: _score,
          danger: _maxDanger,
          newBest: newBest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = ReactColors.coral;
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          foregroundColor: ReactColors.textPrimary,
                          side: BorderSide(color: accent.withValues(alpha: .35)),
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MOSAIC',
                              style: TextStyle(
                                color: ReactColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'PRESSURE GRID',
                              style: TextStyle(
                                color: accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Metric(label: 'SCORE', value: '$_score'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _PressureHint(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050A13),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: accent.withValues(alpha: .45),
                            width: 2,
                          ),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 9,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 9,
                            mainAxisSpacing: 9,
                          ),
                          itemBuilder: (context, index) {
                            final fill = _fill[index];
                            final color = _tileColor(fill);
                            return GestureDetector(
                              onTap: () => _tapTile(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: const Color(0xFF07111D),
                                  border: Border.all(
                                    color: color.withValues(alpha: .78),
                                    width: 1.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    FractionallySizedBox(
                                      heightFactor: fill,
                                      widthFactor: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: .32),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withValues(alpha: .30),
                                              blurRadius: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '${(fill * 100).round()}',
                                        style: TextStyle(
                                          color: fill > .72
                                              ? Colors.white
                                              : color,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (fill >= 1)
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Icon(
                                          Icons.warning_rounded,
                                          color: ReactColors.coral,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_fill.where((value) => value >= 1).length}/9 TILES FULL',
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (!_running)
              Positioned.fill(
                child: ColoredBox(
                  color: ReactColors.background.withValues(alpha: .96),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PRESSURE GRID',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _go ? 'GO' : '$_countdown',
                          style: TextStyle(
                            color: _go ? accent : ReactColors.textPrimary,
                            fontSize: _go ? 86 : 112,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _tileColor(double fill) {
    if (fill >= .82) return ReactColors.coral;
    if (fill >= .55) return const Color(0xFFFFD33D);
    if (fill >= .28) return ReactColors.purple;
    return ReactColors.electricBlueBright;
  }
}

class _PressureHint extends StatelessWidget {
  const _PressureHint();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: ReactColors.coral.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ReactColors.coral.withValues(alpha: .30)),
        ),
        child: const Row(
          children: [
            Icon(Icons.grid_view_rounded, color: ReactColors.coral, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'TAP TILES TO DRAIN THEM. IF ALL 9 FILL, THE RUN ENDS.',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 9,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ReactColors.coral.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ReactColors.coral.withValues(alpha: .25)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: ReactColors.coral,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _MosaicPressureResultScreen extends StatelessWidget {
  const _MosaicPressureResultScreen({
    required this.score,
    required this.danger,
    required this.newBest,
  });

  final int score;
  final int danger;
  final bool newBest;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ReactColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.grid_view_rounded, color: ReactColors.coral, size: 66),
                const SizedBox(height: 14),
                const Text(
                  'GRID SATURATED',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 92,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  newBest ? 'NEW PRESSURE BEST' : 'TILES DRAINED',
                  style: TextStyle(
                    color: newBest ? ReactColors.lime : ReactColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'PEAK DANGER  $danger/9',
                  style: const TextStyle(
                    color: ReactColors.coral,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const MosaicPressureRunScreen(),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: ReactColors.coral,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('BACK TO MOSAIC'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
