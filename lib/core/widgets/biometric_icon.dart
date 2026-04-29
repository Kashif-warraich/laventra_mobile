import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Combined face-scan (left half) + fingerprint (right half) icon used as
/// the alternate sign-in button on the Login screen. Pure CustomPainter.
class BiometricIcon extends StatelessWidget {
  final double size;
  final Color  color;
  final bool   active;

  const BiometricIcon({
    super.key,
    this.size   = 56,
    this.color  = AppTokens.ts,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = active ? AppTokens.blue : color;
    return SizedBox(
      width:  size,
      height: size,
      child:  CustomPaint(painter: _BiometricPainter(c)),
    );
  }
}

class _BiometricPainter extends CustomPainter {
  final Color color;
  _BiometricPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color       = color
      ..strokeWidth = 2
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;

    final dotPaint = Paint()..color = color;

    final w = s.width;
    final h = s.height;
    final cx = w / 2;
    final cy = h / 2;
    final r  = (w / 2) - 2;

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), r, stroke);
    // Center divider
    canvas.drawLine(Offset(cx, cy - r + 4), Offset(cx, cy + r - 4), stroke);

    // ── Left half: face scan ──
    // L-corner brackets (outer 4 corners of the face square)
    final inset = r * 0.42;
    final cornerLen = r * 0.18;
    // Top-left
    canvas.drawLine(Offset(cx - inset, cy - inset),
                    Offset(cx - inset + cornerLen, cy - inset), stroke);
    canvas.drawLine(Offset(cx - inset, cy - inset),
                    Offset(cx - inset, cy - inset + cornerLen), stroke);
    // Bottom-left
    canvas.drawLine(Offset(cx - inset, cy + inset),
                    Offset(cx - inset + cornerLen, cy + inset), stroke);
    canvas.drawLine(Offset(cx - inset, cy + inset),
                    Offset(cx - inset, cy + inset - cornerLen), stroke);
    // Eye dots
    canvas.drawCircle(Offset(cx - inset * 0.55, cy - inset * 0.25), 1.6, dotPaint);
    // Smile
    final smile = Path()
      ..moveTo(cx - inset * 0.85, cy + inset * 0.15)
      ..quadraticBezierTo(cx - inset * 0.45, cy + inset * 0.55, cx - inset * 0.10, cy + inset * 0.15);
    canvas.drawPath(smile, stroke);

    // ── Right half: fingerprint ──
    // Concentric arcs radiating from a virtual core off-center
    final coreX = cx + inset * 0.55;
    final coreY = cy - inset * 0.05;
    for (int i = 0; i < 4; i++) {
      final radius = (r * 0.18) + (i * (r * 0.10));
      canvas.drawArc(
        Rect.fromCircle(center: Offset(coreX, coreY), radius: radius),
        -3.14159 * 0.15,
        -3.14159 * 0.85,
        false,
        stroke,
      );
    }
    // A couple of lower flow lines
    final flow1 = Path()
      ..moveTo(cx + inset * 0.10, cy + inset * 0.55)
      ..quadraticBezierTo(coreX, cy + inset * 0.85, cx + inset * 0.95, cy + inset * 0.55);
    canvas.drawPath(flow1, stroke);
    canvas.drawCircle(Offset(coreX, coreY), 1.6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _BiometricPainter old) => old.color != color;
}
