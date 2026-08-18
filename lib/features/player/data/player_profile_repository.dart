import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/react_supabase.dart';
import 'local_player_profile.dart';

class PlayerProfileData {
  const PlayerProfileData({
    required this.playerId,
    required this.playerCode,
    required this.displayName,
    required this.createdAt,
    required this.isAnonymous,
    required this.isCloudBacked,
    this.avatarPath,
    this.avatarUrl,
  });

  final String playerId;
  final String playerCode;
  final String displayName;
  final DateTime createdAt;
  final bool isAnonymous;
  final bool isCloudBacked;
  final String? avatarPath;
  final String? avatarUrl;

  PlayerProfileData copyWith({
    String? displayName,
    String? avatarPath,
    String? avatarUrl,
  }) {
    return PlayerProfileData(
      playerId: playerId,
      playerCode: playerCode,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      isAnonymous: isAnonymous,
      isCloudBacked: isCloudBacked,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class PlayerProfileRepository {
  const PlayerProfileRepository();

  static const _avatarBucket = 'player-avatars';

  Future<PlayerProfileData> load() async {
    final client = ReactSupabase.client;
    if (client == null) return _localFallback();

    if (client.auth.currentSession == null) {
      await ReactSupabase.ensurePlayerSession(
        displayName: LocalPlayerProfile.displayName,
      );
    }

    final user = client.auth.currentUser;
    if (user == null) return _localFallback();

    try {
      final row = await client
          .from('player_profiles')
          .select('id, player_code, display_name, avatar_path, created_at')
          .eq('id', user.id)
          .single();

      final displayName = (row['display_name'] as String?)?.trim();
      final playerCode = (row['player_code'] as String?)?.trim();
      final avatarPath = _clean(row['avatar_path'] as String?);
      final createdAt = DateTime.tryParse('${row['created_at']}') ??
          DateTime.tryParse(user.createdAt) ??
          LocalPlayerProfile.createdAt;
      final resolvedName = displayName == null || displayName.isEmpty
          ? LocalPlayerProfile.displayName
          : displayName;
      final resolvedCode = playerCode == null || playerCode.isEmpty
          ? LocalPlayerProfile.playerCodeFor(user.id)
          : playerCode;
      final avatarUrl = avatarPath == null
          ? LocalPlayerProfile.avatarUrl
          : client.storage.from(_avatarBucket).getPublicUrl(avatarPath);

      if (resolvedName != LocalPlayerProfile.displayName) {
        await LocalPlayerProfile.setDisplayName(resolvedName);
      }
      if (avatarPath != null && avatarUrl != null) {
        await LocalPlayerProfile.setAvatar(path: avatarPath, url: avatarUrl);
      } else if (avatarPath == null && LocalPlayerProfile.avatarPath != null) {
        await LocalPlayerProfile.clearAvatar();
      }

      return PlayerProfileData(
        playerId: user.id,
        playerCode: resolvedCode,
        displayName: resolvedName,
        avatarPath: avatarPath,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
        isAnonymous: user.isAnonymous,
        isCloudBacked: true,
      );
    } catch (_) {
      return _localFallback(
        playerId: user.id,
        isAnonymous: user.isAnonymous,
      );
    }
  }

  Future<PlayerProfileData> updateDisplayName(
    PlayerProfileData current,
    String value,
  ) async {
    final normalized = LocalPlayerProfile.normalizeDisplayName(value);
    final validationError = LocalPlayerProfile.validateDisplayName(normalized);
    if (validationError != null) throw ArgumentError(validationError);

    if (ReactSupabase.hasPlayerSession) {
      await ReactSupabase.syncDisplayName(normalized);
    }
    await LocalPlayerProfile.setDisplayName(normalized);
    return current.copyWith(displayName: normalized);
  }

  Future<PlayerProfileData> uploadAvatar({
    required PlayerProfileData current,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final client = ReactSupabase.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('A network player session is required to upload a photo.');
    }
    if (bytes.isEmpty) throw ArgumentError('The selected image is empty.');
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw ArgumentError('Profile photos must be 5 MB or smaller.');
    }

    final safeExtension = _safeExtension(extension);
    final path =
        '${user.id}/avatar-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await client.storage.from(_avatarBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );

    try {
      await client
          .from('player_profiles')
          .update(<String, dynamic>{
            'avatar_path': path,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (error) {
      await client.storage.from(_avatarBucket).remove(<String>[path]);
      rethrow;
    }

    final url = client.storage.from(_avatarBucket).getPublicUrl(path);
    final oldPath = current.avatarPath;
    await LocalPlayerProfile.setAvatar(path: path, url: url);

    if (oldPath != null &&
        oldPath != path &&
        oldPath.startsWith('${user.id}/')) {
      try {
        await client.storage.from(_avatarBucket).remove(<String>[oldPath]);
      } catch (_) {
        // The new avatar is already committed. Cleanup failure is non-fatal.
      }
    }

    return current.copyWith(avatarPath: path, avatarUrl: url);
  }

  Future<PlayerProfileData> removeAvatar(PlayerProfileData current) async {
    final client = ReactSupabase.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null) {
      await client
          .from('player_profiles')
          .update(<String, dynamic>{
            'avatar_path': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);

      final oldPath = current.avatarPath;
      if (oldPath != null && oldPath.startsWith('${user.id}/')) {
        try {
          await client.storage.from(_avatarBucket).remove(<String>[oldPath]);
        } catch (_) {
          // Database state is authoritative; stale storage cleanup can retry later.
        }
      }
    }

    await LocalPlayerProfile.clearAvatar();
    return PlayerProfileData(
      playerId: current.playerId,
      playerCode: current.playerCode,
      displayName: current.displayName,
      createdAt: current.createdAt,
      isAnonymous: current.isAnonymous,
      isCloudBacked: current.isCloudBacked,
    );
  }

  PlayerProfileData _localFallback({
    String? playerId,
    bool isAnonymous = true,
  }) {
    final id = playerId ?? LocalPlayerProfile.localId;
    return PlayerProfileData(
      playerId: id,
      playerCode: LocalPlayerProfile.playerCodeFor(id),
      displayName: LocalPlayerProfile.displayName,
      avatarPath: LocalPlayerProfile.avatarPath,
      avatarUrl: LocalPlayerProfile.avatarUrl,
      createdAt: LocalPlayerProfile.createdAt,
      isAnonymous: isAnonymous,
      isCloudBacked: playerId != null,
    );
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static String _safeExtension(String extension) {
    final normalized = extension.toLowerCase().replaceAll('.', '');
    return switch (normalized) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
  }
}
