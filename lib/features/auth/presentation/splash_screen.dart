import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/theme/app_tokens.dart';

/// Splash: the car-wash bay scene from the Laventra design.
///
/// A muddy car drives into the bay under the gradient arch + spray bar, the
/// mud washes off (mud → fog → gleam → sparkles), then it rolls out and the
/// cycle repeats while we wait on auth. Faithful port of `Laventra Splash.html`.
///
/// Auth flow (unchanged):
///   AuthStarted is dispatched shortly after entry; the router redirect handles
///   the unauthenticated → /login transition. When biometric login is enabled
///   the BLoC emits AuthBiometricRequired and we trigger the prompt immediately.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _loop; // one wash cycle (compressed from 9s → 6s)

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _loop  = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.read<AuthBloc>().add(const AuthStarted());
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media   = MediaQuery.of(context);
    final sceneW  = (media.size.width * 0.92).clamp(280.0, 520.0);
    final sceneH  = sceneW * 9 / 16;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Trigger Face ID / fingerprint prompt — the BLoC drives the result.
        if (state is AuthBiometricRequired) {
          context.read<AuthBloc>().add(const AuthBiometricRequested());
        }
      },
      child: Scaffold(
        backgroundColor: AppTokens.bg,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1.0),
              radius: 1.2,
              colors: [Color(0xFF0D1F38), Color(0xFF060E1C), Color(0xFF03070F)],
              stops:  [0.0, 0.6, 1.0],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(
                  CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WashScene(loop: _loop, width: sceneW, height: sceneH),
                    const SizedBox(height: 24),
                    const _Wordmark(),
                    const SizedBox(height: 10),
                    const _Tagline(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── keyframe helper ───────────────────────────────────────────────────────
// Linear interpolation across [position, value] stops, mirroring the CSS
// @keyframes percentages (0..1).
double _kf(double t, List<List<num>> stops) {
  if (t <= stops.first[0]) return stops.first[1].toDouble();
  if (t >= stops.last[0]) return stops.last[1].toDouble();
  for (var i = 0; i < stops.length - 1; i++) {
    final a0 = stops[i][0].toDouble(),     a1 = stops[i][1].toDouble();
    final b0 = stops[i + 1][0].toDouble(), b1 = stops[i + 1][1].toDouble();
    if (t >= a0 && t <= b0) {
      final f = (t - a0) / (b0 - a0);
      return a1 + (b1 - a1) * f;
    }
  }
  return stops.last[1].toDouble();
}

// ─── the scene ─────────────────────────────────────────────────────────────
class _WashScene extends StatelessWidget {
  final AnimationController loop;
  final double width;
  final double height;
  const _WashScene({required this.loop, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final carW = width * 0.46;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [Color(0xFF081530), Color(0xFF060E1C), Color(0xFF04091A)],
          stops:  [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: AppTokens.blue.withOpacity(0.20), blurRadius: 90, offset: const Offset(0, 30)),
        ],
        border: Border.all(color: const Color(0xFF5BBAFF).withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final t = loop.value;

          // car horizontal position (percent of own width, centered at -50)
          final carP = _kf(t, [
            [0, -210], [.14, -52], [.16, -50], [.18, -50],
            [.74, -50], [.78, -46], [.82, -40], [1, 220],
          ]);
          final carDx = carW * (carP / 100 + 0.5);
          final shakeY = (t > 0.30 && t < 0.68) ? math.sin((t - 0.30) * 64) * -1.3 : 0.0;

          final mud   = _kf(t, [[0, .95], [.28, .95], [.40, .7], [.52, .25], [.60, 0], [1, 0]]);
          final fog   = _kf(t, [[0, 0], [.40, 0], [.46, .5], [.52, 1], [.58, 1], [.64, .65], [.70, .25], [.76, 0], [1, 0]]);
          final fogSc = _kf(t, [[0, .6], [.40, .6], [.46, .9], [.52, 1.05], [.58, 1.1], [.64, 1.18], [.70, 1.3], [.76, 1.45], [1, 1.45]]);
          final gleam = _kf(t, [[0, 0], [.60, 0], [.66, 1], [.78, .7], [.90, .4], [1, 0]]);
          final spk   = _kf(t, [[0, 0], [.64, 0], [.68, 1], [.74, .6], [.80, 0], [1, 0]]);
          final spkSc = _kf(t, [[0, .3], [.64, .3], [.68, 1.4], [.74, 1], [.80, .4], [1, .3]]);
          final brush = _kf(t, [[0, 0], [.22, 0], [.26, .9], [.56, .9], [.62, 0], [1, 0]]);
          final rain  = _kf(t, [[0, 0], [.24, 0], [.28, 1], [.58, 1], [.62, 0], [1, 0]]);

          return Stack(
            children: [
              // ground glow + scan line
              Positioned.fill(child: CustomPaint(painter: _GroundPainter())),

              // arch + spray bar + LEDs
              Positioned.fill(child: CustomPaint(painter: _ArchPainter(blink: loop.value))),

              // counting ticks
              Positioned(
                left: 0, right: 0, bottom: height * 0.18,
                child: CustomPaint(size: Size(width, 8), painter: _TicksPainter(t: t)),
              ),

              // rain
              Positioned.fill(
                child: Opacity(
                  opacity: rain,
                  child: CustomPaint(painter: _RainPainter(t: t, width: width, height: height)),
                ),
              ),

              // side brushes
              _Brush(left: true,  scene: Size(width, height), opacity: brush, t: t),
              _Brush(left: false, scene: Size(width, height), opacity: brush, t: t),

              // status chip
              Positioned(
                top: height * 0.05, left: 0, right: 0,
                child: const Center(child: _Chip()),
              ),

              // car + wash overlays
              Positioned(
                left: 0, right: 0, bottom: height * 0.18,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(carDx, shakeY),
                    child: SizedBox(
                      width: carW,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // soft ground shadow under the car
                          Positioned(
                            left: carW * 0.08, right: carW * 0.08, bottom: -6, height: 14,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 18, spreadRadius: 2)],
                              ),
                            ),
                          ),
                          Image.asset('assets/images/car-clean.png', fit: BoxFit.fitWidth),
                          // mud (before wash)
                          Positioned.fill(child: Opacity(opacity: mud, child: CustomPaint(painter: _MudPainter()))),
                          // fog cover
                          Positioned.fill(
                            child: Opacity(
                              opacity: fog,
                              child: Transform.scale(scale: fogSc, child: CustomPaint(painter: _FogPainter())),
                            ),
                          ),
                          // gleam shine
                          Positioned.fill(child: Opacity(opacity: gleam, child: CustomPaint(painter: _GleamPainter()))),
                          // sparkles
                          ..._sparkles(carW, spk, spkSc),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _sparkles(double carW, double opacity, double scale) {
    const spots = [
      [0.24, 0.18], [0.50, 0.28], [0.78, 0.22], [0.18, 0.50], [0.76, 0.54],
    ];
    final carH = carW * 0.52; // approx aspect of car-clean.png
    return [
      for (final s in spots)
        Positioned(
          left: carW * s[0], top: carH * s[1],
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: const _Sparkle()),
          ),
        ),
    ];
  }
}

// ─── ground (floor glow + scan line) ───────────────────────────────────────
class _GroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final top = s.height * 0.64;
    final floor = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, const Color(0xFF5BBAFF).withOpacity(0.06), const Color(0xFF00C896).withOpacity(0.04)],
      ).createShader(Rect.fromLTWH(0, top, s.width, s.height - top));
    canvas.drawRect(Rect.fromLTWH(0, top, s.width, s.height - top), floor);

    // scan line
    final y = top + (s.height - top) * 0.42;
    final scan = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, const Color(0xFF5BBAFF).withOpacity(0.55), const Color(0xFF00D4AA).withOpacity(0.5), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, y, s.width, 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRect(Rect.fromLTWH(0, y, s.width, 2), scan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── arch + spray bar + corner LEDs ────────────────────────────────────────
class _ArchPainter extends CustomPainter {
  final double blink;
  _ArchPainter({required this.blink});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width * 0.66;
    final h = s.height * 0.62;
    final left = (s.width - w) / 2;
    final top = s.height * 0.10;
    final r = math.min(w / 2, 110.0);
    final bottom = top + h;

    final path = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: Radius.circular(r))
      ..lineTo(left + w - r, top)
      ..arcToPoint(Offset(left + w, top + r), radius: Radius.circular(r))
      ..lineTo(left + w, bottom);

    // faint base stroke
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF5BBAFF).withOpacity(0.18));
    // gradient overlay stroke (0.55 opacity baked into the gradient)
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = LinearGradient(colors: [
        const Color(0xFF2B7FFF).withOpacity(0.55),
        const Color(0xFF00D4AA).withOpacity(0.55),
        const Color(0xFF00C896).withOpacity(0.55),
      ]).createShader(Rect.fromLTWH(left, top, w, h)));

    // spray bar
    final sprayW = s.width * 0.52;
    final sprayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH((s.width - sprayW) / 2, s.height * 0.14, sprayW, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(sprayRect, Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = AppTokens.blue.withOpacity(0.55));
    canvas.drawRRect(sprayRect, Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF2B7FFF), Color(0xFF00D4AA), Color(0xFF00C896)])
          .createShader(sprayRect.outerRect));

    // corner LEDs (blink)
    final ledL = (0.5 + 0.5 * math.sin(blink * 2 * math.pi)).clamp(0.3, 1.0);
    final ledR = (0.5 + 0.5 * math.sin((blink + 0.25) * 2 * math.pi)).clamp(0.3, 1.0);
    _led(canvas, Offset(left, top), const Color(0xFF5BBAFF), ledL);
    _led(canvas, Offset(left + w, top), const Color(0xFF00D4AA), ledR);
  }

  void _led(Canvas c, Offset o, Color col, double a) {
    c.drawCircle(o, 6, Paint()
      ..color = col.withOpacity(a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawCircle(o, 5, Paint()..color = col.withOpacity(a));
  }

  @override
  bool shouldRepaint(covariant _ArchPainter old) => old.blink != blink;
}

// ─── counting ticks ────────────────────────────────────────────────────────
class _TicksPainter extends CustomPainter {
  final double t;
  _TicksPainter({required this.t});

  @override
  void paint(Canvas canvas, Size s) {
    const n = 9;
    final padX = s.width * 0.08;
    final span = s.width - padX * 2;
    for (var i = 0; i < n; i++) {
      final x = padX + span * i / (n - 1);
      // each tick flashes on a staggered phase
      final phase = (t * 1.0 - i * 0.05) % 1.0;
      final lit = phase >= 0 && phase < 0.12;
      final paint = Paint()
        ..color = lit ? const Color(0xFF5BBAFF) : const Color(0xFF5BBAFF).withOpacity(0.22);
      if (lit) paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.5, 0, 3, 6), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TicksPainter old) => old.t != t;
}

// ─── rain droplets ─────────────────────────────────────────────────────────
class _RainPainter extends CustomPainter {
  final double t;
  final double width;
  final double height;
  _RainPainter({required this.t, required this.width, required this.height});

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    final bandL = s.width * 0.24;
    final bandW = s.width * 0.52;
    final top = s.height * 0.16;
    final fallH = s.height * 0.6;
    for (var i = 0; i < 16; i++) {
      final x = bandL + rnd.nextDouble() * bandW;
      final speed = 0.5 + rnd.nextDouble() * 0.3;
      final p = ((t / speed) + rnd.nextDouble()) % 1.0;
      final y = top + fallH * p;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, const Color(0xFF7BC8FF), const Color(0xFF2B7FFF)],
        ).createShader(Rect.fromLTWH(x, y, 3, 14))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 3, 12), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => old.t != t;
}

// ─── side brush ────────────────────────────────────────────────────────────
class _Brush extends StatelessWidget {
  final bool left;
  final Size scene;
  final double opacity;
  final double t;
  const _Brush({required this.left, required this.scene, required this.opacity, required this.t});

  @override
  Widget build(BuildContext context) {
    final w = 16.0;
    final h = scene.height * 0.40;
    final baseX = left ? scene.width * 0.18 : scene.width * 0.82 - w;
    // gentle in/out oscillation while active
    final wobble = math.sin(t * 24) * (opacity > 0.1 ? 8 : 0) * (left ? 1 : -1);

    return Positioned(
      top: scene.height * 0.38,
      left: baseX + wobble,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: w, height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: left
                  ? const [Color(0xFF5BBAFF), Color(0xFF2B7FFF)]
                  : const [Color(0xFF3FE0B0), Color(0xFF00C896)],
            ),
            boxShadow: [
              BoxShadow(
                color: (left ? const Color(0xFF5BBAFF) : const Color(0xFF00C896)).withOpacity(0.65),
                blurRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── mud overlay ───────────────────────────────────────────────────────────
class _MudPainter extends CustomPainter {
  static const _blobs = <List<double>>[
    // x%, y%, rx%, ry%, alpha
    [.18, .52, .10, .08, .92], [.28, .72, .07, .06, .88], [.36, .38, .05, .04, .70],
    [.46, .60, .09, .07, .85], [.56, .44, .06, .05, .75], [.64, .70, .08, .06, .85],
    [.78, .56, .09, .07, .85], [.86, .72, .07, .05, .85],
  ];

  @override
  void paint(Canvas canvas, Size s) {
    for (final b in _blobs) {
      final cx = s.width * b[0], cy = s.height * b[1];
      final rx = s.width * b[2] * 1.6, ry = s.height * b[3] * 1.6;
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF5A3A1C).withOpacity(b[4]), Colors.transparent],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── fog cover ─────────────────────────────────────────────────────────────
class _FogPainter extends CustomPainter {
  static const _blobs = <List<double>>[
    [.28, .50, .38, .50], [.70, .48, .36, .48], [.50, .60, .30, .40],
    [.20, .30, .22, .30], [.80, .32, .24, .30], [.40, .70, .28, .40],
  ];

  @override
  void paint(Canvas canvas, Size s) {
    for (final b in _blobs) {
      final rect = Rect.fromCenter(
        center: Offset(s.width * b[0], s.height * b[1]),
        width: s.width * b[2] * 2, height: s.height * b[3] * 2,
      );
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFE1F0FF).withOpacity(0.9), const Color(0xFFB4D2EB).withOpacity(0.0)],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── gleam ─────────────────────────────────────────────────────────────────
class _GleamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    // diagonal shine sweep
    final sweep = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-1, -0.6), end: Alignment(1, 0.6),
        colors: [Colors.transparent, Color(0x80FFFFFF), Colors.transparent],
        stops: [0.28, 0.36, 0.44],
      ).createShader(Offset.zero & s);
    canvas.drawRect(Offset.zero & s, sweep);

    // two highlight pools on the roof
    for (final p in const [[.30, .28, .18, .08, .55], [.70, .24, .14, .06, .40]]) {
      final rect = Rect.fromCenter(
        center: Offset(s.width * p[0], s.height * p[1]),
        width: s.width * p[2] * 2, height: s.height * p[3] * 2,
      );
      canvas.drawOval(rect, Paint()
        ..shader = RadialGradient(colors: [Colors.white.withOpacity(p[4]), Colors.transparent]).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── sparkle ───────────────────────────────────────────────────────────────
class _Sparkle extends StatelessWidget {
  const _Sparkle();

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(10, 10), painter: _SparklePainter());
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    canvas.drawCircle(c, 3, Paint()
      ..shader = RadialGradient(colors: [Colors.white, Colors.white.withOpacity(0)]).createShader(
          Rect.fromCircle(center: c, radius: 4)));
    final line = Paint()..color = Colors.white..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, c.dy), Offset(s.width, c.dy), line);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, s.height), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── status chip ───────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1424).withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5BBAFF).withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D4AA),
              boxShadow: [BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.8), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'BAY 01 · SCANNING',
            style: TextStyle(
              fontFamily: 'monospace', fontSize: 10, letterSpacing: 2.0,
              color: Color(0xFF5BBAFF), fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── wordmark ──────────────────────────────────────────────────────────────
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2.5,
      height: 0.9, color: Color(0xFFDBE4F0),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('laven', style: base),
        _accent('t', const [Color(0xFF2B7FFF), Color(0xFF2B7FFF)], base),
        _accent('r', const [Color(0xFF00D4AA), Color(0xFF00C896)], base),
        _accent('a', const [Color(0xFF00C896), Color(0xFF00A580)], base),
      ],
    );
  }

  Widget _accent(String ch, List<Color> colors, TextStyle base) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors,
      ).createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(ch, style: base.copyWith(color: Colors.white)),
    );
  }
}

// ─── tagline ───────────────────────────────────────────────────────────────
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'AI',
          style: TextStyle(fontFamily: 'monospace', fontSize: 11, letterSpacing: 3.5, color: Color(0xFF5A6B86)),
        ),
        Container(
          width: 5, height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 11),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5A6B86)),
        ),
        const Text(
          'CAR-WASH COUNTER',
          style: TextStyle(fontFamily: 'monospace', fontSize: 11, letterSpacing: 3.5, color: Color(0xFF5A6B86)),
        ),
      ],
    );
  }
}
