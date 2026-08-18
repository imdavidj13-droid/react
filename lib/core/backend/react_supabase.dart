import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisplayNameUnavailableException implements Exception {
  const DisplayNameUnavailableException();

  @override
  String toString() => 'That player name is already in use.';
}

class ReactSupabase {
  ReactSupabase._();

  static const String projectUrl = 'https://tmvgieybvmkptydfjjtd.supabase.co';
  static const String publishableKey =
      'sb_publishable_qBeehKyLw735wIQ0ppziaQ_V-ILNDoZ';

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static Session? get currentSession => client?.auth.currentSession;
  static User? get currentUser => client?.auth.currentUser;
  static String? get currentPlayerId => currentUser?.id;
  static bool get hasPlayerSession => currentSession != null;
  static bool get isAnonymousPlayer => currentUser?.isAnonymous ?? false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: projectUrl,
      publishableKey: publishableKey,
    );
    _initialized = true;
  }

  /// Creates or restores the persistent backend identity for this installation.
  /// Local play never depends on this succeeding.
  static Future<bool> ensurePlayerSession({String? displayName}) async {
    final supabase = client;
    if (supabase == null) return false;

    try {
      if (supabase.auth.currentSession == null) {
        await supabase.auth.signInAnonymously(
          data: displayName == null ? null : <String, dynamic>{'display_name': displayName},
        );
      }

      if (displayName != null && supabase.auth.currentSession != null) {
        await syncDisplayName(displayName);
      }
      return supabase.auth.currentSession != null;
    } catch (error) {
      debugPrint('RE△CT Supabase anonymous session unavailable: $error');
      return false;
    }
  }

  static Future<void> syncDisplayName(String displayName) async {
    final supabase = client;
    if (supabase == null || supabase.auth.currentSession == null) return;

    try {
      await supabase.rpc(
        'set_player_display_name',
        params: <String, dynamic>{'p_display_name': displayName},
      );
    } on PostgrestException catch (error) {
      if (error.code == '23505' || error.message.contains('display_name_taken')) {
        throw const DisplayNameUnavailableException();
      }
      rethrow;
    }
  }
}
