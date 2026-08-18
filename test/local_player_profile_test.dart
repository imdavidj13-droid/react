import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/player/data/local_player_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fresh install creates one stable guest identity and default name', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await LocalPlayerProfile.load();
    final firstId = LocalPlayerProfile.localId;
    final firstName = LocalPlayerProfile.displayName;

    expect(firstId, hasLength(24));
    expect(firstName, startsWith('PLAYER-'));
    expect(firstName, hasLength(13));

    await LocalPlayerProfile.load();
    expect(LocalPlayerProfile.localId, firstId);
    expect(LocalPlayerProfile.displayName, firstName);
  });

  test('display name changes persist without replacing guest id', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'react_player_local_id': 'abcdef1234567890abcdef12',
      'react_player_display_name': 'PLAYER-ABCDEF',
    });

    await LocalPlayerProfile.load();
    await LocalPlayerProfile.setDisplayName('  Fast   Hands  ');
    final id = LocalPlayerProfile.localId;

    await LocalPlayerProfile.load();
    expect(LocalPlayerProfile.localId, id);
    expect(LocalPlayerProfile.displayName, 'Fast Hands');
  });

  test('display name validation protects leaderboard-safe names', () {
    expect(LocalPlayerProfile.validateDisplayName('AB'), isNotNull);
    expect(
      LocalPlayerProfile.validateDisplayName('AAAAAAAAAAAAAAAAAAAAA'),
      isNotNull,
    );
    expect(LocalPlayerProfile.validateDisplayName('Bad!Name'), isNotNull);
    expect(LocalPlayerProfile.validateDisplayName('Good_Name-7'), isNull);
  });
}
