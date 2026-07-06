import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 3D-looking particle sphere.
class VoiceOrbParticles extends StatefulWidget {
  const VoiceOrbParticles({
    super.key,
    required this.amplitude,
    required this.active,
    this.size = 260,
    this.count = 140,
  });

  final double amplitude;
  final bool active;
  final double size;
  final int count;

  @override
  State<VoiceOrbParticles> createState() => _VoiceOrbParticlesState();
}

class _VoiceOrbParticlesState extends State<VoiceOrbParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_P> _points;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    final rand = math.Random(42);
    _points = List.generate(widget.count, (i) {
      // Fibonacci sphere for even distribution
      final k = i + 0.5;
      final phi = math.acos(1 - 2 * k / widget.count);
      final theta = math.pi * (1 + math.sqrt(5)) * k;
      return _P(theta: theta, phi: phi, jitter: rand.nextDouble());
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _PPainter(
            t: _c.value,
            amplitude: widget.amplitude,
            active: widget.active,
            points: _points,
          ),
        );
      },
    );
  }
}

class _P {
  final double theta;
  final double phi;
  final double jitter;
  _P({required this.theta, required this.phi, required this.jitter});
}

class _PPainter extends CustomPainter {
  _PPainter({
    required this.t,
    required this.amplitude,
    required this.active,
    required this.points,
  });
  final double t;
  final double amplitude;
  final bool active;
  final List<_P> points;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width * 0.34 * (1 + amplitude * 0.15);

    // glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withOpacity(0.4 + amplitude * 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.7))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, r * 1.7, glow);

    final rotY = t * 2 * math.pi;
    final rotX = math.sin(t * 2 * math.pi) * 0.4;

    // sort by z so nearer particles draw on top
    final projected = <_Projected>[];
    for (final p in points) {
      final wobble = 1 + amplitude * 0.18 * math.sin(p.jitter * 20 + t * 6);
      final rr = r * wobble;
      final x = rr * math.sin(p.phi) * math.cos(p.theta + rotY);
      final y0 = rr * math.cos(p.phi);
      final z0 = rr * math.sin(p.phi) * math.sin(p.theta + rotY);
      // rotate around X axis
      final y = y0 * math.cos(rotX) - z0 * math.sin(rotX);
      final z = y0 * math.sin(rotX) + z0 * math.cos(rotX);
      projected.add(_Projected(x: x, y: y, z: z));
    }
    projected.sort((a, b) => a.z.compareTo(b.z));

    for (final pr in projected) {
      final depth = (pr.z + r) / (2 * r); // 0..1 (1 = near)
      final radius = 1.4 + depth * 2.6 * (1 + amplitude * 0.5);
      final c1 = Color.lerp(AppColors.accent2, AppColors.accent3, depth)!;
      final paint = Paint()
        ..color = c1.withOpacity(0.35 + depth * 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.6 + (1 - depth) * 1.5);
      canvas.drawCircle(center + Offset(pr.x, pr.y), radius, paint);
    }

    // core
    final core = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.85), AppColors.accent.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.5));
    canvas.drawCircle(center, r * 0.5, core);
  }

  @override
  bool shouldRepaint(_PPainter old) =>
      old.t != t || old.amplitude != amplitude || old.active != active;
}

class _Projected {
  final double x, y, z;
  _Projected({required this.x, required this.y, required this.z});
}
