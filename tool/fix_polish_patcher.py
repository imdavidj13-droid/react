from pathlib import Path

path = Path('tool/apply_polish_batch.py')
text = path.read_text()

old = '''replace_once(\n    path,\n    "String _heroEyebrow(ReactRunResult result) => switch (result.mode) {\\n",\n    "String _scoreLabel(ReactGameMode mode) => switch (mode) {\\n      ReactGameMode.classic => 'FINAL SCORE',\\n      ReactGameMode.blitz => '60 SECOND SCORE',\\n      ReactGameMode.endless => 'COMMANDS SURVIVED',\\n      ReactGameMode.daily => 'DAILY SCORE',\\n      ReactGameMode.passIt => 'MATCH COMMANDS',\\n    };\\n\\nString _heroEyebrow(ReactRunResult result) => switch (result.mode) {\\n",\n)\n'''
new = '''replace_once(\n    path,\n    "String _heroEyebrow(ReactRunResult result) {\\n",\n    "String _scoreLabel(ReactGameMode mode) => switch (mode) {\\n      ReactGameMode.classic => 'FINAL SCORE',\\n      ReactGameMode.blitz => '60 SECOND SCORE',\\n      ReactGameMode.endless => 'COMMANDS SURVIVED',\\n      ReactGameMode.daily => 'DAILY SCORE',\\n      ReactGameMode.passIt => 'MATCH COMMANDS',\\n    };\\n\\nString _heroEyebrow(ReactRunResult result) {\\n",\n)\nreplace_between(\n    path,\n    'String _shareText(ReactRunResult result) {',\n    'Color _modeColor(ReactGameMode mode)',\n    '''String _shareText(ReactRunResult result) {\n  if (result.mode == ReactGameMode.passIt && result.winnerPlayer != null) {\n    return 'RE△CT PASS IT — Player ${result.winnerPlayer} wins with '\n        '${result.successfulCommands} commands cleared.';\n  }\n  if (result.mode == ReactGameMode.daily) {\n    return 'RE△CT DAILY ${result.dailyModifierLabel ?? 'CHALLENGE'} — '\n        '${result.score}/60. Can you beat it?';\n  }\n  return 'RE△CT ${result.mode.label} — ${result.score} points. Can you beat it?';\n}\n\nColor _modeColor(ReactGameMode mode)''',\n)\n'''

if old not in text:
    raise RuntimeError('Expected broken share helper patch was not found.')
path.write_text(text.replace(old, new, 1))
print('Polish patcher corrected.')
