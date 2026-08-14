from pathlib import Path

path = Path('tool/apply_polish_batch.py')
text = path.read_text()

old = "String _heroEyebrow(ReactRunResult result) => switch (result.mode) {\\n"
new = "String _heroEyebrow(ReactRunResult result) {\\n"
if text.count(old) < 2:
    raise RuntimeError('Expected both share helper signature occurrences were not found.')
text = text.replace(old, new)

for marker in (
    "class _ResultStat extends StatelessWidget {''',\n)",
    "class _PassItSummary extends StatelessWidget {''',\n)",
    "class _RecordsBanner extends StatelessWidget {''',\n)",
    "class _EmptyHistory extends StatelessWidget {''',\n)",
):
    if marker not in text:
        raise RuntimeError(f'Expected duplicated end marker was not found: {marker}')
    text = text.replace(marker, "''',\n)", 1)

path.write_text(text)
print('Polish patcher signatures and class boundaries corrected.')
