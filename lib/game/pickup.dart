import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../data/items.dart';
import 'fx.dart';
import 'rpg_game.dart';

class Pickup extends SpriteComponent with HasGameReference<RpgGame> {
  Pickup({required this.spawnKey, required this.itemId, required Vector2 position})
      : _baseY = position.y,
        super(position: position, size: Vector2.all(16), anchor: Anchor.center, priority: 4);

  final String spawnKey, itemId;
  final double _baseY;
  double _t = Random().nextDouble() * 6;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(Items.all[itemId]?.icon ?? 'potion.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y = _baseY + sin(_t * 3) * 2; // float up and down

    if (game.player.position.distanceTo(position) < 16) {
      Get.find<InventoryController>().pickUp(spawnKey, itemId);
      Fx.burst(game.world, position.clone(), color: const Color(0xFFFFE082), count: 14, speed: 70, gravity: -30);
      game.world.add(FloatingText(Items.all[itemId]?.name ?? itemId,
          position: position + Vector2(0, -12), color: Colors.white, fontSize: 8));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Pulsing glow + ground shadow behind the icon.
    final pulse = 0.5 + 0.5 * sin(_t * 4);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      9 + pulse * 2,
      Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.18 + pulse * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    super.render(canvas);
  }
}
