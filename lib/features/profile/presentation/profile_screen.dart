import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/data/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final menu = <_MenuItem>[
      _MenuItem(icon: Icons.person_outline_rounded,        label: 'Account Settings',      sub: 'Name, email, password',     route: '/profile/account'),
      _MenuItem(icon: Icons.notifications_outlined,        label: 'Notifications',          sub: 'Alert preferences',         route: '/profile/notifications'),
      _MenuItem(icon: Icons.memory_rounded,                label: 'Camera & AI Config',     sub: 'Detection settings',        route: '/profile/camera'),
      _MenuItem(icon: Icons.wifi_rounded,                  label: 'Network & Connectivity', sub: 'Connection status',         route: '/profile/network'),
      _MenuItem(icon: Icons.shield_outlined,               label: 'Privacy & Security',     sub: '2FA, sessions',             route: '/profile/privacy'),
      _MenuItem(icon: Icons.description_outlined,          label: 'Reports',                sub: 'Generate & schedule',       route: '/reports', tabSwitch: true),
    ];

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(user: user),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
              child: Column(
                children: [
                  ...menu.map((m) => _Tile(
                    item: m,
                    onTap: () => m.tabSwitch ? context.go(m.route) : context.push(m.route),
                  )),
                  const SizedBox(height: 6),
                  _LogoutTile(onTap: () => _confirmLogout(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context,
      title:        'Sign Out',
      message:      'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      destructive:  true,
    );
    if (ok == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}

class _Header extends StatelessWidget {
  final UserModel user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topCenter,
          end:    Alignment.bottomCenter,
          colors: [Color(0xFF0F1E35), AppTokens.bg],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTokens.blue, Color(0xFF5B9FFF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.fullName,
            style: const TextStyle(color: AppTokens.tp, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(user.email, style: const TextStyle(color: AppTokens.ts, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color:        AppTokens.blue.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppTokens.blue.withOpacity(0.3)),
            ),
            child: Text(user.role.toUpperCase().replaceAll('_', ' '),
              style: const TextStyle(color: AppTokens.blueL, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final _MenuItem    item;
  final VoidCallback onTap;
  const _Tile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg - 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.rLg - 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              border:       Border.all(color: AppTokens.border),
              borderRadius: BorderRadius.circular(AppTokens.rLg - 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color:        AppTokens.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: AppTokens.blue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: const TextStyle(color: AppTokens.tp, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 1),
                      Text(item.sub, style: const TextStyle(color: AppTokens.ts, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTokens.ts, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        AppTokens.red.withOpacity(0.13),
      borderRadius: BorderRadius.circular(AppTokens.rLg - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.rLg - 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            border:       Border.all(color: AppTokens.red.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppTokens.rLg - 2),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        AppTokens.red.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, color: AppTokens.red, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Sign Out',
                  style: TextStyle(color: AppTokens.red, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String   label;
  final String   sub;
  final String   route;
  /// True for routes that should switch the bottom-nav tab (e.g. Reports)
  /// rather than push as a sub-screen.
  final bool     tabSwitch;
  const _MenuItem({required this.icon, required this.label, required this.sub, required this.route, this.tabSwitch = false});
}
