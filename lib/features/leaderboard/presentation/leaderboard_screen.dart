import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../daily/domain/daily_challenge.dart';
import '../../gameplay/data/local_player_stats.dart';
import '../../gameplay/domain/react_run_history_entry.dart';
import '../../gameplay/domain/react_run_result.dart';
import '../data/leaderboard_repository.dart';
import '../data/local_leaderboard_repository.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/leaderboard_query.dart';
import '../domain/leaderboard_snapshot.dart';
import 'personal_records_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardRepository _repository = const LocalLeaderboardRepository();

  LeaderboardScope _scope = LeaderboardScope.global;
  ReactGameMode _mode = ReactGameMode.classic;
  late Future<_LeaderboardScreenData> _data;

  LeaderboardQuery get _query => LeaderboardQuery(
    scope: _scope,
    mode: _scope == LeaderboardScope.daily ? ReactGameMode.daily : _mode,
    dailyDate: _scope == LeaderboardScope.daily ? DateTime.now() : null,
  );

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_LeaderboardScreenData> _loadData() async {
    final query = _query;
    final snapshot = await _repository.load(query);
    final mode = query.mode;
    return _LeaderboardScreenData(
      snapshot: snapshot,
      best: query.scope == LeaderboardScope.daily
          ? await LocalPlayerStats.dailyBestToday()
          : await LocalPlayerStats.bestFor(mode),
      runs: await LocalPlayerStats.runsFor(mode),
      commands: await LocalPlayerStats.successfulCommandsFor(mode),
      averageReactionSeconds:
          await LocalPlayerStats.averageReactionSecondsFor(mode),
      recentRuns: (await LocalPlayerStats.recentRuns())
          .where((entry) => entry.mode == mode)
          .take(5)
          .toList(growable: false),
    );
  }

  void _reload() => setState(() => _data = _loadData());

  void _setScope(LeaderboardScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _data = _loadData();
    });
  }

  void _setMode(ReactGameMode mode) {
    if (_mode == mode || !LocalLeaderboardRepository.supportsMode(mode)) return;
    setState(() {
      _mode = mode;
      _data = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _data;
          },
          child: FutureBuilder<_LeaderboardScreenData>(
            future: _data,
            builder: (context, snapshot) {
              final data = snapshot.data;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                children: [
                  _Header(
                    onBack: () => Navigator.of(context).pop(),
                    onRecords: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PersonalRecordsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _LocalPreviewBanner(),
                  const SizedBox(height: 16),
                  _ScopeSelector(scope: _scope, onChanged: _setScope),
                  if (_scope == LeaderboardScope.global) ...[
                    const SizedBox(height: 12),
                    _ModeSelector(mode: _mode, onChanged: _setMode),
                  ] else ...[
                    const SizedBox(height: 12),
                    _DailyContext(challenge: DailyChallenge.today()),
                  ],
                  const SizedBox(height: 18),
                  const _SectionLabel('RANKINGS'),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      data == null)
                    const _LoadingCard()
                  else if (snapshot.hasError)
                    _ErrorCard(onRetry: _reload)
                  else
                    _RankingsCard(snapshot: data?.snapshot),
                  const SizedBox(height: 20),
                  const _SectionLabel('YOUR PERFORMANCE'),
                  const SizedBox(height: 10),
                  _PerformanceCard(
                    mode: _query.mode,
                    best: data?.best ?? 0,
                    runs: data?.runs ?? 0,
                    commands: data?.commands ?? 0,
                    averageReactionSeconds:
                        data?.averageReactionSeconds ?? 0,
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('RECENT RUNS'),
                  const SizedBox(height: 10),
                  if ((data?.recentRuns ?? const <ReactRunHistoryEntry>[]).isEmpty)
                    const _EmptyRuns()
                  else
                    for (final run in data!.recentRuns) ...[
                      _RecentRunCard(entry: run),
                      const SizedBox(height: 8),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LeaderboardScreenData {
  const _LeaderboardScreenData({
    required this.snapshot,
    required this.best,
    required this.runs,
    required this.commands,
    required this.averageReactionSeconds,
    required this.recentRuns,
  });

  final LeaderboardSnapshot snapshot;
  final int best;
  final int runs;
  final int commands;
  final double averageReactionSeconds;
  final List<ReactRunHistoryEntry> recentRuns;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onRecords});

  final VoidCallback onBack;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) => Row(
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
                'LEADERBOARD',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'COMPETITIVE SCORE FOUNDATION',
                style: TextStyle(
                  color: ReactColors.electricBlueBright,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
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

class _LocalPreviewBanner extends StatelessWidget {
  const _LocalPreviewBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: ReactColors.purple.withValues(alpha: .42),
      ),
    ),
    child: const Row(
      children: [
        Icon(Icons.cloud_off_rounded, color: ReactColors.purple, size: 23),
        SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOCAL PREVIEW',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'YOUR REAL SCORES ONLY • ONLINE RANKS WILL PLUG INTO THIS VIEW LATER',
                style: TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 7.2,
                  height: 1.45,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.scope, required this.onChanged});

  final LeaderboardScope scope;
  final ValueChanged<LeaderboardScope> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _SelectorButton(
          label: 'GLOBAL',
          selected: scope == LeaderboardScope.global,
          color: ReactColors.electricBlueBright,
          onTap: () => onChanged(LeaderboardScope.global),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _SelectorButton(
          label: 'DAILY',
          selected: scope == LeaderboardScope.daily,
          color: ReactColors.purple,
          onTap: () => onChanged(LeaderboardScope.daily),
        ),
      ),
    ],
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final ReactGameMode mode;
  final ValueChanged<ReactGameMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = [
      ReactGameMode.classic,
      ReactGameMode.blitz,
      ReactGameMode.endless,
    ];
    return Row(
      children: [
        for (var index = 0; index < modes.length; index++) ...[
          if (index > 0) const SizedBox(width: 7),
          Expanded(
            child: _SelectorButton(
              label: modes[index].label,
              selected: mode == modes[index],
              color: _modeColor(modes[index]),
              onTap: () => onChanged(modes[index]),
              compact: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: compact ? 40 : 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: .13)
            : const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? color : const Color(0xFF263A54),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : ReactColors.textSecondary,
            fontSize: compact ? 8.5 : 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
      ),
    ),
  );
}

class _DailyContext extends StatelessWidget {
  const _DailyContext({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ReactColors.purple.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        const Icon(Icons.calendar_today_rounded, color: ReactColors.purple, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '${challenge.modifier.label}  •  ${challenge.dateLabel}',
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .55,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RankingsCard extends StatelessWidget {
  const _RankingsCard({required this.snapshot});

  final LeaderboardSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot?.entries ?? const <LeaderboardEntry>[];
    if (entries.isEmpty) {
      return const _EmptyRanking();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF29405D)),
      ),
      child: Column(
        children: [
          const _RankingHeader(),
          const SizedBox(height: 8),
          for (final entry in entries) _RankingRow(entry: entry),
        ],
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  const _RankingHeader();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SizedBox(width: 38, child: Text('RANK', style: _tinyLabelStyle)),
      Expanded(child: Text('PLAYER', style: _tinyLabelStyle)),
      SizedBox(width: 70, child: Text('AVG', textAlign: TextAlign.center, style: _tinyLabelStyle)),
      SizedBox(width: 58, child: Text('SCORE', textAlign: TextAlign.end, style: _tinyLabelStyle)),
    ],
  );
}

const _tinyLabelStyle = TextStyle(
  color: ReactColors.textSecondary,
  fontSize: 6.8,
  fontWeight: FontWeight.w900,
  letterSpacing: .8,
);

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
    decoration: BoxDecoration(
      color: entry.isCurrentPlayer
          ? ReactColors.electricBlueBright.withValues(alpha: .08)
          : const Color(0xFF050C16),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: entry.isCurrentPlayer
            ? ReactColors.electricBlueBright.withValues(alpha: .45)
            : const Color(0xFF1F324A),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            entry.rank == null ? '—' : '#${entry.rank}',
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            entry.displayName,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            entry.averageReactionSeconds == null
                ? '--'
                : '${entry.averageReactionSeconds!.toStringAsFixed(2)}s',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 58,
          child: Text(
            '${entry.score}',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: ReactColors.lime,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.mode,
    required this.best,
    required this.runs,
    required this.commands,
    required this.averageReactionSeconds,
  });

  final ReactGameMode mode;
  final int best;
  final int runs;
  final int commands;
  final double averageReactionSeconds;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(mode);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_modeIcon(mode), color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mode.label,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$best',
                style: TextStyle(
                  color: color,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1D314A)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Metric(label: 'RUNS', value: '$runs')),
              const _MetricDivider(),
              Expanded(child: _Metric(label: 'COMMANDS', value: '$commands')),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  label: 'AVG',
                  value: averageReactionSeconds == 0
                      ? '--'
                      : '${averageReactionSeconds.toStringAsFixed(2)}s',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: ReactColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 3),
      Text(label, style: _tinyLabelStyle),
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    color: const Color(0xFF263A54),
  );
}

class _RecentRunCard extends StatelessWidget {
  const _RecentRunCard({required this.entry});

  final ReactRunHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(entry.mode);
    return InkWell(
      onTap: () => _showRunDetail(context, entry),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Row(
          children: [
            Icon(_modeIcon(entry.mode), color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${entry.successfulCommands} cleared  •  ${entry.misses} misses  •  ${entry.averageTimeSeconds == 0 ? '--' : '${entry.averageTimeSeconds.toStringAsFixed(2)}s avg'}',
                style: const TextStyle(
                  color: ReactColors.textSecondary,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${entry.score}',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: _tinyLabelStyle),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: Color(0xFF263851))),
    ],
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 108,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _MessageCard(
    icon: Icons.error_outline_rounded,
    title: 'COULD NOT LOAD SCORES',
    subtitle: 'YOUR LOCAL RECORDS ARE SAFE. TRY LOADING THIS VIEW AGAIN.',
    action: TextButton(onPressed: onRetry, child: const Text('RETRY')),
  );
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) => const _MessageCard(
    icon: Icons.leaderboard_rounded,
    title: 'NO SCORE YET',
    subtitle: 'PLAY THIS MODE TO CREATE YOUR LOCAL PREVIEW ROW.',
  );
}

class _EmptyRuns extends StatelessWidget {
  const _EmptyRuns();

  @override
  Widget build(BuildContext context) => const _MessageCard(
    icon: Icons.history_rounded,
    title: 'NO RECENT RUNS',
    subtitle: 'YOUR LAST FIVE RUNS FOR THIS MODE WILL APPEAR HERE.',
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF29405D)),
    ),
    child: Column(
      children: [
        Icon(icon, color: ReactColors.textSecondary, size: 28),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 7.5,
            height: 1.45,
            fontWeight: FontWeight.w800,
          ),
        ),
        ?action,
      ],
    ),
  );
}

void _showRunDetail(BuildContext context, ReactRunHistoryEntry entry) {
  final color = _modeColor(entry.mode);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF07111D),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF32445D),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${entry.mode.label} RUN',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailChip('SCORE', '${entry.score}', color),
                _DetailChip('CLEARS', '${entry.successfulCommands}', ReactColors.electricBlueBright),
                _DetailChip('MISSES', '${entry.misses}', ReactColors.coral),
                _DetailChip('STREAK', '${entry.maxStreak}', ReactColors.lime),
                if (entry.averageTimeSeconds > 0)
                  _DetailChip('AVG', '${entry.averageTimeSeconds.toStringAsFixed(2)}s', ReactColors.textPrimary),
                if (entry.strongestCommand != null)
                  _DetailChip('BEST', entry.strongestCommand!, ReactColors.lime),
                if (entry.weakestCommand != null)
                  _DetailChip('WEAK', entry.weakestCommand!, ReactColors.coral),
                if (entry.dailyModifierLabel != null)
                  _DetailChip('RULE', entry.dailyModifierLabel!, ReactColors.purple),
                if (entry.winnerPlayer != null)
                  _DetailChip('WINNER', 'PLAYER ${entry.winnerPlayer}', ReactColors.purple),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Text(
      '$label  $value',
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

Color _modeColor(ReactGameMode mode) => switch (mode) {
  ReactGameMode.classic => ReactColors.electricBlueBright,
  ReactGameMode.blitz => ReactColors.coral,
  ReactGameMode.endless => ReactColors.lime,
  ReactGameMode.daily => ReactColors.purple,
  ReactGameMode.passIt => const Color(0xFFFFB85A),
};

IconData _modeIcon(ReactGameMode mode) => switch (mode) {
  ReactGameMode.classic => Icons.bolt_rounded,
  ReactGameMode.blitz => Icons.timer_rounded,
  ReactGameMode.endless => Icons.all_inclusive_rounded,
  ReactGameMode.daily => Icons.calendar_today_rounded,
  ReactGameMode.passIt => Icons.groups_2_rounded,
};
