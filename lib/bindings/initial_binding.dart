import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';
import '../controllers/toast_controller.dart';
import '../services/save_service.dart';

/// Permanent controllers: progress lives here for the whole app session.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ToastController(), permanent: true);
    Get.put(SaveService(), permanent: true);
    Get.put(PlayerController(), permanent: true);
    Get.put(InventoryController(), permanent: true);
    Get.put(QuestController(), permanent: true);
    Get.put(DialogueController(), permanent: true);
  }
}
