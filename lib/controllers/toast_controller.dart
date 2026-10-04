import 'package:get/get.dart';

class ToastMsg {
  ToastMsg(this.id, this.text);
  final int id;
  final String text;
}

/// In-game notifications (pickups, quests, saves). Rendered by `ToastLayer`.
class ToastController extends GetxController {
  final toasts = <ToastMsg>[].obs;
  int _next = 0;

  static void show(String text) {
    if (Get.isRegistered<ToastController>()) Get.find<ToastController>().push(text);
  }

  void push(String text) {
    final m = ToastMsg(_next++, text);
    toasts.add(m);
    if (toasts.length > 3) toasts.removeAt(0);
    Future.delayed(const Duration(milliseconds: 2400), () => toasts.remove(m));
  }
}
