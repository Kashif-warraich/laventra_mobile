import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/sub_header.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/data/models/user_model.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _username;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    final u    = auth is AuthAuthenticated ? auth.user : null;
    _firstName = TextEditingController(text: u?.firstName ?? '');
    _lastName  = TextEditingController(text: u?.lastName  ?? '');
    _email     = TextEditingController(text: u?.email     ?? '');
    _phone     = TextEditingController(text: u?.phoneNumber ?? '');
    _username  = TextEditingController(text: u?.username  ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _username.dispose();
    super.dispose();
  }

  void _save(UserModel user) {
    context.read<ProfileBloc>().add(ProfileUpdateRequested(
      userId:      user.id,
      firstName:   _firstName.text.trim(),
      lastName:    _lastName.text.trim(),
      username:    _username.text.trim(),
      email:       _email.text.trim(),
      phoneNumber: _phone.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null) {
      return const Scaffold(backgroundColor: AppTokens.bg);
    }
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: 'Account Settings', onBack: () => context.pop()),
            Expanded(
              child: BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileUpdateSuccess) {
                    AppAlerts.success(context, state.message);
                  } else if (state is ProfileError) {
                    AppAlerts.error(context, state.message);
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  children: [
                    _Card(
                      title: 'Personal Info',
                      children: [
                        _F(label: 'First Name',   controller: _firstName),
                        const SizedBox(height: 12),
                        _F(label: 'Last Name',    controller: _lastName),
                        const SizedBox(height: 12),
                        _F(label: 'Username',     controller: _username),
                        const SizedBox(height: 12),
                        _F(label: 'Email',        controller: _email,    keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _F(label: 'Phone Number', controller: _phone,    keyboard: TextInputType.phone),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      title: 'Security',
                      children: [
                        _Btn(label: 'Change Password',
                          color: AppTokens.blue,
                          onTap: () => AppAlerts.info(context, 'Password reset email sent')),
                        const SizedBox(height: 8),
                        _Btn(label: 'Enable 2FA',
                          color: AppTokens.teal,
                          onTap: () => AppAlerts.info(context, '2FA setup not yet implemented')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (_, state) {
                        final saving = state is ProfileUpdating;
                        return SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: saving ? null : () => _save(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTokens.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: saving
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                              : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _F extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final TextInputType?        keyboard;
  const _F({required this.label, required this.controller, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: const TextStyle(color: AppTokens.ts, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller:   controller,
          keyboardType: keyboard,
          style:        const TextStyle(color: AppTokens.tp),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        color.withOpacity(0.13),
      borderRadius: BorderRadius.circular(AppTokens.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border:       Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppTokens.rMd),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String        title;
  final List<Widget>  children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
