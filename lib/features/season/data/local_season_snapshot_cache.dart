import 'package:shared_preferences/shared_preferences.dart';

import '../domain/season_models.dart';

abstract final class LocalSeasonSnapshotCache {
  static const _chargeKey = 'season_last_known_charge';
  static const _codeKey = 'season_last_known_code';
  static const _endsAtKey = 'season_last_known_ends_at';

  static Future<void> save(SeasonSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait<void>([
      prefs.setInt(_chargeKey, snapshot.charge),
      prefs.setString(_codeKey, snapshot.code),
      prefs.setString(_endsAtKey, snapshot.endsAt.toUtc().toIso8601String()),
    ]);
  }

  /// Returns the cached CHARGE only while its season has not expired.
  /// An old season must never masquerade as current progression during an
  /// offseason or a later season.
  static Future<int?> charge() async {
    final prefs = await SharedPreferences.getInstance();
    final charge = prefs.getInt(_chargeKey);
    final rawEndsAt = prefs.getString(_endsAtKey);
    if (charge == null || rawEndsAt == null) return null;

    final endsAt = DateTime.tryParse(rawEndsAt)?.toUtc();
    if (endsAt == null || !DateTime.now().toUtc().isBefore(endsAt)) {
      await clear();
      return null;
    }
    return charge;
  }

  static Future<String?> seasonCode() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEndsAt = prefs.getString(_endsAtKey);
    final endsAt = rawEndsAt == null ? null : DateTime.tryParse(rawEndsAt)?.toUtc();
    if (endsAt == null || !DateTime.now().toUtc().isBefore(endsAt)) return null;
    return prefs.getString(_codeKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait<void>([
      prefs.remove(_chargeKey),
      prefs.remove(_codeKey),
      prefs.remove(_endsAtKey),
    ]);
  }
}
