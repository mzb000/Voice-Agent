import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Siri-style waveform bars.
class VoiceOrbBars extends StatefulWidget {
  const VoiceOrbBars({
    super.key,
    required this.amplitude,
    required this.active,
    this.size = 260,
    this.barCount = 28,
  });

  final double amplitude;
  final bool active;
  final double size;
  final int barCount;

  @override
  State<VoiceOrbBars> createState() => _VoiceOrbBarsState();
}

class _VoiceOrbBarsState extends State<VoiceOrbBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
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
          painter: _BarsPainter(
            t: _c.value,
            amplitude: widget.amplitude,
            active: widget.active,
            count: widget.barCount,
          ),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.t,
    required this.amplitude,
    required this.active,
    required this.count,
  });
  final double t;
  final double amplitude;
  final bool active;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.42;

    // Halo
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withOpacity(0.35 + amplitude * 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(center, radius * 1.4, halo);

    // Ring
    final ring = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, ring);

    // Bars radially
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final phase = t * 2 * math.pi + i * 0.4;
      final baseLen = 8 + amplitude * 60;
      final wave = 0.5 + 0.5 * math.sin(phase);
      final len = baseLen * (0.4 + wave * (0.6 + amplitude));
      final startR = radius * 0.88;
      final endR = startR + len;

      final p1 = center + Offset(math.cos(angle) * startR, math.sin(angle) * startR);
      final p2 = center + Offset(math.cos(angle) * endR, math.sin(angle) * endR);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: const [AppColors.accent, AppColors.accent2, AppColors.accent3],
          transform: GradientRotation(angle),
        ).createShader(Rect.fromPoints(p1, p2))
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;
      canvas.drawLine(p1, p2, paint);
    }

    // Center dot
    final dot = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, AppColors.accent.withOpacity(0.4), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5));
    canvas.drawCircle(center, radius * 0.5, dot);
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.t != t || old.amplitude != amplitude || old.active != active;
}
