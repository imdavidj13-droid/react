import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/react_app.dart';
import 'core/audio/react_audio.dart';
import 'core/settings/react_settings.dart';
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

  // Persisted preferences are useful but not required to boot. If a platform
  // storage plugin is unavailable, the in-memory defaults keep the game usable.
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

  // Audio is optional gameplay polish. A platform audio-session or temporary
  // file failure must never prevent the app itself from launching.
  try {
    await ReactAudio.initialize();
  } catch (error) {
    debugPrint('RE△CT audio initialization failed; continuing: $error');
  }

  runApp(const ReactApp());
}
