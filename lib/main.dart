import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/react_app.dart';
import 'core/audio/react_audio.dart';
import 'core/backend/react_supabase.dart';
import 'core/settings/react_settings.dart';
import 'features/leaderboard/data/remote_leaderboard_submission_sync.dart';
import 'features/player/data/local_player_profile.dart';
import 'features/shop/data/local_shop_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF050911),
      systemNavigationBarDividerColor: Color(0xFF050911),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await ReactSettings.load();
  } catch (error) {
    debugPrint('RE△CT settings load failed; using defaults: $error');
  }

  try {
    await LocalShopState.load();
  } catch (error) {
    debugPrint('RE△CT cosmetics load failed; using defaults: $error');
  }

  // The local guest profile is the player's identity even when offline. It is
  // created before the UI boots and later mirrored to the anonymous Supabase
  // account when online services are available.
  try {
    await LocalPlayerProfile.load();
  } catch (error) {
    debugPrint('RE△CT player profile load failed; using in-memory identity: $error');
  }

  var supabaseReady = false;
  try {
    await ReactSupabase.initialize();
    supabaseReady = true;
  } catch (error) {
    debugPrint('RE△CT Supabase initialization failed; continuing offline: $error');
  }

  try {
    await ReactAudio.initialize();
  } catch (error) {
    debugPrint('RE△CT audio initialization failed; continuing: $error');
  }

  runApp(const ReactApp());

  if (supabaseReady) {
    unawaited(_startOnlineServices());
  }
}

Future<void> _startOnlineServices() async {
  final sessionReady = await ReactSupabase.ensurePlayerSession(
    displayName: LocalPlayerProfile.displayName,
  );
  if (!sessionReady) return;
  await RemoteLeaderboardSubmissionSync.flushPending();
}
