import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/season_progress_service.dart';
import '../data/season_repository.dart';
import '../domain/season_models.dart';
import 'season_locker_screen.dart';
import 'season_screen.dart';

class HomeSeasonStrip extends StatefulWidget {
  const HomeSeasonStrip({super.key});

  @override
  State<HomeSeasonStrip> createState() => _HomeSeasonStripState();
}

class _HomeSeasonStripState extends State<HomeSeasonStrip> {
  static const _repository = SeasonRepository();
  late Future<SeasonSnapshot?> _season;

  @override
  void initState() {
    super.initState();
    _reload();
    SeasonProgressService.progressRevision.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    SeasonProgressService.progressRevision.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _reload() {
    _season = _repository.loadActiveSeason();
  }

  void _onProgressChanged() {
    if (!mounted) return;
    setState(_reload);
  }

  void _retry() => setState(_reload);

  Future<void> _openSeason() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SeasonScreen()),
    );
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _openLocker() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SeasonLockerScreen()),
    );
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SeasonSnapshot?>(
      future: _season,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SeasonStripShell(
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'LOADING SEASON PASS…',
                    style: TextStyle(
                      color: ReactColors.textSecondary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final season = snapshot.data;
        if (season == null) {
          return _SeasonStripShell(
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 19,
                  color: ReactColors.coral,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEASON PASS UNAVAILABLE',
                        style: TextStyle(
                          color: ReactColors.textPrimary,
                          fontSize: 8.8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .65,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Could not load the active season.',
                        style: TextStyle(
                          color: ReactColors.textSecondary,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _retry,
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final days = (season.remaining.inHours / 24).ceil();
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 8),
          child: Material(
            color: const Color(0xFF07111D),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openSeason,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 49,
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ReactColors.electricBlueBright.withValues(alpha: .28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ReactColors.electricBlueBright.withValues(alpha: .09),
                        border: Border.all(
                          color: ReactColors.electricBlueBright.withValues(alpha: .35),
                        ),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: ReactColors.electricBlueBright,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  season.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ReactColors.textPrimary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .65,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'T${season.currentTier.clamp(1, 30)}  •  $days D',
                                style: const TextStyle(
                                  color: ReactColors.textSecondary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: season.tierProgress,
                                    minHeight: 5,
                                    backgroundColor: ReactColors.electricBlueBright
                                        .withValues(alpha: .11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${season.charge} CHARGE',
                                style: const TextStyle(
                                  color: ReactColors.electricBlueBright,
                                  fontSize: 7.8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Season locker',
                      onPressed: _openLocker,
                      visualDensity: VisualDensity.compact,
                      color: ReactColors.purple,
                      icon: const Icon(Icons.checkroom_rounded, size: 18),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ReactColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeasonStripShell extends StatelessWidget {
  const _SeasonStripShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 8),
      child: Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: child,
      ),
    );
  }
}
