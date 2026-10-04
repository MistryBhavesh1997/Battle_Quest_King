import 'package:flame/components.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';
import '../controllers/toast_controller.dart';

class SaveService extends GetxService {
  final _box = GetStorage();

  bool get hasSave => _box.hasData('player');

  Vector2? get savedPosition {
    final p = _box.read<List>('pos');
    if (p == null) return null;
    return Vector2((p[0] as num).toDouble(), (p[1] as num).toDouble());
  }

  void save(Vector2 pos) {
    _box.write('player', Get.find<PlayerController>().toJson());
    _box.write('inventory', Get.find<InventoryController>().toJson());
    _box.write('quests', Get.find<QuestController>().toJson());
    _box.write('pos', [pos.x, pos.y]);
    ToastController.show('💾 Game saved');
  }

  void load() {
    if (!hasSave) return;
    Get.find<PlayerController>().fromJson(Map<String, dynamic>.from(_box.read('player')));
    Get.find<InventoryController>().fromJson(Map<String, dynamic>.from(_box.read('inventory') ?? {}));
    Get.find<QuestController>().fromJson(_box.read<List>('quests') ?? []);
  }

  Future<void> newGame() async {
    await _box.erase();
    Get.find<PlayerController>().reset();
    Get.find<InventoryController>().reset();
    Get.find<QuestController>().reset();
  }
}
