from pathlib import Path


def replace_between(path: Path, start_marker: str, end_marker: str, replacement: str) -> None:
    text = path.read_text()
    start = text.index(start_marker)
    end = text.index(end_marker, start)
    path.write_text(text[:start] + replacement + text[end:])


# Share card: real Daily runs use frozen metadata. Synthetic/legacy Daily
# results fall back to today's deterministic challenge so old callers/tests
# still render a complete card.
share_path = Path('lib/features/results/presentation/result_share_screen.dart')
share = share_path.read_text()
import_anchor = "import '../../../core/theme/react_colors.dart';\n"
if "../../daily/domain/daily_challenge.dart" not in share:
    share = share.replace(
        import_anchor,
        import_anchor + "import '../../daily/domain/daily_challenge.dart';\n",
        1,
    )
share_path.write_text(share)

replace_between(
    share_path,
    'class _DailySummary extends StatelessWidget {',
    'class _PassItSummary extends StatelessWidget {',
    '''class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.result, required this.color});

  final ReactRunResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fallback = result.dailyModifierLabel == null
        ? DailyChallenge.today()
        : null;
    final date = result.dailyDate;
    final dateLabel = date == null
        ? fallback?.dateLabel ?? 'DAILY CHALLENGE'
        : _dailyDateLabel(date);
    final modifierLabel =
        result.dailyModifierLabel ?? fallback?.modifier.label ?? 'DAILY';
    final rule = result.dailyModifierRule ??
        fallback?.modifier.shortRule ??
        '60 COMMAND TARGET';

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
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

''',
)

share = share_path.read_text()
old_daily_condition = "                    if (isDaily && result.dailyModifierLabel != null) ...[\n"
new_daily_condition = "                    if (isDaily) ...[\n"
if old_daily_condition not in share:
    raise RuntimeError('Expected generated Daily share condition was not found.')
share = share.replace(old_daily_condition, new_daily_condition, 1)
share_path.write_text(share)

share = share_path.read_text()
start = share.index('String _shareText(ReactRunResult result) {')
end = share.index('Color _modeColor(ReactGameMode mode)', start)
share_text = '''String _shareText(ReactRunResult result) {
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {
    return 'RE△CT PASS IT — Player ${result.winnerPlayer} wins with '
        '${result.successfulCommands} commands cleared.';
  }
  if (result.mode == ReactGameMode.daily) {
    final modifier = result.dailyModifierLabel ?? DailyChallenge.today().modifier.label;
    return 'RE△CT DAILY $modifier — ${result.score}/60. Can you beat it?';
  }
  return 'RE△CT ${result.mode.label} — ${result.score} points. Can you beat it?';
}

'''
share_path.write_text(share[:start] + share_text + share[end:])

# Results NEW BEST badge uses runtime Daily copy, so only the static children
# are const.
results_path = Path('lib/features/results/presentation/results_screen.dart')
results = results_path.read_text()
old = '''            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, color: ReactColors.lime, size: 17),
                SizedBox(width: 7),
                Text(
                  result.mode == ReactGameMode.daily ? 'NEW RULE BEST' : 'NEW BEST',
                  style: TextStyle(
'''
new = '''            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: ReactColors.lime, size: 17),
                const SizedBox(width: 7),
                Text(
                  result.mode == ReactGameMode.daily ? 'NEW RULE BEST' : 'NEW BEST',
                  style: const TextStyle(
'''
if old not in results:
    raise RuntimeError('Expected generated NEW BEST badge block was not found.')
results_path.write_text(results.replace(old, new, 1))

# Scores: keep both navigation buttons without squeezing the title beyond a
# 320px phone. The title owns the remaining width and scales down if needed.
leaderboard_path = Path('lib/features/leaderboard/presentation/leaderboard_screen.dart')
replace_between(
    leaderboard_path,
    'class _Header extends StatelessWidget {',
    'class _RecordsBanner extends StatelessWidget {',
    '''class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onRecords});
  final VoidCallback onBack;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.textPrimary,
            side: const BorderSide(color: Color(0xFF1E3552)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              children: [
                Text(
                  'SCORES',
                  style: TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'LOCAL DEVICE RECORDS',
                  style: TextStyle(
                    color: ReactColors.purple,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Personal records',
          onPressed: onRecords,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            foregroundColor: ReactColors.lime,
            side: const BorderSide(color: Color(0xFF1E3552)),
          ),
          icon: const Icon(Icons.workspace_premium_outlined, size: 19),
        ),
      ],
    );
  }
}

''',
)

# Give compact Personal Records cards enough vertical room for long labels.
records_path = Path('lib/features/leaderboard/presentation/personal_records_screen.dart')
records = records_path.read_text()
if 'childAspectRatio: 1.55,' not in records:
    raise RuntimeError('Expected Personal Records grid ratio was not found.')
records_path.write_text(records.replace('childAspectRatio: 1.55,', 'childAspectRatio: 1.10,', 1))

print('Daily fallback, Results badge, and compact record layouts updated.')
