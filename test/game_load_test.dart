import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:questkings/bindings/initial_binding.dart';
import 'package:questkings/controllers/player_controller.dart';
import 'package:questkings/game/enemy.dart';
import 'package:questkings/game/npc.dart';
import 'package:questkings/game/pickup.dart';
import 'package:questkings/game/rpg_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('questkings_test').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir,
    );
    await GetStorage.init();
    Get.reset();
    InitialBinding().dependencies();
  });

  testWithGame<RpgGame>(
    'village map loads with walls, npc, enemies and pickups',
    RpgGame.new,
    (game) async {
      await game.ready(); // flush components queued during onLoad
      expect(game.walls, isNotEmpty);
      expect(game.world.children.whereType<Npc>(), hasLength(1));
      expect(game.world.children.whereType<Enemy>(), hasLength(5));
      expect(game.world.children.whereType<Pickup>(), hasLength(3));
    },
  );

  testWithGame<RpgGame>('hero is stopped by the border wall', RpgGame.new, (game) async {
    await game.ready();
    game.player.position.setValues(24, 24);
    game.moveWithCollision(game.player, Vector2(-20, 0));
    expect(game.player.position.x, greaterThan(0));
  });

  testWithGame<RpgGame>('killing a slime pays XP', RpgGame.new, (game) async {
    await game.ready();
    final slime = game.world.children.whereType<Enemy>().first;
    slime.takeHit(999, from: slime.position);
    expect(Get.find<PlayerController>().xp.value, 10);
  });
}
