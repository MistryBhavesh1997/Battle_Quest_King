import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';
import '../controllers/toast_controller.dart';
import '../data/items.dart';

const _gold = Color(0xFFFFD54F);

// ---------------- Loading ----------------
class LoadingView extends StatefulWidget {
  const LoadingView({super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF0B1030),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.rotate(angle: sin(_c.value * 2 * pi) * 0.25, child: const Text('⚔️', style: TextStyle(fontSize: 40))),
            const SizedBox(height: 10),
            Text('Entering the kingdom${'.' * (1 + (_c.value * 3).floor())}',
                style: const TextStyle(color: Colors.white70, letterSpacing: 2)),
          ]),
        ),
      );
}

// ---------------- HUD ----------------
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({super.key, required this.value, required this.colors, this.width = 170, this.height = 12});
  final double value;
  final List<Color> colors;
  final double width, height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: Colors.white24),
        ),
        clipBehavior: Clip.antiAlias,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Align(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
          ),
        ),
      );
}

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<PlayerController>();
    final q = Get.find<QuestController>();
    final g = Get.find<GameController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Obx(() => Row(mainAxisSize: MainAxisSize.min, children: [
                    // Level badge pops whenever the level changes.
                    TweenAnimationBuilder<double>(
                      key: ValueKey(p.level.value),
                      tween: Tween(begin: 1.5, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (_, s, child) => Transform.scale(scale: s, child: child),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [_gold, Color(0xFFE08A00)]),
                        ),
                        child: Text('${p.level.value}',
                            style: const TextStyle(color: Color(0xFF3A2400), fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.favorite, color: Colors.redAccent, size: 13),
                        const SizedBox(width: 4),
                        Text('${p.hp.value}/${p.maxHp.value}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Text('🪙', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        _CountUp(value: p.gold.value),
                      ]),
                      const SizedBox(height: 4),
                      AnimatedBar(
                        value: p.hp.value / p.maxHp.value,
                        colors: p.hp.value / p.maxHp.value < 0.3
                            ? const [Color(0xFFFF8A80), Color(0xFFD50000)]
                            : const [Color(0xFFFF8A80), Color(0xFFE53935)],
                      ),
                      const SizedBox(height: 3),
                      AnimatedBar(
                        value: p.xp.value / p.xpToNext,
                        colors: const [Color(0xFF81D4FA), Color(0xFF1E88E5)],
                        height: 7,
                      ),
                    ]),
                  ])),
            ),
            const Spacer(),
            _RoundIcon(icon: Icons.backpack, onTap: g.toggleInventory),
            const SizedBox(width: 8),
            _RoundIcon(icon: Icons.save, onTap: g.saveGame),
          ]),
          const SizedBox(height: 8),
          // Quest tracker
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: q.quests.where((e) => !e.done.value).map((e) {
                  return _QuestChip(
                    key: ValueKey(e.id),
                    text: '📜 ${e.title}  ${e.progress.value}/${e.required}'
                        '${e.isReady ? '  — return to quest giver' : ''}',
                    ready: e.isReady,
                  );
                }).toList(),
              )),
        ]),
      ),
    );
  }
}

/// Number that rolls to its new value.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.toDouble()),
        duration: const Duration(milliseconds: 500),
        builder: (_, v, __) => Text('${v.round()}',
            style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 12)),
      );
}

class _QuestChip extends StatelessWidget {
  const _QuestChip({super.key, required this.text, required this.ready});
  final String text;
  final bool ready;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(-30 * (1 - v), 0), child: child),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ready ? Colors.lightGreenAccent : _gold.withValues(alpha: 0.6)),
          ),
          child: Text(text, style: TextStyle(color: ready ? Colors.lightGreenAccent : _gold, fontSize: 12)),
        ),
      );
}

class _RoundIcon extends StatefulWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_RoundIcon> createState() => _RoundIconState();
}

class _RoundIconState extends State<_RoundIcon> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.85 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 22),
          ),
        ),
      );
}

// ---------------- Action buttons ----------------
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final g = Get.find<GameController>();
    // Resolve `game.player` at tap time: the overlay can build before the world loads.
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            _ActionButton(
                label: 'TALK', icon: Icons.chat_bubble, color: Colors.teal, size: 66, onTap: () => g.game.player.interact()),
            const SizedBox(width: 14),
            _ActionButton(
                label: 'ATTACK', icon: Icons.flash_on, color: Colors.red, size: 84, onTap: () => g.game.player.attack()),
          ]),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton(
      {required this.label, required this.icon, required this.color, required this.size, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          setState(() => _down = true);
          widget.onTap();
        },
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.88 : 1,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                widget.color.withValues(alpha: _down ? 0.95 : 0.7),
                widget.color.withValues(alpha: _down ? 0.7 : 0.45),
              ]),
              border: Border.all(color: Colors.white54, width: 2),
              boxShadow: [BoxShadow(color: widget.color.withValues(alpha: _down ? 0.7 : 0.25), blurRadius: _down ? 16 : 8)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, color: Colors.white, size: widget.size * 0.34),
              Text(widget.label,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: widget.size * 0.14)),
            ]),
          ),
        ),
      );
}

// ---------------- Hit flash (red vignette) ----------------
class HitFlash extends StatelessWidget {
  const HitFlash({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<PlayerController>();
    return IgnorePointer(
      child: Obx(() {
        final tick = p.hitTick.value;
        return TweenAnimationBuilder<double>(
          key: ValueKey(tick), // new tick → restart the animation
          tween: Tween(begin: tick == 0 ? 0 : 1, end: 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (_, v, __) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.0,
                stops: const [0.5, 1],
                colors: [Colors.transparent, Colors.red.withValues(alpha: 0.6 * v)],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        );
      }),
    );
  }
}

// ---------------- Toasts ----------------
class ToastLayer extends StatelessWidget {
  const ToastLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Get.find<ToastController>();
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.75),
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [for (final m in t.toasts) _ToastTile(key: ValueKey(m.id), text: m.text)],
              )),
        ),
      ),
    );
  }
}

class _ToastTile extends StatefulWidget {
  const _ToastTile({super.key, required this.text});
  final String text;

  @override
  State<_ToastTile> createState() => _ToastTileState();
}

class _ToastTileState extends State<_ToastTile> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _c.reverse();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return FadeTransition(
      opacity: _c,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -0.8), end: Offset.zero).animate(a),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: 0.7)),
          ),
          child: Text(widget.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ---------------- Level up banner ----------------
class LevelUpBanner extends StatelessWidget {
  const LevelUpBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<PlayerController>();
    return IgnorePointer(
      child: Obx(() {
        final tick = p.levelUpTick.value;
        if (tick == 0) return const SizedBox.shrink();
        return TweenAnimationBuilder<double>(
          key: ValueKey(tick),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2200),
          builder: (_, t, __) {
            final opacity = t < 0.12 ? t / 0.12 : (t > 0.78 ? (1 - t) / 0.22 : 1.0);
            final scale = 0.5 + 0.5 * Curves.elasticOut.transform((t / 0.35).clamp(0.0, 1.0));
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -20 - 30 * t),
                  child: Transform.scale(
                    scale: scale,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF3B0), Color(0xFFF4B400)],
                        ).createShader(r),
                        child: const Text('LEVEL UP!',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 3))],
                            )),
                      ),
                      Text('You are now level ${p.level.value}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                    ]),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ---------------- Dialogue box ----------------
class DialogueBox extends StatelessWidget {
  const DialogueBox({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Get.find<DialogueController>();
    return Obx(() {
      if (!d.isOpen.value) return const SizedBox.shrink();
      return _DialogueShell(
        speaker: d.speaker.value,
        child: _Typewriter(
          // New key per line → typing restarts.
          key: ValueKey('${d.index.value}|${d.text}'),
          text: d.text,
          isLast: d.index.value >= d.lines.length - 1,
          onNext: d.next,
        ),
      );
    });
  }
}

/// Slides in once when the conversation starts; persists across lines.
class _DialogueShell extends StatelessWidget {
  const _DialogueShell({required this.speaker, required this.child});
  final String speaker;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 60 * (1 - v)), child: c),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  border: Border.all(color: _gold, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16)],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(speaker, style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  child,
                ]),
              ),
            ),
          ),
        ),
      );
}

class _Typewriter extends StatefulWidget {
  const _Typewriter({super.key, required this.text, required this.isLast, required this.onNext});
  final String text;
  final bool isLast;
  final VoidCallback onNext;

  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 25 * widget.text.length.clamp(1, 200)),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _c.isCompleted ? widget.onNext() : _c.value = 1, // tap: skip typing, then advance
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final n = (widget.text.length * _c.value).round();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Invisible full text reserves the final height so the box doesn't jump.
              Stack(children: [
                Opacity(opacity: 0, child: Text(widget.text, style: const TextStyle(fontSize: 16))),
                Text(widget.text.substring(0, n), style: const TextStyle(color: Colors.white, fontSize: 16)),
              ]),
              Align(
                alignment: Alignment.bottomRight,
                child: _c.isCompleted ? _BlinkingHint(isLast: widget.isLast) : const SizedBox(height: 16),
              ),
            ]);
          },
        ),
      );
}

class _BlinkingHint extends StatefulWidget {
  const _BlinkingHint({required this.isLast});
  final bool isLast;

  @override
  State<_BlinkingHint> createState() => _BlinkingHintState();
}

class _BlinkingHintState extends State<_BlinkingHint> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
        child: Text(widget.isLast ? 'tap to close ✕' : 'tap ▶', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      );
}

// ---------------- Inventory ----------------
class InventoryPanel extends StatelessWidget {
  const InventoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = Get.find<InventoryController>();
    final g = Get.find<GameController>();
    return GestureDetector(
      onTap: g.toggleInventory,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Container(
          color: Colors.black.withValues(alpha: 0.6 * v.clamp(0.0, 1.0)),
          alignment: Alignment.center,
          child: Transform.scale(scale: 0.8 + 0.2 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
        ),
        child: GestureDetector(
          onTap: () {}, // swallow taps on the panel itself
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withValues(alpha: 0.6)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Text('🎒  Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: g.toggleInventory),
              ]),
              Obx(() {
                if (inv.items.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(16), child: Text('Your bag is empty'));
                }
                return Column(
                  children: inv.items.entries.map((e) {
                    final item = Items.all[e.key];
                    return ListTile(
                      dense: true,
                      leading: Image.asset('assets/images/${item?.icon ?? 'potion.png'}',
                          width: 28, filterQuality: FilterQuality.none),
                      title: Text('${item?.name ?? e.key} × ${e.value}'),
                      trailing: item?.type == ItemType.potion
                          ? FilledButton.tonal(onPressed: () => inv.use(e.key), child: const Text('Use'))
                          : null,
                    );
                  }).toList(),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------- Game over ----------------
class GameOverView extends StatelessWidget {
  const GameOverView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<PlayerController>();
    final g = Get.find<GameController>();
    return Obx(() {
      if (!p.isDead) return const SizedBox.shrink();
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Container(
          color: Colors.black.withValues(alpha: 0.85 * v),
          alignment: Alignment.center,
          child: Opacity(
            opacity: v,
            child: Transform.scale(
              scale: 1.4 - 0.4 * v,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('YOU WERE DEFEATED',
                    style: TextStyle(fontSize: 34, color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: g.respawn, icon: const Icon(Icons.replay), label: const Text('Respawn')),
              ]),
            ),
          ),
        ),
      );
    });
  }
}
