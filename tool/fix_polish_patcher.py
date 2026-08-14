from pathlib import Path

path = Path('tool/apply_polish_batch.py')
text = path.read_text()

old = "String _heroEyebrow(ReactRunResult result) => switch (result.mode) {\\n"
new = "String _heroEyebrow(ReactRunResult result) {\\n"
if old not in text:
    raise RuntimeError('Expected share helper signature was not found in patcher.')
text = text.replace(old, new, 1)

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
