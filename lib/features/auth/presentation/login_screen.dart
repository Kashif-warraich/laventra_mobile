import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/biometric_icon.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/storage/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscurePassword = true;

  bool _biometricAvailable = false;
  bool _isFaceId           = false;

  late final AnimationController _orbA;
  late final AnimationController _orbB;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _orbA = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orbB = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat(reverse: true);
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled   = await SecureStorage.instance.getBiometricEnabled();
    final available = await BiometricService.instance.isAvailable();
    final faceId    = await BiometricService.instance.isFaceId();
    if (mounted) {
      setState(() {
        _biometricAvailable = enabled && available;
        _isFaceId           = faceId;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _orbA.dispose();
    _orbB.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLoginRequested(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      ));
    }
  }

  /// Round button next to Sign In. Local biometric check, then ask the
  /// bloc to restore the session from secure storage (no network call).
  Future<void> _biometricLogin() async {
    final ok = await BiometricService.instance.authenticate();
    if (!mounted || !ok) return;
    context.read<AuthBloc>().add(const AuthBiometricRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoginFailure) {
            AppAlerts.error(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoginInProgress;
          return Stack(
            children: [
              const _LoginBackground(),
              _Orbs(a: _orbA, b: _orbB),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      _GlowingLogo(glow: _glow),
                      const SizedBox(height: 14),
                      Text(AppConstants.appName,
                        style: const TextStyle(
                          color: AppTokens.tp, fontSize: 28, fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Smart Car Wash Management',
                        style: TextStyle(color: AppTokens.ts, fontSize: 13.5),
                      ),
                      const SizedBox(height: 22),
                      const _StatsStrip(),
                      const SizedBox(height: 22),
                      _GlassCard(
                        formKey:            _formKey,
                        emailCtrl:          _emailCtrl,
                        passwordCtrl:       _passwordCtrl,
                        obscure:            _obscurePassword,
                        onTogglePassword:   () => setState(() => _obscurePassword = !_obscurePassword),
                        onSubmit:           _submit,
                        isLoading:          isLoading,
                        biometricAvailable: _biometricAvailable,
                        isFaceId:           _isFaceId,
                        onBiometric:        _biometricLogin,
                      ),
                      const SizedBox(height: 18),
                      _Footer(),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: [Color(0xFF0A1730), AppTokens.bg, Color(0xFF080F1E)],
          ),
        ),
      ),
    );
  }
}

class _Orbs extends StatelessWidget {
  final AnimationController a;
  final AnimationController b;
  const _Orbs({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([a, b]),
        builder:   (_, __) => Stack(
          children: [
            Positioned(
              top:  -80 + 30 * a.value,
              left: -60 - 20 * a.value,
              child: _orb(220, AppTokens.blue.withOpacity(0.25)),
            ),
            Positioned(
              bottom: -100 + 40 * b.value,
              right:  -80 - 20 * b.value,
              child: _orb(260, AppTokens.teal.withOpacity(0.18)),
            ),
            Positioned(
              top: 220 + 30 * b.value, right: 40,
              child: _orb(120, AppTokens.purple.withOpacity(0.12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
    ),
  );
}

class _GlowingLogo extends StatelessWidget {
  final AnimationController glow;
  const _GlowingLogo({required this.glow});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:        AppTokens.blue.withOpacity(0.25 + 0.30 * glow.value),
              blurRadius:   30 + 20 * glow.value,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
      child: const AppLogo(size: 92),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        AppTokens.bgCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          Expanded(child: _statCell('9,842', 'Events',    AppTokens.blue)),
          _divider(),
          Expanded(child: _statCell('96%',  'Accuracy',  AppTokens.teal)),
          _divider(),
          Expanded(child: _statCell('3',    'Locations', AppTokens.purple)),
        ],
      ),
    );
  }

  Widget _statCell(String v, String l, Color c) => Column(
    children: [
      Text(v, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(l, style: const TextStyle(color: AppTokens.ts, fontSize: 11, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _divider() => Container(width: 1, height: 28, color: AppTokens.border);
}

class _GlassCard extends StatelessWidget {
  final GlobalKey<FormState>   formKey;
  final TextEditingController  emailCtrl;
  final TextEditingController  passwordCtrl;
  final bool                   obscure;
  final VoidCallback           onTogglePassword;
  final VoidCallback           onSubmit;
  final bool                   isLoading;
  final bool                   biometricAvailable;
  final bool                   isFaceId;
  final VoidCallback           onBiometric;

  const _GlassCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.isLoading,
    required this.biometricAvailable,
    required this.isFaceId,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color:        AppTokens.bgCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border:       Border.all(color: AppTokens.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Label('Email Address'),
            const SizedBox(height: 7),
            TextFormField(
              controller:      emailCtrl,
              keyboardType:    TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect:     false,
              style: const TextStyle(color: AppTokens.tp),
              decoration: const InputDecoration(
                hintText:   'email@example.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppTokens.ts, size: 18),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@'))         return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const _Label('Password'),
            const SizedBox(height: 7),
            TextFormField(
              controller:       passwordCtrl,
              obscureText:      obscure,
              textInputAction:  TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              style: const TextStyle(color: AppTokens.tp),
              decoration: InputDecoration(
                hintText: 'Your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTokens.ts, size: 18),
                suffixIcon: IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppTokens.ts, size: 18,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6)            return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 22),
            // Sign In + biometric icon side by side. Biometric button only
            // shows once the user has previously logged in AND enabled it
            // (and the device hardware supports it).
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.blue,
                        foregroundColor: Colors.white,
                        minimumSize:     const Size.fromHeight(50),
                        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation:       0,
                      ),
                      child: isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                if (biometricAvailable) ...[
                  const SizedBox(width: 12),
                  _BiometricButton(
                    onTap:   onBiometric,
                    tooltip: isFaceId ? 'Face ID' : 'Fingerprint',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => AppAlerts.info(context, 'Forgot-password flow not yet implemented'),
                style: TextButton.styleFrom(foregroundColor: AppTokens.blueL),
                child: const Text('Forgot password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppTokens.ts, fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 0.5,
    ),
  );
}

class _BiometricButton extends StatelessWidget {
  final VoidCallback onTap;
  final String       tooltip;
  const _BiometricButton({required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color:        AppTokens.bgEl,
            shape:        BoxShape.circle,
            border:       Border.all(color: AppTokens.border),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: BiometricIcon(size: 34, color: AppTokens.blueL),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('v1.0.0',
          style: TextStyle(color: AppTokens.tm, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppTokens.tm, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppTokens.tm,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {},
          child: const Text('Privacy Policy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
