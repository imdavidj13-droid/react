import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/react_app.dart';
import 'core/settings/react_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await ReactSettings.load();
  runApp(const ReactApp());
}
