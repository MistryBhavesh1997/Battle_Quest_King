import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/quest_controller.dart';
import 'rpg_game.dart';

class Npc extends SpriteComponent with HasGameReference<RpgGame> {
  Npc({
    required this.npcName,
    required this.lines,
    required super.position,
    this.questId,
    this.spriteFile = 'npc.png',
  }) : super(size: Vector2.all(32), anchor: Anchor.center, priority: 5);

  final String npcName, spriteFile;
  final List<String> lines;
  final String? questId;
  double _t = 0;

  @override
  Future<void> onLoad() async => sprite = await game.loadSprite(spriteFile);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    scale.y = 1 + sin(_t * 2.2) * 0.025; // gentle breathing
  }

  /// '!' when a quest can be taken, '?' when it can be handed in.
  String? get _marker {
    if (questId == null) return null;
    final quest = Get.find<QuestController>().byId(questId!);
    if (quest == null) return '!';
    if (quest.isReady) return '?';
    return null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final m = _marker;
    if (m == null) return;
    final bounce = sin(_t * 4).abs() * 4;
    TextPaint(
      style: TextStyle(
        color: m == '!' ? const Color(0xFFFFD54F) : const Color(0xFF80DEEA),
        fontSize: 16,
        fontWeight: FontWeight.w900,
        shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1))],
      ),
    ).render(canvas, m, Vector2(size.x / 2, -4 - bounce), anchor: Anchor.center);
  }

  void onInteract() {
    final d = Get.find<DialogueController>();
    final qc = Get.find<QuestController>();

    if (questId == null) {
      d.start(npcName, lines);
      return;
    }

    final quest = qc.byId(questId!);
    if (quest == null) {
      d.start(npcName, lines, onEnd: () => qc.accept(questId!));
    } else if (quest.isReady) {
      d.start(npcName, ['You did it, hero!', 'Please take this reward.'],
          onEnd: () => qc.complete(questId!));
    } else if (quest.done.value) {
      d.start(npcName, ['The village is safe thanks to you.']);
    } else {
      final left = quest.required - quest.progress.value;
      d.start(npcName, ['Still $left more to go. Be careful out there!']);
    }
  }
}
