import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import 'overlays.dart';

class GameScreen extends GetView<GameController> {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: controller.game,
        loadingBuilder: (_) => const LoadingView(),
        errorBuilder: (_, e) => Center(child: Text('Failed to load: $e')),
        overlayBuilderMap: {
          'hud': (_, __) => const Hud(),
          'actions': (_, __) => const ActionButtons(),
          'hitFlash': (_, __) => const HitFlash(),
          'toasts': (_, __) => const ToastLayer(),
          'levelUp': (_, __) => const LevelUpBanner(),
          'dialogue': (_, __) => const DialogueBox(),
          'inventory': (_, __) => const InventoryPanel(),
          'gameOver': (_, __) => const GameOverView(),
        },
        // dialogue, toasts & gameOver show/hide themselves with Obx.
        initialActiveOverlays: const [
          'hud', 'actions', 'hitFlash', 'toasts', 'levelUp', 'dialogue', 'gameOver',
        ],
      ),
    );
  }
}
