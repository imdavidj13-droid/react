import 'dart:math';

import 'package:flutter/widgets.dart';

class DotSequenceRound {
  const DotSequenceRound({required this.positions});

  // Position centres stay deliberately conservative because the rendered dot
  // itself has size, border and glow and the gameplay layout shifts the field
  // slightly downward beneath the Sequence heading.
  static const double maximumRadius = .56;

  final List<Offset> positions;

  int get dotCount => positions.length;

  static DotSequenceRound generate(
    Random random, {
    required int count,
    double minimumSpacing = .32,
  }) {
    assert(count >= 1);

    final positions = <Offset>[];
    var attempts = 0;

    while (positions.length < count && attempts < 600) {
      attempts += 1;

      final angle = random.nextDouble() * pi * 2;
      final radius = sqrt(random.nextDouble()) * maximumRadius;
      final candidate = Offset(cos(angle) * radius, sin(angle) * radius);

      final clear = positions.every(
        (existing) => (existing - candidate).distance >= minimumSpacing,
      );
      if (clear) positions.add(candidate);
    }

    while (positions.length < count) {
      final index = positions.length;
      final angle = (pi * 2 * index) / count;
      positions.add(Offset(cos(angle) * .48, sin(angle) * .48));
    }

    return DotSequenceRound(positions: List<Offset>.unmodifiable(positions));
  }
}
