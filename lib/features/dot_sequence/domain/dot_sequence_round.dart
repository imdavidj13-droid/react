import 'dart:math';

import 'package:flutter/widgets.dart';

class DotSequenceRound {
  const DotSequenceRound({required this.positions});

  final List<Offset> positions;

  int get dotCount => positions.length;

  static DotSequenceRound generate(
    Random random, {
    required int count,
    double minimumSpacing = .24,
  }) {
    assert(count >= 1);

    final positions = <Offset>[];
    var attempts = 0;

    while (positions.length < count && attempts < 600) {
      attempts += 1;

      final angle = random.nextDouble() * pi * 2;
      final radius = sqrt(random.nextDouble()) * .72;
      final candidate = Offset(cos(angle) * radius, sin(angle) * radius);

      final clear = positions.every(
        (existing) => (existing - candidate).distance >= minimumSpacing,
      );
      if (clear) positions.add(candidate);
    }

    while (positions.length < count) {
      final index = positions.length;
      final angle = (pi * 2 * index) / count;
      positions.add(Offset(cos(angle) * .58, sin(angle) * .58));
    }

    return DotSequenceRound(positions: List<Offset>.unmodifiable(positions));
  }
}
