import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/player_controller.dart';
import 'enemy.dart';
import 'fx.dart';
import 'npc.dart';
import 'rpg_game.dart';

enum Facing { down, left, right, up } // = rows in hero.png

class Player extends SpriteAnimationGroupComponent<Facing> with HasGameReference<RpgGame> {
  Player({required super.position})
      : super(size: Vector2.all(32), anchor: Anchor.center, priority: 10);

  static const speed = 90.0;

  final _stats = Get.find<PlayerController>();
  final _dialogue = Get.find<DialogueController>();
  double _attackCooldown = 0;
  double _dustTimer = 0;
  int _lastHp = 0;
  final _workers = <Worker>[];

  bool get _locked => _dialogue.isOpen.value || _stats.isDead;

  double get _facingAngle => switch (current ?? Facing.down) {
        Facing.down => pi / 2,
        Facing.left => pi,
        Facing.right => 0,
        Facing.up => -pi / 2,
      };

  Vector2 get _facingVector => Vector2(cos(_facingAngle), sin(_facingAngle));

  @override
  Future<void> onLoad() async {
    final sheet = SpriteSheet(
      image: await game.images.load('hero.png'),
      srcSize: Vector2.all(32),
    );
    animations = {
      for (final f in Facing.values) f: sheet.createAnimation(row: f.index, stepTime: 0.14),
    };
    current = Facing.down;
    playing = false;

    _lastHp = _stats.hp.value;
    _workers.add(ever<int>(_stats.hp, (hp) {
      final delta = hp - _lastHp;
      _lastHp = hp;
      if (delta < 0) {
        add(ColorEffect(Colors.red, EffectController(duration: 0.12, alternate: true, repeatCount: 2),
            opacityTo: 0.7));
        game.world.add(FloatingText('$delta', position: position + Vector2(0, -20), color: Colors.redAccent, fontSize: 11));
      } else if (delta > 0) {
        game.world.add(FloatingText('+$delta', position: position + Vector2(0, -20), color: Colors.lightGreenAccent, fontSize: 11));
        Fx.burst(game.world, position + Vector2(0, 4), color: Colors.lightGreenAccent, count: 12, speed: 40, gravity: -50);
      }
    }));
    _workers.add(ever<int>(_stats.levelUpTick, (_) => Fx.levelUp(game.world, position.clone())));
  }

  @override
  void onRemove() {
    for (final w in _workers) {
      w.dispose();
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _attackCooldown -= dt;

    final input = game.moveInput;
    if (_locked || input.isZero()) {
      playing = false;
      animationTicker?.reset(); // idle on the standing frame
      return;
    }

    playing = true;
    game.moveWithCollision(this, input * speed * dt);

    current = input.x.abs() > input.y.abs()
        ? (input.x > 0 ? Facing.right : Facing.left)
        : (input.y > 0 ? Facing.down : Facing.up);

    _dustTimer -= dt;
    if (_dustTimer <= 0) {
      _dustTimer = 0.22;
      Fx.dust(game.world, position + Vector2(0, 12));
    }
  }

  /// TALK button
  void interact() {
    if (_locked) return;
    for (final npc in game.world.children.whereType<Npc>()) {
      if (npc.position.distanceTo(position) < 36) {
        npc.onInteract();
        return;
      }
    }
  }

  /// ATTACK button
  void attack() {
    if (_locked || _attackCooldown > 0) return;
    _attackCooldown = 0.4;

    // Swing animation: a quick lunge plus the slash arc.
    add(ScaleEffect.to(Vector2.all(1.12), EffectController(duration: 0.07, alternate: true)));
    game.world.add(SlashFx(position: position + _facingVector * 12 + Vector2(0, 4), direction: _facingAngle));

    for (final e in game.world.children.whereType<Enemy>().toList()) {
      final to = e.position - position;
      final inFront = to.length == 0 || _facingVector.dot(to.normalized()) > -0.3;
      if (to.length < 40 && inFront) e.takeHit(_stats.attack.value, from: position);
    }
  }
}
