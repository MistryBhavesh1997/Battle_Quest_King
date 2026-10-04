import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';
import 'fx.dart';
import 'rpg_game.dart';

class Enemy extends SpriteAnimationComponent with HasGameReference<RpgGame> {
  Enemy({
    required Vector2 position,
    this.kind = 'slime',
    this.maxHp = 20,
    this.damage = 5,
    this.xp = 10,
    this.gold = 5,
  })  : hp = maxHp,
        home = position.clone(),
        super(position: position, size: Vector2.all(32), anchor: Anchor.center, priority: 5);

  final String kind;
  final int maxHp, damage, xp, gold;
  final Vector2 home;
  int hp;

  static const chaseRange = 120.0, speed = 40.0;
  double _hitCooldown = 0;
  final _knockback = Vector2.zero();

  @override
  Future<void> onLoad() async {
    animation = await game.loadSpriteAnimation(
      '$kind.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2.all(32)),
    );
    // Spawn-in pop.
    scale = Vector2.zero();
    add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.35, curve: Curves.elasticOut)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final stats = Get.find<PlayerController>();
    if (stats.isDead || Get.find<DialogueController>().isOpen.value) return;

    _hitCooldown -= dt;

    if (!_knockback.isZero()) {
      game.moveWithCollision(this, _knockback * dt);
      _knockback.scale(1 - (8 * dt).clamp(0, 1));
      if (_knockback.length < 4) _knockback.setZero();
      return;
    }

    final toPlayer = game.player.position - position;
    final dist = toPlayer.length;

    if (dist < chaseRange && dist > 14) {
      game.moveWithCollision(this, toPlayer.normalized() * speed * dt);
    }
    if (dist < 20 && _hitCooldown <= 0) {
      stats.takeDamage(damage); // contact damage
      _hitCooldown = 1.0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (hp >= maxHp) return;
    // Tiny health bar above the head.
    const w = 20.0;
    final x = (size.x - w) / 2;
    canvas.drawRect(Rect.fromLTWH(x - 0.5, 3.5, w + 1, 4), Paint()..color = Colors.black87);
    canvas.drawRect(
      Rect.fromLTWH(x, 4, w * (hp / maxHp).clamp(0, 1), 3),
      Paint()..color = Colors.redAccent,
    );
  }

  void takeHit(int dmg, {required Vector2 from}) {
    hp -= dmg;
    add(ColorEffect(
      Colors.white,
      EffectController(duration: 0.1, alternate: true),
      opacityTo: 0.9,
    ));
    game.world.add(FloatingText('-$dmg', position: position + Vector2(0, -14), color: Colors.orangeAccent));
    Fx.burst(game.world, position.clone(), color: const Color(0xFF8FE3A0), count: 8, speed: 60);

    final away = position - from;
    _knockback.setFrom(away.isZero() ? Vector2(0, 1) : away.normalized() * 140);

    if (hp <= 0) _die();
  }

  void _die() {
    final stats = Get.find<PlayerController>();
    stats.gainXp(xp);
    stats.addGold(gold);
    Get.find<QuestController>().onKill(kind);

    game.world.add(FloatingText('+$xp XP', position: position + Vector2(0, -20), color: Colors.lightBlueAccent));
    game.world.add(FloatingText('+$gold 🪙', position: position + Vector2(0, -8), color: Colors.amber));
    Fx.burst(game.world, position.clone(), color: const Color(0xFF6FD08C), count: 24, speed: 110, life: 0.8, size: 3);
    game.scheduleRespawn(kind, home);
    removeFromParent();
  }
}
