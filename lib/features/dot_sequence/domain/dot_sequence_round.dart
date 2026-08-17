import 'dart:math';

import 'package:flutter/widgets.dart';

class DotSequenceRound {
  const DotSequenceRound({required this.positions});

  // Position centres stay deliberately conservative because the rendered dot
  // itself has size, border and glow and the gameplay layout reserves a safe
  // title/timer zone above the actual dot field.
  static const double maximumRadius = .56;

  final List<Offset> positions;

  int get dotCount => positions.length;

  static DotSequenceRound generate(
    Random random, {
    required int count,
    double minimumSpacing = .50,
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

    if (positions.length < count) {
      positions
        ..clear()
        ..addAll(
          List<Offset>.generate(count, (index) {
            final angle = -pi / 2 + (pi * 2 * index) / count;
            return Offset(cos(angle) * .48, sin(angle) * .48);
          }),
        );
    }

    return DotSequenceRound(positions: List<Offset>.unmodifiable(positions));
  }
}
