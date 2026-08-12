import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.soundEnabled = true;
    ReactSettings.visualEffectsEnabled = true;
    ReactSettings.passItPlayerCount = 3;
  });

  test('settings default to enabled with three Pass It players', () async {
    await ReactSettings.load();

    expect(ReactSettings.soundEnabled, isTrue);
    expect(ReactSettings.visualEffectsEnabled, isTrue);
    expect(ReactSettings.passItPlayerCount, 3);
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

  test('Pass It player count persists', () async {
    await ReactSettings.setPassItPlayerCount(4);
    ReactSettings.passItPlayerCount = 3;

    await ReactSettings.load();

    expect(ReactSettings.passItPlayerCount, 4);
  });

  test('Pass It player count is clamped to two through four', () async {
    await ReactSettings.setPassItPlayerCount(99);
    expect(ReactSettings.passItPlayerCount, 4);

    await ReactSettings.setPassItPlayerCount(0);
    expect(ReactSettings.passItPlayerCount, 2);
  });
}
