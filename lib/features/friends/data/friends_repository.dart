import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/react_supabase.dart';
import '../../player/data/local_player_profile.dart';

enum FriendRelationshipState {
  none,
  self,
  incoming,
  outgoing,
  friend,
}

class FriendPlayer {
  const FriendPlayer({
    required this.playerId,
    required this.playerCode,
    required this.displayName,
    required this.relationshipState,
    this.relationshipId,
    this.avatarPath,
    this.avatarUrl,
    this.createdAt,
  });

  final String playerId;
  final String playerCode;
  final String displayName;
  final FriendRelationshipState relationshipState;
  final String? relationshipId;
  final String? avatarPath;
  final String? avatarUrl;
  final DateTime? createdAt;

  bool get isFriend => relationshipState == FriendRelationshipState.friend;
  bool get isIncoming => relationshipState == FriendRelationshipState.incoming;
  bool get isOutgoing => relationshipState == FriendRelationshipState.outgoing;
}

class FriendsSnapshot {
  const FriendsSnapshot({
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });

  final List<FriendPlayer> friends;
  final List<FriendPlayer> incoming;
  final List<FriendPlayer> outgoing;

  int get friendCount => friends.length;
  int get pendingCount => incoming.length;
}

class FriendsException implements Exception {
  const FriendsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FriendsRepository {
  const FriendsRepository();

  static const _avatarBucket = 'player-avatars';

  Future<FriendsSnapshot> load() async {
    final client = await _requireClient();
    final rows = await client.rpc('get_react_friend_connections');
    final connections = _rows(rows)
        .map((row) => _connectionFromRow(client, row))
        .toList(growable: false);

    return FriendsSnapshot(
      friends: connections
          .where((item) => item.relationshipState == FriendRelationshipState.friend)
          .toList(growable: false),
      incoming: connections
          .where((item) => item.relationshipState == FriendRelationshipState.incoming)
          .toList(growable: false),
      outgoing: connections
          .where((item) => item.relationshipState == FriendRelationshipState.outgoing)
          .toList(growable: false),
    );
  }

  Future<FriendPlayer?> findByCode(String rawCode) async {
    final client = await _requireClient();
    final code = normalizePlayerCode(rawCode);
    if (code == null) {
      throw const FriendsException('Enter a valid player code.');
    }

    final result = await client.rpc(
      'find_react_player_by_code',
      params: <String, dynamic>{'p_player_code': code},
    );
    final rows = _rows(result);
    if (rows.isEmpty) return null;
    return _searchResultFromRow(client, rows.first);
  }

  Future<void> sendRequest(String playerCode) async {
    final client = await _requireClient();
    final code = normalizePlayerCode(playerCode);
    if (code == null) {
      throw const FriendsException('Enter a valid player code.');
    }

    await _rpc(
      client,
      'send_react_friend_request',
      <String, dynamic>{'p_player_code': code},
    );
  }

  Future<void> accept(String relationshipId) async {
    final client = await _requireClient();
    await _rpc(
      client,
      'accept_react_friend_request',
      <String, dynamic>{'p_relationship_id': relationshipId},
    );
  }

  Future<void> decline(String relationshipId) async {
    final client = await _requireClient();
    await _rpc(
      client,
      'decline_react_friend_request',
      <String, dynamic>{'p_relationship_id': relationshipId},
    );
  }

  Future<void> cancel(String relationshipId) async {
    final client = await _requireClient();
    await _rpc(
      client,
      'cancel_react_friend_request',
      <String, dynamic>{'p_relationship_id': relationshipId},
    );
  }

  Future<void> remove(String relationshipId) async {
    final client = await _requireClient();
    await _rpc(
      client,
      'remove_react_friend',
      <String, dynamic>{'p_relationship_id': relationshipId},
    );
  }

  static String? normalizePlayerCode(String raw) {
    var value = raw.trim().toUpperCase().replaceAll(' ', '');
    if (value.isEmpty) return null;
    if (!value.startsWith('RX-') && RegExp(r'^[A-F0-9]{10}$').hasMatch(value)) {
      value = 'RX-$value';
    }
    if (!RegExp(r'^RX-[A-F0-9]{10}$').hasMatch(value)) return null;
    return value;
  }

  Future<SupabaseClient> _requireClient() async {
    final client = ReactSupabase.client;
    if (client == null) {
      throw const FriendsException('Friends need an online player session.');
    }
    if (client.auth.currentSession == null) {
      final ready = await ReactSupabase.ensurePlayerSession(
        displayName: LocalPlayerProfile.displayName,
      );
      if (!ready) {
        throw const FriendsException('Could not connect your player profile.');
      }
    }
    if (client.auth.currentUser == null) {
      throw const FriendsException('Friends need an online player session.');
    }
    return client;
  }

  Future<void> _rpc(
    SupabaseClient client,
    String function,
    Map<String, dynamic> params,
  ) async {
    try {
      await client.rpc(function, params: params);
    } on PostgrestException catch (error) {
      throw FriendsException(_friendlyMessage(error.message));
    }
  }

  FriendPlayer _connectionFromRow(
    SupabaseClient client,
    Map<String, dynamic> row,
  ) {
    return FriendPlayer(
      playerId: '${row['player_id']}',
      playerCode: '${row['player_code']}',
      displayName: _displayName(row['display_name']),
      relationshipState: _state('${row['relationship_direction']}'),
      relationshipId: _clean(row['relationship_id']),
      avatarPath: _clean(row['avatar_path']),
      avatarUrl: _avatarUrl(client, _clean(row['avatar_path'])),
      createdAt: DateTime.tryParse('${row['created_at']}'),
    );
  }

  FriendPlayer _searchResultFromRow(
    SupabaseClient client,
    Map<String, dynamic> row,
  ) {
    final avatarPath = _clean(row['avatar_path']);
    return FriendPlayer(
      playerId: '${row['player_id']}',
      playerCode: '${row['player_code']}',
      displayName: _displayName(row['display_name']),
      relationshipState: _state('${row['relationship_direction']}'),
      relationshipId: _clean(row['relationship_id']),
      avatarPath: avatarPath,
      avatarUrl: _avatarUrl(client, avatarPath),
    );
  }

  static List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
  }

  static FriendRelationshipState _state(String raw) => switch (raw) {
        'self' => FriendRelationshipState.self,
        'incoming' => FriendRelationshipState.incoming,
        'outgoing' => FriendRelationshipState.outgoing,
        'friend' => FriendRelationshipState.friend,
        _ => FriendRelationshipState.none,
      };

  static String _displayName(dynamic value) {
    final cleaned = '$value'.trim();
    return cleaned.isEmpty || cleaned == 'null' ? 'PLAYER' : cleaned;
  }

  static String? _clean(dynamic value) {
    final cleaned = value?.toString().trim();
    return cleaned == null || cleaned.isEmpty || cleaned == 'null' ? null : cleaned;
  }

  static String? _avatarUrl(SupabaseClient client, String? path) =>
      path == null ? null : client.storage.from(_avatarBucket).getPublicUrl(path);

  static String _friendlyMessage(String raw) {
    if (raw.contains('player_not_found')) return 'Player not found.';
    if (raw.contains('cannot_friend_self')) return 'That is your own player code.';
    if (raw.contains('already_friends')) return 'You are already friends.';
    if (raw.contains('friend_request_already_sent')) return 'Friend request already sent.';
    if (raw.contains('friend_request_already_received')) {
      return 'This player has already sent you a request.';
    }
    if (raw.contains('friend_request_not_found')) return 'That friend request is no longer available.';
    if (raw.contains('friendship_not_found')) return 'That friendship is no longer available.';
    if (raw.contains('authentication_required')) return 'Friends need an online player session.';
    return 'Could not update friends right now.';
  }
}
