import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/constants/app_constants.dart';

/// Splash: dark gradient + ripple ring + glowing logo + loading dots.
/// Auth state drives navigation (router redirect handles it once checked).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entry;       // fade + scale in
  late final AnimationController _ripple;      // looping ripple ring
  late final AnimationController _glow;        // logo glow pulse

  @override
  void initState() {
    super.initState();
    _entry  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _glow   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.read<AuthBloc>().add(const AuthStarted());
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _ripple.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center:  Alignment.topCenter,
            radius:  1.2,
            colors:  [Color(0xFF112340), AppTokens.bg],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(
                CurvedAnimation(parent: _entry, curve: Curves.elasticOut),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ripple + glow + logo
                  SizedBox(
                    width: 220, height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _Ripple(ctrl: _ripple),
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (_, child) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:     AppTokens.blue.withOpacity(0.25 + 0.25 * _glow.value),
                                  blurRadius: 40 + 30 * _glow.value,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          child: const AppLogo(size: 120),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTokens.tp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.appTagline,
                    style: const TextStyle(color: AppTokens.ts, fontSize: 14, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 36),
                  _LoadingDots(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots that fade in sequence — design's loading rhythm.
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          // Stagger each dot's pulse phase by 0.33
          final phase = ((_ac.value + i * 0.33) % 1.0);
          final t     = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width:  8, height: 8,
            decoration: BoxDecoration(
              color: AppTokens.blue.withOpacity(0.3 + 0.7 * t),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class _Ripple extends StatelessWidget {
  final AnimationController ctrl;
  const _Ripple({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(2, (i) {
            // Stagger each ring 0.5 phase apart so two ripples overlap
            final phase = ((ctrl.value + i * 0.5) % 1.0);
            return Opacity(
              opacity: (1 - phase).clamp(0.0, 1.0),
              child: Container(
                width:  90 + 130 * phase,
                height: 90 + 130 * phase,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  border: Border.all(color: AppTokens.blue.withOpacity(0.4)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
