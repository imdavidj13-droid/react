import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/theme/react_colors.dart';

class ReactGame extends FlameGame {
  ReactGame();

  Color accent = ReactColors.electricBlueBright;
  double intensity = .18;

  final Random _random = Random();

  @override
  Color backgroundColor() => ReactColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_AmbientParticleField(game: this));
  }

  void configure({required Color accent, required double intensity}) {
    this.accent = accent;
    this.intensity = intensity.clamp(0, 1);
  }

  void setIntensity(double value) {
    intensity = value.clamp(0, 1);
  }

  void triggerSuccess() {
    add(
      _ReactionBurst(
        game: this,
        color: accent,
        particleCount: 18 + (intensity * 12).round(),
        speed: 105 + (intensity * 95),
      ),
    );
  }

  void triggerMiss() {
    add(
      _ReactionBurst(
        game: this,
        color: ReactColors.coral,
        particleCount: 26,
        speed: 165,
        outwardBias: 1.2,
      ),
    );
  }

  Offset randomPoint() {
    if (size.x <= 0 || size.y <= 0) return Offset.zero;
    return Offset(
      _random.nextDouble() * size.x,
      _random.nextDouble() * size.y,
    );
  }
}

class _AmbientParticleField extends Component {
  _AmbientParticleField({required this.game});

  final ReactGame game;
  final Random _random = Random();
  final List<_AmbientParticle> _particles = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (var i = 0; i < 34; i++) {
      _particles.add(_newParticle(initial: true));
    }
  }

  _AmbientParticle _newParticle({bool initial = false}) {
    final position = game.randomPoint();
    return _AmbientParticle(
      x: position.dx,
      y: initial ? position.dy : game.size.y + 8,
      radius: 0.7 + _random.nextDouble() * 1.4,
      speed: 7 + _random.nextDouble() * 17,
      drift: (_random.nextDouble() - .5) * 8,
      phase: _random.nextDouble() * pi * 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.size.x <= 0 || game.size.y <= 0) return;

    final speedMultiplier = .7 + game.intensity * 1.7;
    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      particle.phase += dt * (1.2 + game.intensity * 2.4);
      particle.y -= particle.speed * speedMultiplier * dt;
      particle.x += sin(particle.phase) * particle.drift * dt;

      if (particle.y < -10 || particle.x < -12 || particle.x > game.size.x + 12) {
        _particles[i] = _newParticle();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final baseAlpha = .045 + game.intensity * .055;

    for (final particle in _particles) {
      final shimmer = .72 + sin(particle.phase) * .28;
      final paint = Paint()
        ..color = game.accent.withValues(
          alpha: (baseAlpha * shimmer).clamp(0, .12),
        );
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        paint,
      );
    }
  }
}

class _AmbientParticle {
  _AmbientParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.phase,
  });

  double x;
  double y;
  final double radius;
  final double speed;
  final double drift;
  double phase;
}

class _ReactionBurst extends Component {
  _ReactionBurst({
    required this.game,
    required this.color,
    required this.particleCount,
    required this.speed,
    this.outwardBias = 1,
  });

  final ReactGame game;
  final Color color;
  final int particleCount;
  final double speed;
  final double outwardBias;

  final Random _random = Random();
  final List<_BurstParticle> _particles = [];
  double _age = 0;
  static const _lifetime = .46;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final center = Offset(game.size.x / 2, game.size.y / 2);

    for (var i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final velocity = speed * (.55 + _random.nextDouble() * .65) * outwardBias;
      _particles.add(
        _BurstParticle(
          position: center,
          velocity: Offset(cos(angle), sin(angle)) * velocity,
          radius: 1.2 + _random.nextDouble() * 2.1,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _lifetime) {
      removeFromParent();
      return;
    }

    final drag = pow(.06, dt).toDouble();
    for (final particle in _particles) {
      particle.position += particle.velocity * dt;
      particle.velocity *= drag;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final life = (1 - (_age / _lifetime)).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in _particles) {
      paint.color = color.withValues(alpha: .55 * life);
      canvas.drawCircle(
        particle.position,
        particle.radius * (.65 + life * .55),
        paint,
      );
    }
  }
}

class _BurstParticle {
  _BurstParticle({
    required this.position,
    required this.velocity,
    required this.radius,
  });

  Offset position;
  Offset velocity;
  final double radius;
}
