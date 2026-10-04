import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Small, reusable visual effects (particles, floating text, sword slash).
class Fx {
  static final _rnd = Random();

  /// Radial burst of fading dots.
  static void burst(
    Component parent,
    Vector2 at, {
    Color color = Colors.white,
    int count = 14,
    double speed = 80,
    double life = 0.6,
    double size = 2.5,
    double gravity = 120,
  }) {
    parent.add(ParticleSystemComponent(
      position: at.clone(),
      priority: 20,
      particle: Particle.generate(
        count: count,
        lifespan: life,
        generator: (i) {
          final a = _rnd.nextDouble() * pi * 2;
          final v = Vector2(cos(a), sin(a)) * (speed * (0.4 + _rnd.nextDouble() * 0.6));
          return AcceleratedParticle(
            acceleration: Vector2(0, gravity),
            speed: v,
            child: ComputedParticle(renderer: (canvas, p) {
              final alpha = (1 - p.progress).clamp(0.0, 1.0);
              canvas.drawCircle(
                Offset.zero,
                size * (1 - p.progress * 0.6),
                Paint()..color = color.withValues(alpha: alpha),
              );
            }),
          );
        },
      ),
    ));
  }

  /// Soft puff under the hero's feet.
  static void dust(Component parent, Vector2 at) => burst(
        parent,
        at,
        color: const Color(0xFFE8D8B0),
        count: 4,
        speed: 14,
        life: 0.4,
        size: 2,
        gravity: -10,
      );

  /// Rising golden sparks (level up).
  static void levelUp(Component parent, Vector2 at) {
    burst(parent, at, color: const Color(0xFFFFD54F), count: 30, speed: 110, life: 1.0, size: 3, gravity: -40);
    burst(parent, at, color: Colors.white, count: 14, speed: 60, life: 0.8, size: 2, gravity: -60);
  }
}

/// Number / text that pops, drifts upward and fades.
class FloatingText extends PositionComponent {
  FloatingText(
    this.text, {
    required Vector2 position,
    this.color = Colors.white,
    this.fontSize = 9,
  }) : super(position: position, anchor: Anchor.center, priority: 30);

  final String text;
  final Color color;
  final double fontSize;
  static const _life = 0.9;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    position.y -= 22 * dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final pop = k < 0.2 ? 0.6 + 2 * k * 2 : 1.0; // quick overshoot-free pop
    final alpha = k < 0.6 ? 1.0 : (1 - (k - 0.6) / 0.4);
    canvas.save();
    canvas.scale(pop.clamp(0.6, 1.0));
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Colors.black.withValues(alpha: alpha), blurRadius: 0, offset: const Offset(0.8, 0.8))],
      ),
    ).render(canvas, text, Vector2.zero(), anchor: Anchor.center);
    canvas.restore();
  }
}

/// Expanding crescent drawn when the hero swings.
class SlashFx extends PositionComponent {
  SlashFx({required Vector2 position, required this.direction}) : super(position: position, priority: 15);

  final double direction; // radians
  static const _life = 0.2;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4 * (1 - k) + 0.5
      ..color = Colors.white.withValues(alpha: 1 - k);
    final r = 18 + 12 * k;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r),
      direction - 1.0 + k * 0.5,
      2.0,
      false,
      paint,
    );
  }
}
