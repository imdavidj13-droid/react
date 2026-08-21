import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../season/data/season_repository.dart';
import '../data/local_player_stats.dart';
import '../domain/react_run_result.dart';

/// Compact run-time metadata shared by every gameplay mode.
///
/// The persisted PB and server-owned season CHARGE are loaded once when the
/// run surface appears. The displayed BEST then follows the live score if the
/// player overtakes the stored record during the current run.
class RunMetaHud extends StatefulWidget {
  const RunMetaHud({
    required this.mode,
    required this.currentScore,
    super.key,
  });

  final ReactGameMode mode;
  final int currentScore;

  @override
  State<RunMetaHud> createState() => _RunMetaHudState();
}

class _RunMetaHudState extends State<RunMetaHud> {
  late Future<_RunMetaData> _data;

  @override
  void initState() {
    super.initState();
    _data = _RunMetaData.load(widget.mode);
  }

  @override
  void didUpdateWidget(covariant RunMetaHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _data = _RunMetaData.load(widget.mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RunMetaData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final persistedBest = data?.best ?? 0;
        final liveBest = widget.currentScore > persistedBest
            ? widget.currentScore
            : persistedBest;
        final charge = data?.charge;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RunMetaPill(
              icon: Icons.emoji_events_outlined,
              label: 'BEST',
              value: '$liveBest',
              color: ReactColors.lime,
            ),
            const SizedBox(width: 7),
            _RunMetaPill(
              icon: Icons.bolt_rounded,
              label: 'CHARGE',
              value: charge == null ? '—' : '$charge',
              color: ReactColors.electricBlueBright,
            ),
          ],
        );
      },
    );
  }
}

class _RunMetaData {
  const _RunMetaData({required this.best, required this.charge});

  final int best;
  final int? charge;

  static Future<_RunMetaData> load(ReactGameMode mode) async {
    final best = await LocalPlayerStats.bestFor(mode);
    final season = await const SeasonRepository().loadActiveSeason();
    return _RunMetaData(best: best, charge: season?.charge);
  }
}

class _RunMetaPill extends StatelessWidget {
  const _RunMetaPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF050B14).withValues(alpha: .82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(
              '$label ',
              style: const TextStyle(
                color: ReactColors.textSecondary,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: .65,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .35,
              ),
            ),
          ],
        ),
      );
}
