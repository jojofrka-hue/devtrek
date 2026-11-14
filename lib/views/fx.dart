import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mouse hover micro-interaction: gently scales the child and lifts it
/// with a colored shadow while the pointer is inside.
class HoverScale extends StatefulWidget {
  const HoverScale({
    super.key,
    required this.child,
    this.hoverScale = 1.02,
    this.glow,
    this.radius = 18,
    this.duration = const Duration(milliseconds: 140),
  });

  final Widget child;
  final double hoverScale;
  final Color? glow;
  final double radius;
  final Duration duration;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? widget.hoverScale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: widget.duration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: _hovering && widget.glow != null
                ? [
                    BoxShadow(
                      color: widget.glow!.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Neon-style glow border used to mark the active learning path.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.color,
    required this.child,
    this.active = false,
    this.radius = 18,
  });

  final Color color;
  final Widget child;
  final bool active;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.85 : 0.45),
          width: active ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: active ? 0.35 : 0.16),
            blurRadius: active ? 26 : 14,
            spreadRadius: active ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Smoothly animated linear progress bar (tweens between value changes).
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.value,
    required this.color,
    this.background,
    this.height = 7,
    this.duration = const Duration(milliseconds: 650),
  });

  final double value;
  final Color color;
  final Color? background;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final fallback = Theme.of(context).dividerColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => LinearProgressIndicator(
          value: animated,
          minHeight: height,
          backgroundColor: background ?? fallback,
          color: color,
        ),
      ),
    );
  }
}

/// Animated progress ring; shows [center] inside the ring.
class AnimatedRing extends StatelessWidget {
  const AnimatedRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 46,
    this.stroke = 4.5,
    this.background,
    this.center,
    this.duration = const Duration(milliseconds: 700),
  });

  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Color? background;
  final Widget? center;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final fallback = Theme.of(context).dividerColor;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, animated, child) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: animated,
              strokeWidth: stroke,
              backgroundColor: background ?? fallback,
              color: color,
            ),
            if (child != null) Center(child: child),
          ],
        ),
        child: center,
      ),
    );
  }
}

/// Subtle horizontal shake, replayed whenever [trigger] changes to true.
/// Used on cards surfaces for wrong-answer style feedback.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final bool trigger;
  final Widget child;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Current horizontal offset; exposed for tests and the painter.
  double get offset => _shakeAt(_controller.value);

  static double _shakeAt(double t) {
    if (t <= 0 || t >= 1) return 0;
    final decay = 1 - t;
    return math.sin(t * math.pi * 6) * 5 * decay;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.translate(offset: Offset(offset, 0), child: child),
      child: widget.child,
    );
  }
}

/// Fires a full-screen confetti/particle burst with a neon glow flash.
/// Hand-built with [Overlay] + [CustomPainter] — no external packages.
class ConfettiBurst {
  const ConfettiBurst._();

  static final math.Random _random = math.Random();

  static void celebrate(BuildContext context, {List<Color>? colors}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final palette =
        colors ??
        const [
          Color(0xFF7EE02E),
          Color(0xFFFFC800),
          Color(0xFF1CB0F6),
          Color(0xFF7A5CFF),
          Color(0xFFFF7A00),
        ];
    final particles = List<_Particle>.generate(46, (i) {
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * 1.5;
      final speed = 420 + _random.nextDouble() * 520;
      return _Particle(
        x: 0.15 + _random.nextDouble() * 0.7,
        color: palette[i % palette.length],
        dx: math.cos(angle) * speed * (_random.nextDouble() + 0.35),
        dy: math.sin(angle) * speed,
        size: 4 + _random.nextDouble() * 5,
        spin: (_random.nextDouble() - 0.5) * 14,
      );
    });

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: _BurstLayer(particles: particles, onDone: () => entry.remove()),
      ),
    );
    overlay.insert(entry);
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.color,
    required this.dx,
    required this.dy,
    required this.size,
    required this.spin,
  });

  final double x;
  final Color color;
  final double dx;
  final double dy;
  final double size;
  final double spin;
}

class _BurstLayer extends StatefulWidget {
  const _BurstLayer({required this.particles, required this.onDone});

  final List<_Particle> particles;
  final VoidCallback onDone;

  @override
  State<_BurstLayer> createState() => _BurstLayerState();
}

class _BurstLayerState extends State<_BurstLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _BurstPainter(
          particles: widget.particles,
          t: _controller.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.particles, required this.t});

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Neon glow flash, strongest at the start.
    final glowAlpha = (1 - t) * 0.14;
    if (glowAlpha > 0.004) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF7EE02E).withValues(alpha: glowAlpha),
      );
    }
    final gravity = 900.0;
    final originY = size.height * 0.42;
    for (final p in particles) {
      final x = p.x * size.width + p.dx * t;
      final y = originY + p.dy * t + 0.5 * gravity * t * t;
      final alpha = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 1.6,
          ),
          Radius.circular(p.size * 0.35),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.t != t;
}
