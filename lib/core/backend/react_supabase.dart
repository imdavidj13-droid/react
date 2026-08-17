import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReactSupabase {
  ReactSupabase._();

  static const String projectUrl = 'https://tmvgieybvmkptydfjjtd.supabase.co';
  static const String publishableKey =
      'sb_publishable_qBeehKyLw735wIQ0ppziaQ_V-ILNDoZ';

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: projectUrl,
      publishableKey: publishableKey,
    );
    _initialized = true;
  }

  /// Creates a persistent device-level player identity when anonymous Auth is
  /// enabled in Supabase. Existing sessions are reused automatically.
  ///
  /// Failure is intentionally non-fatal: local gameplay and local records must
  /// remain available when the device is offline or the backend is unavailable.
  static Future<void> ensurePlayerSession() async {
    final supabase = client;
    if (supabase == null || supabase.auth.currentSession != null) return;

    try {
      await supabase.auth.signInAnonymously();
    } catch (error) {
      debugPrint('RE△CT Supabase anonymous session unavailable: $error');
    }
  }
}
