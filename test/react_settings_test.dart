import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.soundEnabled = true;
    ReactSettings.visualEffectsEnabled = true;
  });

  test('settings default to enabled', () async {
    await ReactSettings.load();

    expect(ReactSettings.soundEnabled, isTrue);
    expect(ReactSettings.visualEffectsEnabled, isTrue);
  });

  test('sound preference persists', () async {
    await ReactSettings.setSoundEnabled(false);
    ReactSettings.soundEnabled = true;

    await ReactSettings.load();

    expect(ReactSettings.soundEnabled, isFalse);
  });

  test('visual effects preference persists', () async {
    await ReactSettings.setVisualEffectsEnabled(false);
    ReactSettings.visualEffectsEnabled = true;

    await ReactSettings.load();

    expect(ReactSettings.visualEffectsEnabled, isFalse);
  });
}
