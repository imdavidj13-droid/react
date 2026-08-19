import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
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
  }

  void _reload() {
    _season = _repository.loadActiveSeason();
  }

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
        final season = snapshot.data;
        if (season == null) return const SizedBox.shrink();

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
