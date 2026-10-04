import 'package:get/get.dart';
import '../game/rpg_game.dart';
import '../services/save_service.dart';
import 'player_controller.dart';

class GameController extends GetxController {
  late final RpgGame game;

  @override
  void onInit() {
    super.onInit();
    Get.find<SaveService>().load(); // no-op when there is no save
    game = RpgGame();
  }

  void saveGame() => Get.find<SaveService>().save(game.player.position);

  void toggleInventory() {
    if (game.overlays.isActive('inventory')) {
      game.overlays.remove('inventory');
      game.resumeEngine();
    } else {
      game.overlays.add('inventory');
      game.pauseEngine();
    }
  }

  void respawn() {
    final p = Get.find<PlayerController>();
    p.hp.value = p.maxHp.value;
    game.player.position.setFrom(game.spawnPoint);
  }
}
