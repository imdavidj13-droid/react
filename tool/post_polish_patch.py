from pathlib import Path

share_path = Path('lib/features/results/presentation/result_share_screen.dart')
text = share_path.read_text()
start = text.index('String _shareText(ReactRunResult result) {')
end = text.index('Color _modeColor(ReactGameMode mode)', start)
replacement = '''String _shareText(ReactRunResult result) {
  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {
    return 'RE△CT PASS IT — Player ${result.winnerPlayer} wins with '
        '${result.successfulCommands} commands cleared.';
  }
  if (result.mode == ReactGameMode.daily) {
    return 'RE△CT DAILY ${result.dailyModifierLabel ?? 'CHALLENGE'} — '
        '${result.score}/60. Can you beat it?';
  }
  return 'RE△CT ${result.mode.label} — ${result.score} points. Can you beat it?';
}

'''
share_path.write_text(text[:start] + replacement + text[end:])

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

print('Daily share metadata and Results badge const handling updated.')
