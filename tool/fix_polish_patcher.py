from pathlib import Path

path = Path('tool/apply_polish_batch.py')
text = path.read_text()
old = "String _heroEyebrow(ReactRunResult result) => switch (result.mode) {\\n"
new = "String _heroEyebrow(ReactRunResult result) {\\n"
if old not in text:
    raise RuntimeError('Expected share helper signature was not found in patcher.')
path.write_text(text.replace(old, new))
print('Polish patcher signature corrected.')
