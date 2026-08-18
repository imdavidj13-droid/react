import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LocalPlayerProfile {
  LocalPlayerProfile._();

  static const _idKey = 'react_player_local_id';
  static const _displayNameKey = 'react_player_display_name';

  static String localId = '';
  static String displayName = 'PLAYER';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_idKey)?.trim() ?? '';
    if (id.isEmpty) {
      id = _generateLocalId();
      await prefs.setString(_idKey, id);
    }

    localId = id;
    final storedName = prefs.getString(_displayNameKey)?.trim();
    displayName = storedName == null || storedName.isEmpty
        ? defaultDisplayNameFor(id)
        : storedName;

    if (storedName == null || storedName.isEmpty) {
      await prefs.setString(_displayNameKey, displayName);
    }
  }

  static Future<void> setDisplayName(String value) async {
    final normalized = normalizeDisplayName(value);
    final validationError = validateDisplayName(normalized);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    displayName = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, normalized);
  }

  static String normalizeDisplayName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? validateDisplayName(String value) {
    final normalized = normalizeDisplayName(value);
    if (normalized.length < 3 || normalized.length > 20) {
      return 'Name must be 3 to 20 characters.';
    }
    if (!RegExp(r'^[A-Za-z0-9 _-]+$').hasMatch(normalized)) {
      return 'Use letters, numbers, spaces, _ or - only.';
    }
    return null;
  }

  static String defaultDisplayNameFor(String id) {
    final compact = id.replaceAll('-', '').toUpperCase();
    final suffix = compact.length >= 6 ? compact.substring(0, 6) : compact.padRight(6, '0');
    return 'PLAYER-$suffix';
  }

  static String _generateLocalId() {
    final random = Random.secure();
    const alphabet = '0123456789abcdef';
    return List<String>.generate(
      24,
      (_) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    ).join();
  }
}
