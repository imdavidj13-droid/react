from pathlib import Path

path = Path('lib/features/results/presentation/result_share_screen.dart')
text = path.read_text()
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
path.write_text(text[:start] + replacement + text[end:])
print('Daily share text updated to use snapshotted run metadata.')
