import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/save_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

  @override
  void dispose() {
    _ambient.dispose();
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _step(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

  @override
  Widget build(BuildContext context) {
    final save = Get.find<SaveService>();
    final crown = _step(0.0, 0.45, Curves.elasticOut);
    final title = _step(0.15, 0.6, Curves.easeOutBack);
    final tagline = _step(0.45, 0.7);
    final btn1 = _step(0.6, 0.85, Curves.easeOutBack);
    final btn2 = _step(0.7, 0.95, Curves.easeOutBack);

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // Sky, stars, embers and castle silhouette.
        AnimatedBuilder(
          animation: _ambient,
          builder: (_, __) => CustomPaint(painter: _SkyPainter(_ambient.value)),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _Pop(
                  anim: crown,
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, sin(_ambient.value * 2 * pi * 20) * 4),
                      child: child,
                    ),
                    child: const Text('👑', style: TextStyle(fontSize: 52)),
                  ),
                ),
                _Pop(
                  anim: title,
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF3B0), Color(0xFFF4B400), Color(0xFFB8741A)],
                    ).createShader(r),
                    child: const Text(
                      'QUEST OF KINGS',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeTransition(
                  opacity: tagline,
                  child: const Text(
                    'A LEGEND AWAITS',
                    style: TextStyle(color: Colors.white70, letterSpacing: 8, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 28),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _Pop(
                    anim: btn1,
                    child: _MenuButton(
                      label: 'NEW GAME',
                      icon: Icons.auto_awesome,
                      glow: _ambient,
                      onTap: () async {
                        await save.newGame();
                        Get.offNamed('/game');
                      },
                    ),
                  ),
                  const SizedBox(width: 18),
                  _Pop(
                    anim: btn2,
                    child: _MenuButton(
                      label: 'CONTINUE',
                      icon: Icons.play_arrow_rounded,
                      glow: _ambient,
                      enabled: save.hasSave,
                      onTap: () => Get.offNamed('/game'),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Fade + slide-up + scale driven by an animation.
class _Pop extends StatelessWidget {
  const _Pop({required this.anim, required this.child});
  final Animation<double> anim;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        builder: (_, child) => Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 24),
            child: Transform.scale(scale: 0.8 + 0.2 * anim.value, child: child),
          ),
        ),
        child: child,
      );
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.glow,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Animation<double> glow;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return GestureDetector(
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: on
          ? (_) {
              setState(() => _down = false);
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.93 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedBuilder(
          animation: widget.glow,
          builder: (_, child) {
            final pulse = 0.5 + 0.5 * sin(widget.glow.value * 2 * pi * 40);
            return Container(
              width: 170,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: on
                      ? const [Color(0xFFFFD54F), Color(0xFFE08A00)]
                      : const [Color(0xFF555566), Color(0xFF3B3B4A)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: on ? 0.6 : 0.15), width: 1.5),
                boxShadow: on
                    ? [BoxShadow(color: const Color(0xFFFFB300).withValues(alpha: 0.25 + pulse * 0.3), blurRadius: 12 + pulse * 10)]
                    : null,
              ),
              child: child,
            );
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, color: on ? const Color(0xFF3A2400) : Colors.white38, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: on ? const Color(0xFF3A2400) : Colors.white38,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t);
  final double t; // 0..1, loops every 20s – all motion uses integer cycle counts so it loops seamlessly

  static final _rnd = Random(3);
  static final _stars = List.generate(
      70, (_) => (_rnd.nextDouble(), _rnd.nextDouble() * 0.7, _rnd.nextDouble(), 8 + _rnd.nextInt(16), 0.6 + _rnd.nextDouble() * 1.6));
  static final _embers = List.generate(
      28, (_) => (_rnd.nextDouble(), _rnd.nextDouble(), 1 + _rnd.nextInt(3), 3 + _rnd.nextInt(5), 1 + _rnd.nextDouble() * 1.6));

  @override
  void paint(Canvas canvas, Size s) {
    // Sky
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1030), Color(0xFF2A1B54), Color(0xFF8A3B5C), Color(0xFFE88A4A)],
          stops: [0, 0.45, 0.78, 1],
        ).createShader(Offset.zero & s),
    );

    // Stars twinkle
    for (final (x, y, phase, freq, r) in _stars) {
      final a = 0.35 + 0.65 * (0.5 + 0.5 * sin(2 * pi * (t * freq + phase)));
      canvas.drawCircle(Offset(x * s.width, y * s.height), r, Paint()..color = Colors.white.withValues(alpha: a));
    }

    // Moon with soft halo
    final moon = Offset(s.width * 0.82, s.height * 0.2);
    canvas.drawCircle(moon, 48, Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
    canvas.drawCircle(moon, 22, Paint()..color = const Color(0xFFFFF3C4));

    // Castle silhouette
    final ground = s.height * 0.86;
    final castle = Paint()..color = const Color(0xFF120A24);
    final cx = s.width * 0.5;
    final u = s.height / 18;
    void tower(double x, double w, double h) {
      canvas.drawRect(Rect.fromLTWH(x, ground - h, w, h), castle);
      final merlon = w / 5;
      for (var i = 0; i < 5; i += 2) {
        canvas.drawRect(Rect.fromLTWH(x + i * merlon, ground - h - u * 0.5, merlon, u * 0.5), castle);
      }
    }

    tower(cx - u * 7, u * 3, u * 6);
    tower(cx - u * 2.5, u * 5, u * 8);
    tower(cx + u * 4, u * 3, u * 6);
    canvas.drawRect(Rect.fromLTWH(cx - u * 4, ground - u * 3, u * 8, u * 3), castle);
    final peak = Path()
      ..moveTo(cx - u * 2.8, ground - u * 8.5)
      ..lineTo(cx, ground - u * 12)
      ..lineTo(cx + u * 2.8, ground - u * 8.5)
      ..close();
    canvas.drawPath(peak, castle);
    // Lit windows flicker
    final flick = 0.6 + 0.4 * sin(2 * pi * t * 37);
    canvas.drawRect(Rect.fromLTWH(cx - u * 0.4, ground - u * 6.5, u * 0.8, u * 1.2), Paint()..color = const Color(0xFFFFC857).withValues(alpha: flick));
    canvas.drawRect(Rect.fromLTWH(cx - u * 6, ground - u * 4.5, u * 0.6, u), Paint()..color = const Color(0xFFFFC857).withValues(alpha: 1.1 - flick));
    canvas.drawRect(Rect.fromLTWH(cx + u * 5.2, ground - u * 4.5, u * 0.6, u), Paint()..color = const Color(0xFFFFC857).withValues(alpha: flick));

    // Hills
    canvas.drawRect(Rect.fromLTWH(0, ground, s.width, s.height - ground), Paint()..color = const Color(0xFF0B0618));

    // Rising embers
    for (final (x, phase, speed, sway, r) in _embers) {
      final p = (t * speed + phase) % 1.0;
      final px = x * s.width + sin(2 * pi * (t * sway + phase)) * 18;
      final py = ground - p * s.height * 0.8;
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()..color = const Color(0xFFFFB74D).withValues(alpha: (1 - p) * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t;
}
