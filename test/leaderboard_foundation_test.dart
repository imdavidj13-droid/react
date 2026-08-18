import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/gameplay/data/local_player_stats.dart';
import 'package:react/features/gameplay/domain/react_run_result.dart';
import 'package:react/features/leaderboard/data/local_leaderboard_repository.dart';
import 'package:react/features/leaderboard/domain/leaderboard_query.dart';
import 'package:react/features/leaderboard/domain/leaderboard_snapshot.dart';
import 'package:react/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:react/features/player/data/local_player_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> seedGuest({Map<String, Object> values = const {}}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'react_player_local_id': 'abcdef1234567890abcdef12',
      'react_player_display_name': 'PLAYER-ABCDEF',
      ...values,
    });
    await LocalPlayerProfile.load();
  }

  test('local repository exposes the persisted guest identity', () async {
    await seedGuest();
    await LocalPlayerStats.recordResult(
      const ReactRunResult(
        mode: ReactGameMode.classic,
        score: 42,
        successfulCommands: 42,
        averageTimeSeconds: .65,
        outcome: ReactRunOutcome.missedCommand,
        misses: 3,
      ),
    );

    final snapshot = await const LocalLeaderboardRepository().load(
      const LeaderboardQuery(
        scope: LeaderboardScope.global,
        mode: ReactGameMode.classic,
      ),
    );

    expect(snapshot.source, LeaderboardDataSource.localPreview);
    expect(snapshot.entries, hasLength(1));
    expect(snapshot.entries.single.playerId, 'abcdef1234567890abcdef12');
    expect(snapshot.entries.single.displayName, 'PLAYER-ABCDEF');
    expect(snapshot.entries.single.score, 42);
    expect(snapshot.entries.single.rank, isNull);
    expect(snapshot.entries.single.averageReactionSeconds, closeTo(.65, .001));
  });

  test('aggregate reaction data is never attached to an unrelated best score', () async {
    await seedGuest(values: <String, Object>{
      'best_classic': 42,
      'mode_commands_classic': 10,
      'mode_response_ms_classic': 6500,
    });

    final snapshot = await const LocalLeaderboardRepository().load(
      const LeaderboardQuery(
        scope: LeaderboardScope.global,
        mode: ReactGameMode.classic,
      ),
    );

    expect(snapshot.entries.single.score, 42);
    expect(snapshot.entries.single.averageReactionSeconds, isNull);
  });

  test('Pass It is excluded from competitive leaderboard modes', () {
    expect(LocalLeaderboardRepository.supportsMode(ReactGameMode.classic), isTrue);
    expect(LocalLeaderboardRepository.supportsMode(ReactGameMode.blitz), isTrue);
    expect(LocalLeaderboardRepository.supportsMode(ReactGameMode.endless), isTrue);
    expect(LocalLeaderboardRepository.supportsMode(ReactGameMode.daily), isTrue);
    expect(LocalLeaderboardRepository.supportsMode(ReactGameMode.passIt), isFalse);
  });

  testWidgets('leaderboard local preview fits a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await seedGuest(values: <String, Object>{
      'best_classic': 42,
      'mode_runs_classic': 3,
      'mode_commands_classic': 10,
      'mode_response_ms_classic': 6500,
    });

    await tester.pumpWidget(const MaterialApp(home: LeaderboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('LOCAL PREVIEW'), findsOneWidget);
    expect(find.text('GLOBAL'), findsOneWidget);
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('PLAYER-ABCDEF'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
