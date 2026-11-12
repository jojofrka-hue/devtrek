import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight confetti implemented with a CustomPainter (no extra packages).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.trigger = 0});

  final int trigger;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;

  static const _colors = [
    Color(0xFF58CC02),
    Color(0xFF1CB0F6),
    Color(0xFFFF9600),
    Color(0xFFFF4B8B),
    Color(0xFF7A5CFF),
    Color(0xFFFFC800),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _particles = _buildParticles();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _particles = _buildParticles();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _buildParticles() {
    final random = math.Random();
    return List<_Particle>.generate(70, (index) {
      return _Particle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        speed: 0.75 + random.nextDouble() * 0.6,
        phase: random.nextDouble() * math.pi * 2,
        rotation: random.nextDouble() * math.pi,
        size: 6 + random.nextDouble() * 8,
        color: _colors[index % _colors.length],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.phase,
    required this.rotation,
    required this.size,
    required this.color,
  });

  final double x;
  final double delay;
  final double speed;
  final double phase;
  final double rotation;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final particle in particles) {
      final local = ((progress - particle.delay) / (1 - particle.delay))
          .clamp(0.0, 1.0);
      if (local <= 0) continue;

      final dy = -40 + (size.height + 80) * local * particle.speed;
      final dx =
          particle.x * size.width +
          math.sin(local * 7 + particle.phase) * 26;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(particle.rotation + local * 9);
      paint.color = particle.color.withValues(
        alpha: (1 - local).clamp(0.0, 1.0),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.55,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
