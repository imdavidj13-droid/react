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
  double get effectiveIntensity => effectsEnabled
      ? (0.35 + intensity * 0.65).clamp(0.0, 1.0).toDouble()
      : 0;

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

    final particleBoost = isBlitz
        ? 8
        : isEndless
            ? (intensity * 16).round()
            : isPassIt
                ? 4
                : 0;
    final speedBoost = isBlitz
        ? 75.0
        : isEndless
            ? intensity * 80
            : 0.0;

    add(
      _ReactionBurst(
        game: this,
        color: accent,
        particleCount: 22 + (intensity * 16).round() + particleBoost,
        speed: 115 + (intensity * 105) + speedBoost,
      ),
    );

    add(
      _PulseRing(
        game: this,
        color: accent,
        lifetime: isBlitz ? .22 : .32,
        maxRadiusFactor: .32 + intensity * .11,
        strokeWidth: isBlitz ? 4.5 : 3.5,
      ),
    );

    if (isEndless && intensity >= .62) {
      add(
        _PulseRing(
          game: this,
          color: ReactColors.lime,
          lifetime: .22,
          maxRadiusFactor: .50,
          strokeWidth: 2.6,
        ),
      );
    }

    if (isPassIt) {
      add(
        _PulseRing(
          game: this,
          color: ReactColors.electricBlueBright,
          lifetime: .40,
          maxRadiusFactor: .26,
          strokeWidth: 2.4,
        ),
      );
    }
  }

  void triggerMiss() {
    if (!effectsEnabled) return;

    add(
      _ReactionBurst(
        game: this,
        color: ReactColors.coral,
        particleCount: isEndless ? 44 : 32,
        speed: isEndless ? 230 : 180,
        outwardBias: isEndless ? 1.4 : 1.2,
      ),
    );

    add(
      _PulseRing(
        game: this,
        color: ReactColors.coral,
        lifetime: isBlitz ? .28 : .46,
        maxRadiusFactor: isEndless ? .58 : .46,
        strokeWidth: isEndless ? 6.5 : 5.5,
      ),
    );

    if (isBlitz) {
      add(
        _PulseRing(
          game: this,
          color: ReactColors.coral,
          lifetime: .20,
          maxRadiusFactor: .62,
          strokeWidth: 2.8,
        ),
      );
    }

    if (isPassIt) {
      add(
        _PulseRing(
          game: this,
          color: ReactColors.purple,
          lifetime: .52,
          maxRadiusFactor: .36,
          strokeWidth: 2.8,
        ),
      );
    }
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
    for (var i = 0; i < 48; i++) {
      _particles.add(_newParticle(initial: true));
    }
  }

  _AmbientParticle _newParticle({bool initial = false}) {
    final position = game.randomPoint();
    return _AmbientParticle(
      x: position.dx,
      y: initial ? position.dy : game.size.y + 8,
      radius: 0.9 + _random.nextDouble() * 1.9,
      speed: 8 + _random.nextDouble() * 21,
      drift: (_random.nextDouble() - .5) * 10,
      phase: _random.nextDouble() * pi * 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.effectsEnabled || game.size.x <= 0 || game.size.y <= 0) return;

    final speedMultiplier = .8 + game.effectiveIntensity * 2.4;
    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      particle.phase += dt * (1.3 + game.effectiveIntensity * 3.3);
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
    final baseAlpha = .08 + game.effectiveIntensity * .10;

    for (final particle in _particles) {
      final shimmer = .70 + sin(particle.phase) * .30;
      final alpha = (baseAlpha * shimmer).clamp(0.0, .24).toDouble();
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
        game.effectiveIntensity < .28) {
      return;
    }

    final pressure =
        ((game.effectiveIntensity - .28) / .72).clamp(0.0, 1.0).toDouble();
    final pulse = .68 + sin(_phase) * .32;
    final alpha = (.05 + pressure * .14) * pulse;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + pressure * 3.2
      ..color = game.accent.withValues(alpha: alpha.clamp(0.0, .22).toDouble());

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

    if (pressure < .38) return;

    final streakPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4 + pressure * 2.0
      ..color = game.accent.withValues(alpha: (.07 + pressure * .11).toDouble());
    final length = 20 + pressure * 48;
    final travel = (_phase * 68) % max(1, game.size.y);

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
    final alpha =
        (.06 + game.effectiveIntensity * .06).clamp(0.0, .12).toDouble();
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0
      ..color = game.accent.withValues(alpha: alpha);

    for (var i = 0; i < 4; i++) {
      final angle = _phase + i * pi / 2;
      final inner = center + Offset(cos(angle), sin(angle)) * (radius * .74);
      final outer = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawLine(inner, outer, paint);
    }
  }

  void _renderEndless(Canvas canvas) {
    if (game.effectiveIntensity < .38) return;

    final pressure =
        ((game.effectiveIntensity - .38) / .62).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2 + pressure * 1.8
      ..color = game.accent.withValues(alpha: (.05 + pressure * .11).toDouble());

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
    final paint = Paint()..color = game.accent.withValues(alpha: .17);

    for (var i = 0; i < 3; i++) {
      final angle = _phase + i * (pi * 2 / 3);
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(point, 2.8, paint);
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
  static const _lifetime = .48;

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
          radius: 1.4 + _random.nextDouble() * 2.4,
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
      paint.color = color.withValues(alpha: .72 * life);
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
    final alpha = ((1 - t) * .58).clamp(0.0, .58).toDouble();
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
