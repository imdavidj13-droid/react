import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mode Lab run engines stay wired to central audio cues', () {
    final waveTwo = File(
      'lib/features/modes/presentation/wave_two_variant_run_screen.dart',
    ).readAsStringSync();
    final enhanced = File(
      'lib/features/modes/presentation/enhanced_variant_run_screen.dart',
    ).readAsStringSync();
    final pressureGrid = File(
      'lib/features/modes/presentation/mosaic_pressure_run_screen.dart',
    ).readAsStringSync();
    final randomTarget = File(
      'lib/features/modes/presentation/random_target_run_screen.dart',
    ).readAsStringSync();

    for (final source in [waveTwo, enhanced]) {
      expect(source, contains("../../../core/audio/react_audio.dart"));
      expect(source, contains('ReactSoundCue.countdownTick'));
      expect(source, contains('ReactSoundCue.countdownGo'));
      expect(source, contains('ReactSoundCue.command'));
      expect(source, contains('ReactSoundCue.success'));
      expect(source, contains('ReactSoundCue.lifeLost'));
      expect(source, contains('ReactSoundCue.completed'));
    }

    expect(pressureGrid, contains("../../../core/audio/react_audio.dart"));
    expect(pressureGrid, contains('ReactSoundCue.countdownTick'));
    expect(pressureGrid, contains('ReactSoundCue.countdownGo'));
    expect(pressureGrid, contains('ReactSoundCue.command'));
    expect(pressureGrid, contains('ReactSoundCue.success'));
    expect(pressureGrid, contains('ReactSoundCue.completed'));

    expect(randomTarget, contains('ReactSoundCue.command'));
    expect(randomTarget, contains('ReactSoundCue.success'));
    expect(randomTarget, contains('ReactSoundCue.lifeLost'));
    expect(randomTarget, contains('ReactSoundCue.completed'));
  });
}
