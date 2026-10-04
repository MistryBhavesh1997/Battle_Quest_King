import 'package:get/get.dart';

class Quest {
  Quest({
    required this.id,
    required this.title,
    required this.targetKind,
    required this.required,
    this.rewardXp = 0,
    this.rewardGold = 0,
    this.rewardItem,
  });

  final String id, title, targetKind;
  final int required, rewardXp, rewardGold;
  final String? rewardItem;

  final progress = 0.obs;
  final done = false.obs;

  bool get isReady => !done.value && progress.value >= required;
}

class Quests {
  static Quest create(String id) => switch (id) {
        'slime_trouble' => Quest(
            id: id,
            title: 'Slime Trouble',
            targetKind: 'slime',
            required: 3,
            rewardXp: 50,
            rewardGold: 30,
            rewardItem: 'potion',
          ),
        _ => throw ArgumentError('Unknown quest: $id'),
      };
}
