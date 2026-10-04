import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:questkings/controllers/player_controller.dart';

void main() {
  setUp(Get.reset);

  test('gaining enough XP levels the player up and fully heals', () {
    final p = Get.put(PlayerController());
    p.takeDamage(40);
    p.gainXp(120); // lvl1 needs 50, lvl2 needs 100 → ends level 2 with 70 xp

    expect(p.level.value, 2);
    expect(p.xp.value, 70);
    expect(p.hp.value, p.maxHp.value);
    expect(p.levelUpTick.value, 1);
  });

  test('damage never drops below zero and bumps the hit tick', () {
    final p = Get.put(PlayerController());
    p.takeDamage(500);
    expect(p.hp.value, 0);
    expect(p.isDead, isTrue);
    expect(p.hitTick.value, 1);
  });
}
