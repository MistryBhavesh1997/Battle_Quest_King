import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DialogueController extends GetxController {
  final isOpen = false.obs;
  final speaker = ''.obs;
  final lines = <String>[].obs;
  final index = 0.obs;
  VoidCallback? _onEnd;

  String get text => lines.isEmpty ? '' : lines[index.value];

  void start(String who, List<String> l, {VoidCallback? onEnd}) {
    speaker.value = who;
    lines.assignAll(l);
    index.value = 0;
    _onEnd = onEnd;
    isOpen.value = true;
  }

  void next() {
    if (index.value < lines.length - 1) {
      index.value++;
      return;
    }
    isOpen.value = false;
    final cb = _onEnd;
    _onEnd = null;
    cb?.call();
  }
}
