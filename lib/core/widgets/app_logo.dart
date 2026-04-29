import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Hexagon car-wash logo. Pure CustomPainter — no asset files.
///
/// Mirrors the design's [`AppLogo`] SVG: hexagon outline with a teal-blue
/// gradient stroke, a stylized car silhouette, water-drop spray on top,
/// brush rollers on the sides, and a teal scan line crossing the car.
class AppLogo extends StatelessWidget {
  final double size;
  final bool   showBg;

  const AppLogo({super.key, this.size = 60, this.showBg = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size,
      height: size,
      child:  CustomPaint(painter: _AppLogoPainter(showBg: showBg)),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  final bool showBg;
  _AppLogoPainter({required this.showBg});

  @override
  void paint(Canvas canvas, Size s) {
    // Logo is designed in a 200x200 viewbox — scale to whatever size is requested.
    final scale = s.width / 200;
    canvas.scale(scale, scale);

    if (showBg) {
      final bgRect  = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 200, 200),
        const Radius.circular(44),
      );
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF0D1F38), Color(0xFF060E1C)],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 200));
      canvas.drawRRect(bgRect, bgPaint);
    }

    // Hexagon stroke gradient
    final hexPath = Path()
      ..moveTo(100, 18)
      ..lineTo(162, 52)
      ..lineTo(162, 148)
      ..lineTo(100, 182)
      ..lineTo(38, 148)
      ..lineTo(38, 52)
      ..close();

    final hexPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin  = StrokeJoin.round
      ..shader      = const LinearGradient(
        begin:  Alignment.topLeft,
        end:    Alignment.bottomRight,
        colors: [AppTokens.blue, AppTokens.tealL, AppTokens.teal],
      ).createShader(const Rect.fromLTWH(38, 18, 124, 164));
    canvas.drawPath(hexPath, hexPaint);

    // ── Brush rollers (left + right) ──
    final rollerPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap   = StrokeCap.round
      ..color       = AppTokens.ts;
    for (final y in [86.0, 100.0, 114.0]) {
      canvas.drawLine(Offset(56, y),  Offset(72, y),  rollerPaint);
      canvas.drawLine(Offset(128, y), Offset(144, y), rollerPaint);
    }

    // ── Car body (front view) ──
    final carPaint = Paint()
      ..shader = const LinearGradient(
        begin:  Alignment.topCenter,
        end:    Alignment.bottomCenter,
        colors: [Color(0xFFC8D8EE), Color(0xFF8AAAC8)],
      ).createShader(const Rect.fromLTWH(76, 80, 48, 50));

    // Cabin (rounded top)
    final cabinPath = Path()
      ..moveTo(82, 105)
      ..quadraticBezierTo(82, 80, 100, 80)
      ..quadraticBezierTo(118, 80, 118, 105)
      ..close();
    canvas.drawPath(cabinPath, carPaint);

    // Body (lower box)
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(76, 105, 48, 25),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, carPaint);

    // Headlights
    final headlight = Paint()..color = const Color(0xFFFFE08A);
    canvas.drawCircle(const Offset(83, 122), 2.5, headlight);
    canvas.drawCircle(const Offset(117, 122), 2.5, headlight);

    // Windshield highlight
    final winPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(88, 96), const Offset(112, 96), winPaint);

    // ── Scan line (teal dashed) ──
    final scanPaint = Paint()
      ..color       = AppTokens.teal
      ..strokeWidth = 1.6
      ..strokeCap   = StrokeCap.round;
    const dashWidth = 4.0;
    const dashGap   = 3.0;
    double x = 60;
    while (x < 140) {
      canvas.drawLine(Offset(x, 110), Offset(x + dashWidth, 110), scanPaint);
      x += dashWidth + dashGap;
    }

    // ── License plate ──
    final platePaint = Paint()
      ..color = AppTokens.teal.withOpacity(0.9);
    final plateRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(82, 134, 36, 9),
      const Radius.circular(2),
    );
    canvas.drawRRect(plateRect, platePaint);
    final slotPaint = Paint()..color = AppTokens.bg;
    for (final dx in [86.0, 92.0, 98.0, 104.0, 110.0]) {
      canvas.drawRect(Rect.fromLTWH(dx, 137, 3.5, 3), slotPaint);
    }

    // ── Water drops above the hexagon ──
    final dropPaint = Paint()
      ..shader = const LinearGradient(
        begin:  Alignment.topCenter,
        end:    Alignment.bottomCenter,
        colors: [Color(0xFF5BBAFF), AppTokens.blue],
      ).createShader(const Rect.fromLTWH(60, 30, 80, 30));

    final drops = <Offset>[
      const Offset(72, 50),  const Offset(85, 42),  const Offset(98, 38),
      const Offset(115, 40), const Offset(128, 48), const Offset(140, 56),
      const Offset(64, 62),  const Offset(80, 66),  const Offset(120, 64),
      const Offset(136, 70),
    ];
    for (final o in drops) {
      final d = Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(o.dx + 3, o.dy + 4, o.dx, o.dy + 7)
        ..quadraticBezierTo(o.dx - 3, o.dy + 4, o.dx, o.dy)
        ..close();
      canvas.drawPath(d, dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter old) => old.showBg != showBg;
}
