import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mosaic pressure escalates spawn speed and burst size', () {
    final source = File(
      'lib/features/modes/presentation/mosaic_pressure_run_screen.dart',
    ).readAsStringSync();

    expect(source, contains('return max(\n      90,'));
    expect(source, contains('final timePressure = seconds * 8;'));
    expect(source, contains('final scorePressure = _score * 5;'));
    expect(source, contains('if (seconds >= 30 || _score >= 25)'));
    expect(source, contains('if (seconds >= 60 || _score >= 50)'));
    expect(source, contains('if (seconds >= 120 || _score >= 120)'));
    expect(source, contains('if (seconds >= 180 || _score >= 180)'));
    expect(source, contains('return 2 + _random.nextInt(2);'));
    expect(source, contains('_activateBurst()'));
    expect(source, contains('for (var i = 0; i < amount; i++)'));
  });
}
