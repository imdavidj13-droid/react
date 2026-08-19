from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, found {count}')
    p.write_text(text.replace(old, new, 1))


# Home overlay controls: keep all four utilities in the same top row.
replace_once(
    'lib/app/react_app.dart',
    """        Positioned(\n          right: 15,\n          top: MediaQuery.paddingOf(context).top + 58,""",
    """        Positioned(\n          right: 62,\n          top: MediaQuery.paddingOf(context).top + 10,""",
)
replace_once(
    'lib/app/react_app.dart',
    """        Positioned(\n          left: 15,\n          top: MediaQuery.paddingOf(context).top + 58,""",
    """        Positioned(\n          left: 62,\n          top: MediaQuery.paddingOf(context).top + 10,""",
)

# Shift the streak unit slightly inward from the right edge.
replace_once(
    'lib/features/home/presentation/home_screen.dart',
    """                          const SizedBox(width: 14),\n                          _Streak(days: stats.dailyStreak),""",
    """                          const SizedBox(width: 14),\n                          Padding(\n                            padding: const EdgeInsets.only(right: 10),\n                            child: _Streak(days: stats.dailyStreak),\n                          ),""",
)

# Friends: show the current player's own immutable RX code and make it copyable.
replace_once(
    'lib/features/friends/presentation/friends_screen.dart',
    """import 'package:flutter/material.dart';\n\nimport '../../../core/theme/react_colors.dart';\nimport '../data/friends_repository.dart';""",
    """import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n\nimport '../../../core/theme/react_colors.dart';\nimport '../../player/data/player_profile_repository.dart';\nimport '../data/friends_repository.dart';""",
)
replace_once(
    'lib/features/friends/presentation/friends_screen.dart',
    """  late Future<FriendsSnapshot> _snapshot;\n  FriendPlayer? _searchResult;""",
    """  late Future<FriendsSnapshot> _snapshot;\n  late Future<PlayerProfileData> _profile;\n  FriendPlayer? _searchResult;""",
)
replace_once(
    'lib/features/friends/presentation/friends_screen.dart',
    """  void initState() {\n    super.initState();\n    _reload();\n  }""",
    """  void initState() {\n    super.initState();\n    _profile = const PlayerProfileRepository().load();\n    _reload();\n  }""",
)
replace_once(
    'lib/features/friends/presentation/friends_screen.dart',
    """                _buildOverview(snapshot),\n                const SizedBox(height: 20),\n                const _SectionTitle(\n                  'FIND A PLAYER',""",
    """                _buildOverview(snapshot),\n                const SizedBox(height: 12),\n                FutureBuilder<PlayerProfileData>(\n                  future: _profile,\n                  builder: (context, profileSnapshot) {\n                    final profile = profileSnapshot.data;\n                    if (profile == null) return const SizedBox.shrink();\n                    return _OwnCodeCard(\n                      playerCode: profile.playerCode,\n                      onCopy: () async {\n                        await Clipboard.setData(\n                          ClipboardData(text: profile.playerCode),\n                        );\n                        if (!context.mounted) return;\n                        ScaffoldMessenger.of(context).showSnackBar(\n                          const SnackBar(content: Text('Player code copied.')),\n                        );\n                      },\n                    );\n                  },\n                ),\n                const SizedBox(height: 20),\n                const _SectionTitle(\n                  'FIND A PLAYER',""",
)
replace_once(
    'lib/features/friends/presentation/friends_screen.dart',
    """class _Header extends StatelessWidget {""",
    """class _OwnCodeCard extends StatelessWidget {\n  const _OwnCodeCard({required this.playerCode, required this.onCopy});\n\n  final String playerCode;\n  final VoidCallback onCopy;\n\n  @override\n  Widget build(BuildContext context) => Container(\n        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),\n        decoration: BoxDecoration(\n          color: const Color(0xFF07111D),\n          borderRadius: BorderRadius.circular(18),\n          border: Border.all(\n            color: ReactColors.electricBlueBright.withValues(alpha: .35),\n          ),\n        ),\n        child: Row(\n          children: [\n            const Icon(\n              Icons.badge_outlined,\n              color: ReactColors.electricBlueBright,\n            ),\n            const SizedBox(width: 11),\n            Expanded(\n              child: Column(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  const Text(\n                    'YOUR PLAYER CODE',\n                    style: TextStyle(\n                      color: ReactColors.textSecondary,\n                      fontSize: 8,\n                      fontWeight: FontWeight.w900,\n                      letterSpacing: 1.1,\n                    ),\n                  ),\n                  const SizedBox(height: 4),\n                  SelectableText(\n                    playerCode,\n                    style: const TextStyle(\n                      color: ReactColors.textPrimary,\n                      fontSize: 16,\n                      fontWeight: FontWeight.w900,\n                      letterSpacing: .7,\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            IconButton(\n              tooltip: 'Copy player code',\n              onPressed: onCopy,\n              style: IconButton.styleFrom(\n                foregroundColor: ReactColors.electricBlueBright,\n                backgroundColor:\n                    ReactColors.electricBlueBright.withValues(alpha: .08),\n              ),\n              icon: const Icon(Icons.copy_rounded, size: 20),\n            ),\n          ],\n        ),\n      );\n}\n\nclass _Header extends StatelessWidget {""",
)

# Replace Pressure Grid with original-Mosaic-style active tiles.
Path('lib/features/modes/presentation/mosaic_pressure_run_screen.dart').write_text(r'''import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/react_audio.dart';
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
  final List<bool> _active = List<bool>.filled(9, false);

  Timer? _ticker;
  Timer? _countdownTimer;
  int _countdown = 3;
  int _score = 0;
  int _elapsedMs = 0;
  int _spawnClockMs = 0;
  int _peakActive = 0;
  bool _go = false;
  bool _running = false;
  bool _finished = false;
  bool _newBest = false;

  int get _activeCount => _active.where((value) => value).length;

  int get _spawnIntervalMs {
    final timePressure = (_elapsedMs ~/ 1000) * 5;
    final scorePressure = _score * 18;
    return max(220, 1150 - timePressure - scorePressure);
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    ReactAudio.play(ReactSoundCue.countdownTick);
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || _finished) return;
      if (_countdown > 1) {
        setState(() => _countdown -= 1);
        ReactAudio.play(ReactSoundCue.countdownTick);
      } else if (!_go) {
        setState(() => _go = true);
        ReactAudio.play(ReactSoundCue.countdownGo);
      } else {
        _countdownTimer?.cancel();
        setState(() => _running = true);
        _activateRandomTile();
        _ticker = Timer.periodic(_tick, _onTick);
      }
    });
  }

  void _onTick(Timer timer) {
    if (!mounted || !_running || _finished) return;
    _elapsedMs += _tick.inMilliseconds;
    _spawnClockMs += _tick.inMilliseconds;

    while (_spawnClockMs >= _spawnIntervalMs && !_finished) {
      _spawnClockMs -= _spawnIntervalMs;
      _activateRandomTile();
    }
  }

  void _activateRandomTile() {
    if (_finished) return;
    final available = <int>[
      for (var i = 0; i < _active.length; i++)
        if (!_active[i]) i,
    ];

    if (available.isEmpty) {
      _finish();
      return;
    }

    final index = available[_random.nextInt(available.length)];
    setState(() {
      _active[index] = true;
      _peakActive = max(_peakActive, _activeCount);
    });
    ReactAudio.play(ReactSoundCue.command);

    if (_activeCount >= 9) {
      _finish();
    }
  }

  void _tapTile(int index) {
    if (!_running || _finished || !_active[index]) return;
    setState(() {
      _active[index] = false;
      _score += 1;
    });
    ReactAudio.play(ReactSoundCue.success);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _running = false;
    _ticker?.cancel();
    _countdownTimer?.cancel();
    ReactAudio.play(ReactSoundCue.completed);

    final prefs = await SharedPreferences.getInstance();
    final oldBest = prefs.getInt(_bestKey) ?? 0;
    final newBest = _score > oldBest;
    await prefs.setInt(_bestKey, max(oldBest, _score));
    await prefs.setInt(_runsKey, (prefs.getInt(_runsKey) ?? 0) + 1);
    if (!mounted) return;
    setState(() => _newBest = newBest);
  }

  void _restart() {
    _ticker?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      for (var i = 0; i < _active.length; i++) {
        _active[i] = false;
      }
      _countdown = 3;
      _score = 0;
      _elapsedMs = 0;
      _spawnClockMs = 0;
      _peakActive = 0;
      _go = false;
      _running = false;
      _finished = false;
      _newBest = false;
    });
    _startCountdown();
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
                          side: BorderSide(
                            color: accent.withValues(alpha: .35),
                          ),
                        ),
                        icon: const Icon(Icons.pause_rounded),
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
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'PRESSURE GRID',
                              style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Metric(label: 'SCORE', value: '$_score'),
                      const SizedBox(width: 8),
                      _Metric(label: 'ACTIVE', value: '$_activeCount/9'),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 390),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050A13),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accent.withValues(alpha: .48),
                        width: 2,
                      ),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 9,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final active = _active[index];
                          return GestureDetector(
                            onTap: () => _tapTile(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 90),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: active
                                    ? accent.withValues(alpha: .20)
                                    : const Color(0xFF07101A),
                                border: Border.all(
                                  color: active
                                      ? accent
                                      : accent.withValues(alpha: .24),
                                  width: active ? 3.2 : 1.2,
                                ),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          color: accent.withValues(alpha: .20),
                                          blurRadius: 18,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: active
                                    ? const Icon(
                                        Icons.grid_view_rounded,
                                        color: accent,
                                        size: 34,
                                      )
                                    : Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: ReactColors.textSecondary
                                                .withValues(alpha: .28),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'CLEAR THE GRID',
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accent.withValues(alpha: .24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'PRESSURE',
                          style: TextStyle(
                            color: ReactColors.textSecondary,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: ((1150 - _spawnIntervalMs) / 930)
                                  .clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: accent.withValues(alpha: .08),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_running && !_finished) _CountdownOverlay(
              count: _countdown,
              go: _go,
            ),
            if (_finished) _ResultOverlay(
              score: _score,
              peakActive: _peakActive,
              newBest: _newBest,
              onRestart: _restart,
              onExit: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        minWidth: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ReactColors.coral.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ReactColors.coral.withValues(alpha: .25),
          ),
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
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: ReactColors.coral,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.count, required this.go});

  final int count;
  final bool go;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: ColoredBox(
          color: ReactColors.background.withValues(alpha: .96),
          child: Center(
            child: Text(
              go ? 'GO' : '$count',
              style: TextStyle(
                color: go ? ReactColors.coral : ReactColors.textPrimary,
                fontSize: go ? 86 : 112,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.score,
    required this.peakActive,
    required this.newBest,
    required this.onRestart,
    required this.onExit,
  });

  final int score;
  final int peakActive;
  final bool newBest;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: ColoredBox(
          color: ReactColors.background.withValues(alpha: .97),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.grid_view_rounded,
                    color: ReactColors.coral,
                    size: 64,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    newBest ? 'NEW BEST' : 'GRID FULL',
                    style: TextStyle(
                      color: newBest
                          ? ReactColors.lime
                          : ReactColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: ReactColors.coral,
                      fontSize: 76,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'PEAK PRESSURE  $peakActive/9',
                    style: const TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    height: 54,
                    child: FilledButton(
                      onPressed: onRestart,
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
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onExit,
                    child: const Text('BACK TO MOSAIC'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
''')

Path('test/home_friends_mosaic_regression_test.dart').write_text(r'''import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home utility controls stay on the top row', () {
    final source = File('lib/app/react_app.dart').readAsStringSync();
    expect(source, contains('right: 62'));
    expect(source, contains('left: 62'));
    expect(source, contains('MediaQuery.paddingOf(context).top + 10'));
  });

  test('Friends exposes a copyable own player code', () {
    final source = File(
      'lib/features/friends/presentation/friends_screen.dart',
    ).readAsStringSync();
    expect(source, contains('YOUR PLAYER CODE'));
    expect(source, contains('Clipboard.setData'));
    expect(source, contains('PlayerProfileRepository'));
  });

  test('Mosaic pressure uses active tiles instead of fill percentages', () {
    final source = File(
      'lib/features/modes/presentation/mosaic_pressure_run_screen.dart',
    ).readAsStringSync();
    expect(source, contains('List<bool>.filled(9, false)'));
    expect(source, contains('_activateRandomTile'));
    expect(source, contains('if (_activeCount >= 9)'));
    expect(source, contains('Icons.grid_view_rounded'));
    expect(source, isNot(contains('_fill[')));
    expect(source, isNot(contains("'${(fill * 100).round()}'")));
  });
}
''')
