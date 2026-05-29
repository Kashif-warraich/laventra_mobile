import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../data/repositories/auth_repository.dart';

/// Forced onto the user immediately after activation, while
/// must_change_password is true on their account. The router redirect
/// won't let them off this screen until the server flips the flag.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _repo        = AuthRepository();
  final _formKey     = GlobalKey<FormState>();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _submitting = false;
  bool _obscure    = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final user = await _repo.changePassword(
        password: _passCtrl.text,
        passwordConfirmation: _confirmCtrl.text,
      );
      if (!mounted) return;
      // must_change_password flipped to false in the response — refresh
      // the bloc so the router redirect lets the user into /home.
      context.read<AuthBloc>().add(AuthUserRefreshed(user));
      AppAlerts.success(context, 'Welcome, ${user.firstName}!');
    } on DioException catch (e) {
      final errors = e.response?.data?['errors'];
      final msg = (errors is List && errors.isNotEmpty)
          ? errors.first.toString()
          : 'Could not update password.';
      if (!mounted) return;
      AppAlerts.error(context, msg);
    } catch (_) {
      if (!mounted) return;
      AppAlerts.error(context, 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      // No back button — user must complete the step. PopScope blocks the
      // hardware back gesture for the same reason.
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppTokens.blueL, size: 56),
                    const SizedBox(height: 14),
                    const Text('Set your password',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTokens.tp, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose a password to finish activating your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTokens.ts, fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    _passwordField(
                      controller: _passCtrl,
                      label: 'New Password',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6)            return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _passwordField(
                      controller: _confirmCtrl,
                      label: 'Confirm Password',
                      validator: (v) {
                        if (v == null || v.isEmpty)  return 'Please confirm';
                        if (v != _passCtrl.text)     return 'Passwords don\'t match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.blue,
                          foregroundColor: Colors.white,
                          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : const Text('Save & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller:  controller,
      obscureText: _obscure,
      style:       const TextStyle(color: AppTokens.tp),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: const TextStyle(color: AppTokens.ts),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTokens.ts, size: 18),
        suffixIcon: IconButton(
          splashRadius: 20,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppTokens.ts, size: 18),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: validator,
    );
  }
}
