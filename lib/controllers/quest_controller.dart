import 'package:get/get.dart';
import '../data/quests.dart';
import 'inventory_controller.dart';
import 'player_controller.dart';
import 'toast_controller.dart';

class QuestController extends GetxController {
  final quests = <Quest>[].obs;

  Quest? byId(String id) {
    for (final q in quests) {
      if (q.id == id) return q;
    }
    return null;
  }

  void accept(String id) {
    if (byId(id) != null) return;
    final q = Quests.create(id);
    quests.add(q);
    ToastController.show('📜 New quest: ${q.title}');
  }

  /// Called by Enemy when it dies.
  void onKill(String kind) {
    for (final q in quests) {
      if (!q.done.value && q.targetKind == kind && q.progress.value < q.required) {
        q.progress.value++;
        if (q.isReady) ToastController.show('📜 ${q.title}: return to the quest giver');
      }
    }
  }

  void complete(String id) {
    final q = byId(id);
    if (q == null || !q.isReady) return;
    q.done.value = true;
    final p = Get.find<PlayerController>();
    p.gainXp(q.rewardXp);
    p.addGold(q.rewardGold);
    if (q.rewardItem != null) Get.find<InventoryController>().add(q.rewardItem!);
    ToastController.show('✅ Quest complete: ${q.title}');
  }

  void reset() => quests.clear();

  List<Map<String, dynamic>> toJson() => quests
      .map((q) => {'id': q.id, 'progress': q.progress.value, 'done': q.done.value})
      .toList();

  void fromJson(List data) {
    quests.clear();
    for (final raw in data) {
      final m = Map<String, dynamic>.from(raw);
      final q = Quests.create(m['id']);
      q.progress.value = m['progress'] ?? 0;
      q.done.value = m['done'] ?? false;
      quests.add(q);
    }
  }
}
