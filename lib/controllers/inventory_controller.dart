import 'package:get/get.dart';
import '../data/items.dart';
import 'player_controller.dart';
import 'toast_controller.dart';

class InventoryController extends GetxController {
  final items = <String, int>{}.obs; // itemId → quantity
  final Set<String> collected = {}; // map pickups already taken

  int count(String id) => items[id] ?? 0;
  bool has(String id) => count(id) > 0;

  void add(String id, [int n = 1]) => items[id] = count(id) + n;

  void pickUp(String spawnKey, String id) {
    collected.add(spawnKey);
    add(id);
    ToastController.show('Picked up ${Items.all[id]?.name ?? id}');
  }

  void use(String id) {
    final item = Items.all[id];
    if (item == null || !has(id)) return;
    if (item.type == ItemType.potion) {
      Get.find<PlayerController>().heal(item.value);
      _removeOne(id);
    }
  }

  void _removeOne(String id) {
    final q = count(id) - 1;
    q <= 0 ? items.remove(id) : items[id] = q;
  }

  void reset() {
    items.clear();
    collected.clear();
  }

  Map<String, dynamic> toJson() => {'items': items, 'collected': collected.toList()};

  void fromJson(Map<String, dynamic> j) {
    items.assignAll(Map<String, int>.from(j['items'] ?? {}));
    collected
      ..clear()
      ..addAll(List<String>.from(j['collected'] ?? []));
  }
}
