import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react/features/friends/data/friends_repository.dart';
import 'package:react/features/friends/presentation/friends_screen.dart';

void main() {
  test('player code normalization accepts canonical and compact codes', () {
    expect(
      FriendsRepository.normalizePlayerCode('rx-a1b2c3d4e5'),
      'RX-A1B2C3D4E5',
    );
    expect(
      FriendsRepository.normalizePlayerCode('a1b2c3d4e5'),
      'RX-A1B2C3D4E5',
    );
    expect(FriendsRepository.normalizePlayerCode('not-a-code'), isNull);
    expect(FriendsRepository.normalizePlayerCode(''), isNull);
  });

  test('friends snapshot exposes friend and pending counts', () {
    const friend = FriendPlayer(
      playerId: 'friend',
      playerCode: 'RX-A1B2C3D4E5',
      displayName: 'FRIEND ONE',
      relationshipState: FriendRelationshipState.friend,
    );
    const incoming = FriendPlayer(
      playerId: 'incoming',
      playerCode: 'RX-B1B2C3D4E5',
      displayName: 'INCOMING',
      relationshipState: FriendRelationshipState.incoming,
    );
    const snapshot = FriendsSnapshot(
      friends: [friend],
      incoming: [incoming],
      outgoing: [],
    );

    expect(snapshot.friendCount, 1);
    expect(snapshot.pendingCount, 1);
  });

  testWidgets('Friends screen stays usable on a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FriendsScreen(repository: _FakeFriendsRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('FIND A PLAYER'), findsOneWidget);
    expect(find.text('REQUESTS (1)'), findsOneWidget);
    expect(find.text('FRIENDS (1)'), findsOneWidget);
    expect(find.text('FRIEND ONE'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('SENT REQUESTS'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('SENT REQUESTS'), findsOneWidget);
  });
}

class _FakeFriendsRepository extends FriendsRepository {
  @override
  Future<FriendsSnapshot> load() async {
    return const FriendsSnapshot(
      friends: [
        FriendPlayer(
          playerId: 'friend',
          playerCode: 'RX-A1B2C3D4E5',
          displayName: 'FRIEND ONE',
          relationshipState: FriendRelationshipState.friend,
          relationshipId: 'relationship-friend',
        ),
      ],
      incoming: [
        FriendPlayer(
          playerId: 'incoming',
          playerCode: 'RX-B1B2C3D4E5',
          displayName: 'REQUEST ONE',
          relationshipState: FriendRelationshipState.incoming,
          relationshipId: 'relationship-incoming',
        ),
      ],
      outgoing: [
        FriendPlayer(
          playerId: 'outgoing',
          playerCode: 'RX-C1B2C3D4E5',
          displayName: 'PENDING ONE',
          relationshipState: FriendRelationshipState.outgoing,
          relationshipId: 'relationship-outgoing',
        ),
      ],
    );
  }
}
