import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/settings/react_settings.dart';
import '../core/theme/react_colors.dart';

class ReactGame extends FlameGame {
  ReactGame();

  Color accent = ReactColors.electricBlueBright;
  double intensity = .18;

  final Random _random = Random();

  bool get effectsEnabled => ReactSettings.visualEffectsEnabled;
  double get effectiveIntensity => effectsEnabled ? intensity : 0;

  bool get isBlitz => accent == ReactColors.coral;
  bool get isEndless => accent == ReactColors.lime;
  bool get isPassIt => accent == ReactColors.purple;

  @override
  Color backgroundColor() => ReactColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_AmbientParticleField(game: this));
    add(_PressureField(game: this));
    add(_ModeSignatureField(game: this));
  }

  void configure({required Color accent, required double intensity}) {
    this.accent = accent;
    this.intensity = intensity.clamp(0.0, 1.0).toDouble();
  }

  void setIntensity(double value) {
    intensity = value.clamp(0.0, 1.0).toDouble();
  }

  void triggerSuccess() {
    if (!effectsEnabled) return;
    add(
      _ReactionBurst(
        game: this,
        color: accent,
        particleCount: 18 + (intensity * 12).round(),
        speed: 105 + (intensity * 95),
      ),
    );
    add(
      _PulseRing(
        game: this,
        color: accent,
        lifetime: .28,
        maxRadiusFactor: .30 + intensity * .10,
      ),
    );
  }

  void triggerMiss() {
    if (!effectsEnabled) return;
    add(
      _ReactionBurst(
        game: this,
        color: ReactColors.coral,
        particleCount: 26,
        speed: 165,
        outwardBias: 1.2,
      ),
    );
    add(
      _PulseRing(
        game: this,
        color: ReactColors.coral,
        lifetime: .42,
        maxRadiusFactor: .43,
        strokeWidth: 5,
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
    for (var i = 0; i < 38; i++) {
      _particles.add(_newParticle(initial: true));
    }
  }

  _AmbientParticle _newParticle({bool initial = false}) {
    final position = game.randomPoint();
    return _AmbientParticle(
      x: position.dx,
      y: initial ? position.dy : game.size.y + 8,
      radius: 0.7 + _random.nextDouble() * 1.5,
      speed: 7 + _random.nextDouble() * 18,
      drift: (_random.nextDouble() - .5) * 8,
      phase: _random.nextDouble() * pi * 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.effectsEnabled || game.size.x <= 0 || game.size.y <= 0) return;

    final speedMultiplier = .7 + game.effectiveIntensity * 2.1;
    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      particle.phase += dt * (1.2 + game.effectiveIntensity * 3.0);
      particle.y -= particle.speed * speedMultiplier * dt;
      particle.x += sin(particle.phase) * particle.drift * dt;

      if (particle.y < -10 ||
          particle.x < -12 ||
          particle.x > game.size.x + 12) {
        _particles[i] = _newParticle();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!game.effectsEnabled) return;
    final baseAlpha = .04 + game.effectiveIntensity * .065;

    for (final particle in _particles) {
      final shimmer = .72 + sin(particle.phase) * .28;
      final alpha = (baseAlpha * shimmer).clamp(0.0, .14).toDouble();
      final paint = Paint()..color = game.accent.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        paint,
      );
    }
  }
}

class _PressureField extends Component {
  _PressureField({required this.game});

  final ReactGame game;
  double _phase = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * (1.1 + game.effectiveIntensity * 4.4);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!game.effectsEnabled ||
        game.size.x <= 0 ||
        game.size.y <= 0 ||
        game.effectiveIntensity < .38) {
      return;
    }

    final pressure =
        ((game.effectiveIntensity - .38) / .62).clamp(0.0, 1.0).toDouble();
    final pulse = .65 + sin(_phase) * .35;
    final alpha = (.025 + pressure * .09) * pulse;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 + pressure * 2.8
      ..color = game.accent.withValues(alpha: alpha.clamp(0.0, .13).toDouble());

    final inset = 8 + pressure * 12;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      max(0, game.size.x - inset * 2),
      max(0, game.size.y - inset * 2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(28 + pressure * 14)),
      paint,
    );

    if (pressure < .45) return;

    final streakPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2 + pressure * 1.8
      ..color = game.accent.withValues(alpha: (.04 + pressure * .07).toDouble());
    final length = 18 + pressure * 44;
    final travel = (_phase * 64) % max(1, game.size.y);

    final count = game.isEndless ? 8 : 5;
    for (var i = 0; i < count; i++) {
      final y = (travel + i * game.size.y / count) % max(1, game.size.y);
      canvas.drawLine(Offset(8, y), Offset(8 + length, y), streakPaint);
      canvas.drawLine(
        Offset(game.size.x - 8, game.size.y - y),
        Offset(game.size.x - 8 - length, game.size.y - y),
        streakPaint,
      );
    }
  }
}

class _ModeSignatureField extends Component {
  _ModeSignatureField({required this.game});

  final ReactGame game;
  double _phase = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final speed = game.isBlitz
        ? 5.8
        : game.isEndless
            ? 2.5 + game.effectiveIntensity * 5.5
            : game.isPassIt
                ? 1.7
                : .8;
    _phase += dt * speed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!game.effectsEnabled || game.size.x <= 0 || game.size.y <= 0) return;

    if (game.isBlitz) {
      _renderBlitz(canvas);
    } else if (game.isEndless) {
      _renderEndless(canvas);
    } else if (game.isPassIt) {
      _renderPassIt(canvas);
    }
  }

  void _renderBlitz(Canvas canvas) {
    final center = Offset(game.size.x / 2, game.size.y / 2);
    final radius = min(game.size.x, game.size.y) * .46;
    final alpha = (.025 + game.effectiveIntensity * .035).clamp(0.0, .055).toDouble();
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7
      ..color = game.accent.withValues(alpha: alpha);

    for (var i = 0; i < 4; i++) {
      final angle = _phase + i * pi / 2;
      final inner = center + Offset(cos(angle), sin(angle)) * (radius * .76);
      final outer = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawLine(inner, outer, paint);
    }
  }

  void _renderEndless(Canvas canvas) {
    if (game.effectiveIntensity < .45) return;

    final pressure =
        ((game.effectiveIntensity - .45) / .55).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1 + pressure * 1.5
      ..color = game.accent.withValues(alpha: (.025 + pressure * .07).toDouble());

    final spacing = 64 - pressure * 28;
    final travel = (_phase * 34) % spacing;
    final length = 24 + pressure * 58;

    for (double y = -spacing + travel; y < game.size.y + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(length, y - length * .30),
        paint,
      );
      canvas.drawLine(
        Offset(game.size.x, game.size.y - y),
        Offset(game.size.x - length, game.size.y - y + length * .30),
        paint,
      );
    }
  }

  void _renderPassIt(Canvas canvas) {
    final center = Offset(game.size.x / 2, game.size.y / 2);
    final radius = min(game.size.x, game.size.y) * .40;
    final paint = Paint()..color = game.accent.withValues(alpha: .10);

    for (var i = 0; i < 3; i++) {
      final angle = _phase + i * (pi * 2 / 3);
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(point, 2.2, paint);
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
      particle.velocity = particle.velocity * drag;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final life = (1 - (_age / _lifetime)).clamp(0.0, 1.0).toDouble();
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

class _PulseRing extends Component {
  _PulseRing({
    required this.game,
    required this.color,
    required this.lifetime,
    required this.maxRadiusFactor,
    this.strokeWidth = 3,
  });

  final ReactGame game;
  final Color color;
  final double lifetime;
  final double maxRadiusFactor;
  final double strokeWidth;

  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (game.size.x <= 0 || game.size.y <= 0) return;

    final t = (_age / lifetime).clamp(0.0, 1.0).toDouble();
    final radius = min(game.size.x, game.size.y) * maxRadiusFactor * t;
    final alpha = ((1 - t) * .42).clamp(0.0, .42).toDouble();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * (1 - t * .35)
      ..color = color.withValues(alpha: alpha);

    canvas.drawCircle(
      Offset(game.size.x / 2, game.size.y / 2),
      radius,
      paint,
    );
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
