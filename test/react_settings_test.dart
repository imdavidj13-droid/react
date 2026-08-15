import 'package:flutter_test/flutter_test.dart';
import 'package:react/core/settings/react_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ReactSettings.soundEnabled = true;
    ReactSettings.visualEffectsEnabled = true;
    ReactSettings.passItPlayerCount = 3;
    ReactSettings.dailyDevOverrideEnabled = false;
    ReactSettings.dailyDevModifier = 'lightsOut';
    ReactSettings.howToPlayCompleted = false;
    ReactSettings.soundPreview = null;
  });

  test('settings default to enabled with three Pass It players', () async {
    await ReactSettings.load();

    expect(ReactSettings.soundEnabled, isTrue);
    expect(ReactSettings.visualEffectsEnabled, isTrue);
    expect(ReactSettings.passItPlayerCount, 3);
    expect(ReactSettings.dailyDevOverrideEnabled, isFalse);
    expect(ReactSettings.dailyDevModifier, 'lightsOut');
    expect(ReactSettings.howToPlayCompleted, isFalse);
  });

  test('sound preference persists', () async {
    await ReactSettings.setSoundEnabled(false);
    ReactSettings.soundEnabled = true;

    await ReactSettings.load();

    expect(ReactSettings.soundEnabled, isFalse);
  });

  test('enabling sound plays one registered preview', () async {
    var previews = 0;
    ReactSettings.soundPreview = () async => previews += 1;

    await ReactSettings.setSoundEnabled(false);
    expect(previews, 0);

    await ReactSettings.setSoundEnabled(true);
    expect(previews, 1);
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

  test('Daily developer override persists', () async {
    await ReactSettings.setDailyDevOverrideEnabled(true);
    await ReactSettings.setDailyDevModifier('redline');

    ReactSettings.dailyDevOverrideEnabled = false;
    ReactSettings.dailyDevModifier = 'lightsOut';
    await ReactSettings.load();

    expect(ReactSettings.dailyDevOverrideEnabled, isTrue);
    expect(ReactSettings.dailyDevModifier, 'redline');
  });

  test('Daily developer modifier accepts every modifier name', () async {
    const names = [
      'lightsOut',
      'surge',
      'noClock',
      'echo',
      'reverse',
      'chain',
      'redline',
    ];

    for (final name in names) {
      await ReactSettings.setDailyDevModifier(name);
      expect(ReactSettings.dailyDevModifier, name);
    }
  });

  test('how to play completion persists', () async {
    await ReactSettings.setHowToPlayCompleted(true);
    ReactSettings.howToPlayCompleted = false;

    await ReactSettings.load();

    expect(ReactSettings.howToPlayCompleted, isTrue);
  });
}
