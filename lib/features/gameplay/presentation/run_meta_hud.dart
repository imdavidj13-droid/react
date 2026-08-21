import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../daily/domain/daily_challenge.dart';
import '../../season/data/season_cosmetic_state.dart';
import '../../season/data/season_repository.dart';
import '../../season/presentation/season_cosmetic_layers.dart';
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
    final hudStyle = SeasonCosmeticState.equippedReward('hud_style');
    final hudAccent = hudStyle == null
        ? null
        : SeasonCosmeticLayers.accentForReward(hudStyle);

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
              styleAccent: hudAccent,
              styleKey: hudStyle?.rewardKey,
            ),
            const SizedBox(width: 7),
            _RunMetaPill(
              icon: Icons.bolt_rounded,
              label: 'CHARGE',
              value: charge == null ? '—' : '$charge',
              color: ReactColors.electricBlueBright,
              styleAccent: hudAccent,
              styleKey: hudStyle?.rewardKey,
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
    final best = mode == ReactGameMode.daily
        ? await LocalPlayerStats.dailyBestForModifier(DailyChallenge.today().modifier)
        : await LocalPlayerStats.bestFor(mode);
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
    this.styleAccent,
    this.styleKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? styleAccent;
  final String? styleKey;

  @override
  Widget build(BuildContext context) {
    final accent = styleAccent;
    final styled = accent != null;
    final angular = styleKey?.contains('rail') == true ||
        styleKey?.contains('terminal') == true;
    final compact = styleKey?.contains('minimal') == true;
    final effectiveColor = styled ? accent : color;

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 82 : 88),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: styled
            ? effectiveColor.withValues(alpha: .075)
            : const Color(0xFF050B14).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(angular ? 8 : 999),
        border: Border.all(
          color: effectiveColor.withValues(alpha: styled ? .62 : .32),
          width: styled ? 1.25 : 1,
        ),
        boxShadow: styled
            ? [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: .14),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveColor, size: compact ? 12 : 13),
          const SizedBox(width: 5),
          Text(
            '$label ',
            style: TextStyle(
              color: styled
                  ? effectiveColor.withValues(alpha: .78)
                  : ReactColors.textSecondary,
              fontSize: compact ? 6.5 : 7,
              fontWeight: FontWeight.w900,
              letterSpacing: angular ? 1 : .65,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: effectiveColor,
              fontSize: compact ? 8 : 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: angular ? .7 : .35,
            ),
          ),
        ],
      ),
    );
  }
}
