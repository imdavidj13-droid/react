import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../../blitz/presentation/blitz_screen.dart';
import '../../classic/presentation/classic_screen.dart';
import '../../daily/domain/daily_challenge.dart';
import '../../daily/presentation/daily_screen.dart';
import '../../dot_sequence/presentation/dot_sequence_screen.dart';
import '../../endless/presentation/endless_screen.dart';
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
    final mode = query.mode;
    final snapshot = await _repository.load(query);
    final recentRuns = (await LocalPlayerStats.recentRuns())
        .where((entry) => entry.mode == mode)
        .take(5)
        .toList(growable: false);

    return _LeaderboardScreenData(
      snapshot: snapshot,
      best: query.scope == LeaderboardScope.daily
          ? await LocalPlayerStats.dailyBestToday()
          : await LocalPlayerStats.bestFor(mode),
      runs: await LocalPlayerStats.runsFor(mode),
      commands: await LocalPlayerStats.successfulCommandsFor(mode),
      averageReactionSeconds:
          await LocalPlayerStats.averageReactionSecondsFor(mode),
      bestStreak: recentRuns.fold<int>(
        0,
        (best, run) => run.maxStreak > best ? run.maxStreak : best,
      ),
      recentRuns: recentRuns,
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

  Future<void> _playSelectedMode() async {
    final screen = switch (_query.mode) {
      ReactGameMode.classic => const ClassicScreen(),
      ReactGameMode.blitz => const BlitzScreen(),
      ReactGameMode.endless => const EndlessScreen(),
      ReactGameMode.sequence => const DotSequenceScreen(),
      ReactGameMode.daily => const DailyScreen(),
      ReactGameMode.passIt => const ClassicScreen(),
    };
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) _reload();
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
            builder: (context, asyncSnapshot) {
              final data = asyncSnapshot.data;
              final board = data?.snapshot;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
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
                  _CompetitionHero(
                    scope: _scope,
                    mode: _query.mode,
                    board: board,
                    best: data?.best ?? 0,
                  ),
                  const SizedBox(height: 14),
                  _ScopeSelector(scope: _scope, onChanged: _setScope),
                  if (_scope == LeaderboardScope.global) ...[
                    const SizedBox(height: 10),
                    _ModeSelector(mode: _mode, onChanged: _setMode),
                  ] else ...[
                    const SizedBox(height: 10),
                    _DailyContext(challenge: DailyChallenge.today()),
                  ],
                  const SizedBox(height: 16),
                  _StatusCard(
                    board: board,
                    mode: _query.mode,
                    best: data?.best ?? 0,
                    runs: data?.runs ?? 0,
                    onPlay: _playSelectedMode,
                  ),
                  const SizedBox(height: 22),
                  const _SectionLabel('COMPETITIVE RANKINGS'),
                  const SizedBox(height: 10),
                  if (asyncSnapshot.connectionState == ConnectionState.waiting &&
                      data == null)
                    const _LoadingCard()
                  else if (asyncSnapshot.hasError)
                    _ErrorCard(onRetry: _reload)
                  else ...[
                    if (_hasPodium(board)) ...[
                      _Podium(entries: board!.entries.take(3).toList()),
                      const SizedBox(height: 12),
                    ],
                    _RankingsCard(snapshot: board),
                    if (_aroundPlayer(board).isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const _SectionLabel('AROUND YOU'),
                      const SizedBox(height: 10),
                      _AroundYouCard(entries: _aroundPlayer(board)),
                    ],
                  ],
                  const SizedBox(height: 22),
                  const _SectionLabel('YOUR COMPETITIVE SNAPSHOT'),
                  const SizedBox(height: 10),
                  _CompetitiveSnapshot(
                    mode: _query.mode,
                    best: data?.best ?? 0,
                    rank: board?.currentPlayerRank,
                    runs: data?.runs ?? 0,
                    commands: data?.commands ?? 0,
                    averageReactionSeconds:
                        data?.averageReactionSeconds ?? 0,
                    bestStreak: data?.bestStreak ?? 0,
                  ),
                  const SizedBox(height: 22),
                  const _SectionLabel('RECENT ACTIVITY'),
                  const SizedBox(height: 10),
                  if ((data?.recentRuns ?? const <ReactRunHistoryEntry>[]).isEmpty)
                    const _EmptyRuns()
                  else
                    _RecentActivity(
                      runs: data!.recentRuns,
                      best: data.best,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _hasPodium(LeaderboardSnapshot? board) =>
      board != null && !board.isLocalPreview && board.entries.length >= 3;

  List<LeaderboardEntry> _aroundPlayer(LeaderboardSnapshot? board) {
    if (board == null || board.isLocalPreview || board.currentPlayerRank == null) {
      return const [];
    }
    final index = board.entries.indexWhere((entry) => entry.isCurrentPlayer);
    if (index < 0 || index < 3) return const [];
    final start = index > 0 ? index - 1 : index;
    final end = (index + 2).clamp(0, board.entries.length);
    return board.entries.sublist(start, end);
  }
}

class _LeaderboardScreenData {
  const _LeaderboardScreenData({
    required this.snapshot,
    required this.best,
    required this.runs,
    required this.commands,
    required this.averageReactionSeconds,
    required this.bestStreak,
    required this.recentRuns,
  });

  final LeaderboardSnapshot snapshot;
  final int best;
  final int runs;
  final int commands;
  final double averageReactionSeconds;
  final int bestStreak;
  final List<ReactRunHistoryEntry> recentRuns;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onRecords});

  final VoidCallback onBack;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _RoundIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: onBack,
      ),
      const SizedBox(width: 8),
      const Expanded(
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
            SizedBox(height: 4),
            Text(
              'LIVE COMPETITION • BEST SCORES • DAILY BATTLES',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ReactColors.electricBlueBright,
                fontSize: 6.8,
                fontWeight: FontWeight.w900,
                letterSpacing: .9,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _RoundIconButton(
        icon: Icons.workspace_premium_outlined,
        color: ReactColors.lime,
        onTap: onRecords,
      ),
    ],
  );
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.color = ReactColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFF07101E),
      foregroundColor: color,
      side: const BorderSide(color: Color(0xFF1E3552)),
    ),
    icon: Icon(icon, size: 19),
  );
}

class _CompetitionHero extends StatelessWidget {
  const _CompetitionHero({
    required this.scope,
    required this.mode,
    required this.board,
    required this.best,
  });

  final LeaderboardScope scope;
  final ReactGameMode mode;
  final LeaderboardSnapshot? board;
  final int best;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(mode);
    final rank = board?.currentPlayerRank;
    final local = board?.isLocalPreview ?? true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: .16),
            const Color(0xFF07111D),
            const Color(0xFF050A13),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .12),
              border: Border.all(color: color.withValues(alpha: .65)),
            ),
            child: Icon(_modeIcon(mode), color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${scope == LeaderboardScope.global ? 'GLOBAL' : 'DAILY'} • ${mode.label}',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  rank == null ? 'UNRANKED' : '#$rank',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  local
                      ? 'LOCAL SCORE PREVIEW • CLOUD RANK APPEARS WHEN AVAILABLE'
                      : 'LIVE COMPETITIVE POSITION',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .55,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('BEST', style: _tinyLabelStyle),
              const SizedBox(height: 3),
              Text(
                '$best',
                style: TextStyle(
                  color: color,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
      ReactGameMode.sequence,
    ];
    return Row(
      children: [
        for (var index = 0; index < modes.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
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
    borderRadius: BorderRadius.circular(15),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: compact ? 42 : 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: .14) : const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? color : const Color(0xFF263A54),
          width: selected ? 1.35 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .10),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : ReactColors.textSecondary,
            fontSize: compact ? 8.2 : 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .75,
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ReactColors.purple.withValues(alpha: .4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.calendar_today_rounded, color: ReactColors.purple, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '${challenge.modifier.label} • ${challenge.dateLabel}',
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.board,
    required this.mode,
    required this.best,
    required this.runs,
    required this.onPlay,
  });

  final LeaderboardSnapshot? board;
  final ReactGameMode mode;
  final int best;
  final int runs;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final rank = board?.currentPlayerRank;
    final color = _modeColor(mode);
    final ranked = rank != null;
    final remote = board != null && !board!.isLocalPreview;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                ranked ? Icons.emoji_events_rounded : Icons.radar_rounded,
                color: ranked ? ReactColors.lime : color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ranked ? 'CURRENT RANK' : 'NOT YET RANKED',
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ranked
                          ? 'Your best score is live on this board.'
                          : remote
                              ? 'Play ${mode.label} to post your first competitive score.'
                              : 'Your local best is ready while the live board connects.',
                      style: const TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 8,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (ranked)
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: ReactColors.lime,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'BEST LOCAL', value: '$best', color: color)),
              const SizedBox(width: 8),
              Expanded(child: _MiniStat(label: 'RUNS', value: '$runs')),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'BOARD',
                  value: remote ? 'LIVE' : 'LOCAL',
                  color: remote ? ReactColors.lime : ReactColors.purple,
                ),
              ),
            ],
          ),
          if (!ranked) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPlay,
                style: FilledButton.styleFrom(
                  backgroundColor: color.withValues(alpha: .18),
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: .75)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  'PLAY ${mode.label}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];
    return SizedBox(
      height: 176,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PodiumPlayer(entry: second, height: 132, medal: '2')),
          const SizedBox(width: 8),
          Expanded(child: _PodiumPlayer(entry: first, height: 164, medal: '1', winner: true)),
          const SizedBox(width: 8),
          Expanded(child: _PodiumPlayer(entry: third, height: 120, medal: '3')),
        ],
      ),
    );
  }
}

class _PodiumPlayer extends StatelessWidget {
  const _PodiumPlayer({
    required this.entry,
    required this.height,
    required this.medal,
    this.winner = false,
  });

  final LeaderboardEntry entry;
  final double height;
  final String medal;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final color = winner ? ReactColors.lime : ReactColors.electricBlueBright;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: winner ? .65 : .3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '#$medal',
            style: TextStyle(
              color: color,
              fontSize: winner ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          _Avatar(entry: entry, size: winner ? 46 : 38),
          const SizedBox(height: 7),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ReactColors.textPrimary,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.score}',
            style: TextStyle(
              color: color,
              fontSize: winner ? 20 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingsCard extends StatelessWidget {
  const _RankingsCard({required this.snapshot});

  final LeaderboardSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot?.entries ?? const <LeaderboardEntry>[];
    if (entries.isEmpty) return const _EmptyRanking();

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
          const SizedBox(height: 6),
          for (final entry in entries.take(20)) _RankingRow(entry: entry),
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
      SizedBox(width: 52, child: Text('AVG', textAlign: TextAlign.center, style: _tinyLabelStyle)),
      SizedBox(width: 48, child: Text('SCORE', textAlign: TextAlign.end, style: _tinyLabelStyle)),
    ],
  );
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(
      color: entry.isCurrentPlayer
          ? ReactColors.electricBlueBright.withValues(alpha: .09)
          : const Color(0xFF050C16),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: entry.isCurrentPlayer
            ? ReactColors.electricBlueBright.withValues(alpha: .52)
            : const Color(0xFF1F324A),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            entry.rank == null ? '—' : '#${entry.rank}',
            style: TextStyle(
              color: entry.isCurrentPlayer
                  ? ReactColors.electricBlueBright
                  : ReactColors.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _Avatar(entry: entry, size: 34),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (entry.isCurrentPlayer) ...[
                    const SizedBox(width: 5),
                    const Text(
                      'YOU',
                      style: TextStyle(
                        color: ReactColors.electricBlueBright,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
              if (entry.playerCode != null) ...[
                const SizedBox(height: 2),
                Text(
                  entry.playerCode!,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .45,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            entry.averageReactionSeconds == null
                ? '—'
                : '${entry.averageReactionSeconds!.toStringAsFixed(2)}s',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ReactColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${entry.score}',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: ReactColors.lime,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry, required this.size});

  final LeaderboardEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0B1730),
        border: Border.all(color: const Color(0xFF29405D)),
      ),
      child: Icon(
        Icons.person_rounded,
        color: ReactColors.electricBlueBright,
        size: size * .55,
      ),
    );
    final url = entry.avatarUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _AroundYouCard extends StatelessWidget {
  const _AroundYouCard({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ReactColors.purple.withValues(alpha: .4)),
    ),
    child: Column(
      children: [for (final entry in entries) _RankingRow(entry: entry)],
    ),
  );
}

class _CompetitiveSnapshot extends StatelessWidget {
  const _CompetitiveSnapshot({
    required this.mode,
    required this.best,
    required this.rank,
    required this.runs,
    required this.commands,
    required this.averageReactionSeconds,
    required this.bestStreak,
  });

  final ReactGameMode mode;
  final int best;
  final int? rank;
  final int runs;
  final int commands;
  final double averageReactionSeconds;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(mode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .12),
                ),
                child: Icon(_modeIcon(mode), color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'YOUR BEST COMPETITIVE NUMBERS',
                      style: TextStyle(
                        color: ReactColors.textSecondary,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .55,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('BEST SCORE', style: _tinyLabelStyle),
                  Text(
                    '$best',
                    style: TextStyle(
                      color: color,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF1E3149), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'RANK', value: rank == null ? '—' : '#$rank', color: ReactColors.lime)),
              const _MetricDivider(),
              Expanded(child: _MiniStat(label: 'RUNS', value: '$runs')),
              const _MetricDivider(),
              Expanded(child: _MiniStat(label: 'COMMANDS', value: '$commands')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'AVG REACTION',
                  value: averageReactionSeconds <= 0
                      ? '—'
                      : '${averageReactionSeconds.toStringAsFixed(2)}s',
                  color: ReactColors.coral,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MiniStat(
                  label: 'BEST STREAK',
                  value: '$bestStreak',
                  color: ReactColors.purple,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _MiniStat(
                  label: 'STATUS',
                  value: rank == null ? 'UNRANKED' : 'LIVE',
                  color: rank == null ? ReactColors.textSecondary : ReactColors.lime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.color = ReactColors.textPrimary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: _tinyLabelStyle),
      ),
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: const Color(0xFF1E3149),
  );
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.runs, required this.best});

  final List<ReactRunHistoryEntry> runs;
  final int best;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF29405D)),
    ),
    child: Column(
      children: [
        for (var index = 0; index < runs.length; index++) ...[
          _RecentRunRow(entry: runs[index], isBest: runs[index].score == best),
          if (index != runs.length - 1)
            const Divider(color: Color(0xFF1E3149), height: 1),
        ],
      ],
    ),
  );
}

class _RecentRunRow extends StatelessWidget {
  const _RecentRunRow({required this.entry, required this.isBest});

  final ReactRunHistoryEntry entry;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(entry.mode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .1),
            ),
            child: Icon(_modeIcon(entry.mode), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SCORE ${entry.score}',
                      style: const TextStyle(
                        color: ReactColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ReactColors.lime.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ReactColors.lime.withValues(alpha: .45)),
                        ),
                        child: const Text(
                          'PB',
                          style: TextStyle(
                            color: ReactColors.lime,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(entry.playedAt)} • ${entry.successfulCommands} CLEARED • ${entry.misses} MISSES',
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 6.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.averageTimeSeconds <= 0
                ? '—'
                : '${entry.averageTimeSeconds.toStringAsFixed(2)}s',
            style: const TextStyle(
              color: ReactColors.coral,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) => _EmptyCard(
    icon: Icons.leaderboard_rounded,
    title: 'NO LIVE SCORES YET',
    subtitle: 'PLAY THIS MODE TO SET THE PACE AND CREATE A COMPETITIVE SCORE.',
  );
}

class _EmptyRuns extends StatelessWidget {
  const _EmptyRuns();

  @override
  Widget build(BuildContext context) => const _EmptyCard(
    icon: Icons.history_rounded,
    title: 'NO RECENT ACTIVITY',
    subtitle: 'YOUR LATEST RUNS, PERSONAL BESTS AND REACTION TIMES WILL APPEAR HERE.',
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF29405D)),
    ),
    child: Column(
      children: [
        Icon(icon, color: ReactColors.textSecondary, size: 30),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ReactColors.textSecondary,
            fontSize: 6.8,
            height: 1.4,
            fontWeight: FontWeight.w700,
            letterSpacing: .35,
          ),
        ),
      ],
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 120,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF07111D),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ReactColors.coral.withValues(alpha: .45)),
    ),
    child: Column(
      children: [
        const Icon(Icons.sync_problem_rounded, color: ReactColors.coral),
        const SizedBox(height: 8),
        const Text(
          'RANKINGS UNAVAILABLE',
          style: TextStyle(
            color: ReactColors.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(child: Divider(color: Color(0xFF243750), height: 1)),
    ],
  );
}

const _tinyLabelStyle = TextStyle(
  color: ReactColors.textSecondary,
  fontSize: 6.5,
  fontWeight: FontWeight.w900,
  letterSpacing: .75,
);

Color _modeColor(ReactGameMode mode) => switch (mode) {
  ReactGameMode.classic => ReactColors.electricBlueBright,
  ReactGameMode.blitz => ReactColors.coral,
  ReactGameMode.endless => ReactColors.lime,
  ReactGameMode.sequence => const Color(0xFF3DDCFF),
  ReactGameMode.daily => ReactColors.purple,
  ReactGameMode.passIt => ReactColors.textPrimary,
};

IconData _modeIcon(ReactGameMode mode) => switch (mode) {
  ReactGameMode.classic => Icons.bolt_rounded,
  ReactGameMode.blitz => Icons.timer_rounded,
  ReactGameMode.endless => Icons.all_inclusive_rounded,
  ReactGameMode.sequence => Icons.hub_rounded,
  ReactGameMode.daily => Icons.calendar_month_rounded,
  ReactGameMode.passIt => Icons.swap_horiz_rounded,
};

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month';
}
