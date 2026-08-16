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

  await ReactSettings.load();
  await LocalShopState.load();
  await ReactAudio.initialize();
  runApp(const ReactApp());
}
