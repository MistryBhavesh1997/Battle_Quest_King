import 'package:get/get.dart';

class PlayerController extends GetxController {
  final hp = 100.obs;
  final maxHp = 100.obs;
  final xp = 0.obs;
  final level = 1.obs;
  final gold = 0.obs;
  final attack = 10.obs;

  /// Bumped on every hit / level up so the UI can play one-shot animations.
  final hitTick = 0.obs;
  final levelUpTick = 0.obs;

  int get xpToNext => level.value * 50;
  bool get isDead => hp.value <= 0;

  void takeDamage(int d) {
    if (isDead) return;
    hp.value = (hp.value - d).clamp(0, maxHp.value);
    hitTick.value++;
  }

  void heal(int v) => hp.value = (hp.value + v).clamp(0, maxHp.value);
  void addGold(int g) => gold.value += g;

  void gainXp(int v) {
    xp.value += v;
    while (xp.value >= xpToNext) {
      xp.value -= xpToNext;
      level.value++;
      maxHp.value += 20;
      attack.value += 3;
      hp.value = maxHp.value;
      levelUpTick.value++;
    }
  }

  void reset() {
    hp.value = 100;
    maxHp.value = 100;
    xp.value = 0;
    level.value = 1;
    gold.value = 0;
    attack.value = 10;
  }

  Map<String, dynamic> toJson() => {
        'hp': hp.value,
        'maxHp': maxHp.value,
        'xp': xp.value,
        'level': level.value,
        'gold': gold.value,
        'attack': attack.value,
      };

  void fromJson(Map<String, dynamic> j) {
    maxHp.value = j['maxHp'] ?? 100;
    hp.value = j['hp'] ?? maxHp.value;
    xp.value = j['xp'] ?? 0;
    level.value = j['level'] ?? 1;
    gold.value = j['gold'] ?? 0;
    attack.value = j['attack'] ?? 10;
    // A save made at 0 HP should not resume dead.
    if (hp.value <= 0) hp.value = maxHp.value;
  }
}
