import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Morphing blob with mic-reactive glow.
class VoiceOrbBlob extends StatefulWidget {
  const VoiceOrbBlob({
    super.key,
    required this.amplitude,
    required this.active,
    this.size = 260,
  });

  final double amplitude; // 0..1
  final bool active;
  final double size;

  @override
  State<VoiceOrbBlob> createState() => _VoiceOrbBlobState();
}

class _VoiceOrbBlobState extends State<VoiceOrbBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
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
          painter: _BlobPainter(
            t: _c.value,
            amplitude: widget.amplitude,
            active: widget.active,
          ),
        );
      },
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.t, required this.amplitude, required this.active});
  final double t;
  final double amplitude;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseR = size.width * 0.32;
    final wobble = 0.08 + amplitude * 0.22;

    // Outer glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withOpacity(0.55 + amplitude * 0.3),
          AppColors.accent2.withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, size.width / 2, glow);

    // Multiple morphing rings
    for (int i = 0; i < 3; i++) {
      final phase = t * 2 * math.pi + i * (math.pi / 3);
      final ringR = baseR + i * 6;
      final path = Path();
      const steps = 60;
      for (int s = 0; s <= steps; s++) {
        final a = (s / steps) * 2 * math.pi;
        final r = ringR *
            (1 +
                wobble * math.sin(a * 3 + phase) +
                wobble * 0.6 * math.cos(a * 5 - phase * 1.3));
        final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
        if (s == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();

      final paint = Paint()
        ..shader = SweepGradient(
          colors: const [
            AppColors.accent,
            AppColors.accent2,
            AppColors.accent3,
            AppColors.accent,
          ],
          transform: GradientRotation(phase),
        ).createShader(Rect.fromCircle(center: center, radius: ringR))
        ..style = i == 0 ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..maskFilter =
            i == 0 ? const MaskFilter.blur(BlurStyle.normal, 6) : null;
      if (i == 0) paint.color = Colors.white.withOpacity(0.15);
      canvas.drawPath(path, paint);
    }

    // Bright core highlight
    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          AppColors.accent.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseR * 0.4));
    canvas.drawCircle(center, baseR * 0.4, core);
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.t != t || old.amplitude != amplitude || old.active != active;
}
