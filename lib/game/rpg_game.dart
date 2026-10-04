import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../services/save_service.dart';
import 'enemy.dart';
import 'npc.dart';
import 'pickup.dart';
import 'player.dart';

class RpgGame extends FlameGame with KeyboardEvents {
  late Player player;
  late JoystickComponent joystick;
  Vector2 spawnPoint = Vector2.zero();

  /// Solid rectangles from the `Collisions` layer.
  final List<Rect> walls = [];

  final _keyDir = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFF1B1B2F);

  @override
  Future<void> onLoad() async {
    // 1) Map
    final map = await TiledComponent.load('village.tmx', Vector2.all(16));
    world.add(map);

    // 2) Walls
    final wallLayer = map.tileMap.getLayer<ObjectGroup>('Collisions');
    for (final o in wallLayer?.objects ?? const <TiledObject>[]) {
      walls.add(Rect.fromLTWH(o.x, o.y, o.width, o.height));
    }

    // 3) Spawns
    final inv = Get.find<InventoryController>();
    final spawns = map.tileMap.getLayer<ObjectGroup>('Spawns');
    for (final o in spawns?.objects ?? const <TiledObject>[]) {
      final pos = Vector2(o.x, o.y);
      final props = o.properties;
      switch (props.getValue<String>('kind')) {
        case 'player':
          spawnPoint = pos;
        case 'npc':
          world.add(Npc(
            npcName: o.name,
            position: pos,
            lines: (props.getValue<String>('dialogue') ?? '...').split('|'),
            questId: props.getValue<String>('quest'),
            spriteFile: props.getValue<String>('sprite') ?? 'npc.png',
          ));
        case 'enemy':
          world.add(Enemy(kind: props.getValue<String>('type') ?? 'slime', position: pos));
        case 'item':
          final key = 'item_${o.id}';
          if (!inv.collected.contains(key)) {
            world.add(Pickup(
              spawnKey: key,
              itemId: props.getValue<String>('item') ?? 'potion',
              position: pos,
            ));
          }
      }
    }

    // 4) Player (saved position or spawn)
    player = Player(position: Get.find<SaveService>().savedPosition ?? spawnPoint.clone());
    world.add(player);

    // 5) Camera: follow the hero and never show outside the map
    camera.viewfinder.zoom = 2.5;
    camera.follow(player, snap: true);
    camera.setBounds(Rectangle.fromLTWH(0, 0, map.size.x, map.size.y));

    // 6) Joystick (fixed on screen, so it goes on the viewport)
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 22, paint: Paint()..color = Colors.white70),
      background: CircleComponent(radius: 55, paint: Paint()..color = Colors.white24),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    camera.viewport.add(joystick);
  }

  /// Joystick + keyboard, clamped to length 1.
  Vector2 get moveInput {
    final v = joystick.relativeDelta + _keyDir;
    return v.length > 1 ? v.normalized() : v;
  }

  bool isBlocked(Rect r) {
    for (final w in walls) {
      if (w.overlaps(r)) return true;
    }
    return false;
  }

  /// Moves [c] by [delta], one axis at a time so it slides along walls.
  /// The collision box is a small rectangle around the character's feet.
  void moveWithCollision(PositionComponent c, Vector2 delta,
      {Vector2? box, double feetOffset = 8}) {
    final size = box ?? Vector2(14, 10);
    Rect feet(double x, double y) =>
        Rect.fromCenter(center: Offset(x, y + feetOffset), width: size.x, height: size.y);

    var x = c.position.x;
    var y = c.position.y;
    if (!isBlocked(feet(x + delta.x, y))) x += delta.x;
    if (!isBlocked(feet(x, y + delta.y))) y += delta.y;
    c.position.setValues(x, y);
  }

  /// Slimes come back so the quest can never be soft-locked.
  void scheduleRespawn(String kind, Vector2 at) {
    add(TimerComponent(
      period: 20,
      removeOnFinish: true,
      onTick: () => world.add(Enemy(kind: kind, position: at.clone())),
    ));
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool down(List<LogicalKeyboardKey> k) => k.any(keysPressed.contains);
    _keyDir.setValues(
      (down([LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight]) ? 1 : 0) -
          (down([LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft]) ? 1 : 0),
      (down([LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown]) ? 1 : 0) -
          (down([LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp]) ? 1 : 0),
    );
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) player.attack();
      if (event.logicalKey == LogicalKeyboardKey.keyE ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        player.interact();
      }
    }
    return KeyEventResult.handled;
  }
}
