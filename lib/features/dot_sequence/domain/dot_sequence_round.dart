import 'dart:math';

import 'package:flutter/widgets.dart';

class DotSequenceRound {
  const DotSequenceRound({required this.positions});

  // Positions are normalized against the Sequence arena's placement radius.
  // Keeping centres inside this radius leaves visible clearance from the
  // surrounding gameplay ring even after the rendered dot size is included.
  static const double maximumRadius = .84;
  static const double defaultMinimumSpacing = .62;

  final List<Offset> positions;

  int get dotCount => positions.length;

  static DotSequenceRound generate(
    Random random, {
    required int count,
    double minimumSpacing = defaultMinimumSpacing,
  }) {
    assert(count >= 1);
    assert(minimumSpacing > 0);

    // Build a completely fresh random layout whenever a partial attempt gets
    // boxed in. The previous implementation eventually fell back to a regular
    // polygon, which made five-dot rounds visibly repeat the same pattern.
    // Restarting preserves true random placement while still enforcing the
    // requested spacing between every pair of dots.
    while (true) {
      final positions = <Offset>[];
      var attempts = 0;

      while (positions.length < count && attempts < 400) {
        attempts += 1;

        // sqrt() gives an even distribution across the area of the circle,
        // rather than clustering points around its centre.
        final angle = random.nextDouble() * pi * 2;
        final radius = sqrt(random.nextDouble()) * maximumRadius;
        final candidate = Offset(cos(angle) * radius, sin(angle) * radius);

        final clear = positions.every(
          (existing) => (existing - candidate).distance >= minimumSpacing,
        );
        if (clear) positions.add(candidate);
      }

      if (positions.length == count) {
        return DotSequenceRound(
          positions: List<Offset>.unmodifiable(positions),
        );
      }
    }
  }
}
