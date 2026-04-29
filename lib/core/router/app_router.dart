import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

import '../../features/shell/presentation/home_shell.dart';

import '../../features/home/bloc/dashboard_bloc.dart';
import '../../features/home/presentation/dashboard_screen.dart';

import '../../features/events/presentation/events_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';

import '../../features/lavvaggios/presentation/lavaggi_screen.dart';
import '../../features/lavvaggios/presentation/lavaggio_settings_screen.dart';
import '../../features/lavvaggios/data/models/lavvaggio_model.dart';

import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/create_report_screen.dart';

import '../../features/notifications/presentation/notifications_screen.dart';

import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/account_settings_screen.dart';
import '../../features/profile/presentation/notification_settings_screen.dart';
import '../../features/profile/presentation/camera_config_screen.dart';
import '../../features/profile/presentation/network_screen.dart';

import '../../features/devices/data/repositories/device_repository.dart';
import '../../features/events/data/repositories/event_repository.dart';
import '../../features/lavvaggios/data/repositories/lavvaggio_repository.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';

/// go_router config. Auth state drives top-level redirects.
///
/// Architecture:
/// - Reference blocs (Lavvaggio/Device/Event/Notification/Report/Profile) are
///   provided once at the root in [main.dart] and shared across the whole app.
/// - The 5-tab nav lives under a [StatefulShellRoute.indexedStack] so each tab
///   keeps its own navigation history.
/// - Screen-scoped blocs (DashboardBloc) are created inline in their route
///   builder via [BlocProvider].
/// - Sub-screens (event detail, lavaggio settings, reports/new, notifications,
///   profile sub-pages) live as TOP-LEVEL routes outside the shell so they
///   present fullscreen without the bottom nav.
class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter build(AuthBloc auth) {
    return GoRouter(
      navigatorKey:      _rootKey,
      initialLocation:   '/splash',
      refreshListenable: _AuthListenable(auth),
      redirect: (context, state) {
        final s   = auth.state;
        final loc = state.matchedLocation;

        if (loc == '/splash') return null;          // splash decides itself
        final isAuthed = s is AuthAuthenticated;
        final atLogin  = loc == '/login';
        if (!isAuthed && !atLogin) return '/login';
        if (isAuthed  &&  atLogin) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),

        // ── Bottom-nav shell ──────────────────────────────────────────────
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => HomeShell(shell: shell),
          branches: [
            // Home
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => BlocProvider(
                  create: (_) => DashboardBloc(
                    lavRepo:    LavvaggioRepository(),
                    deviceRepo: DeviceRepository(),
                    eventRepo:  EventRepository(),
                    notifRepo:  NotificationRepository(),
                  ),
                  child: const DashboardScreen(),
                ),
              ),
            ]),
            // Events
            StatefulShellBranch(routes: [
              GoRoute(path: '/events', builder: (_, __) => const EventsScreen()),
            ]),
            // Lavaggi
            StatefulShellBranch(routes: [
              GoRoute(path: '/lavaggi', builder: (_, __) => const LavaggiScreen()),
            ]),
            // Reports
            StatefulShellBranch(routes: [
              GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
            ]),
            // Profile
            StatefulShellBranch(routes: [
              GoRoute(path: '/profile', builder: (context, __) {
                final s = context.read<AuthBloc>().state;
                if (s is! AuthAuthenticated) return const SizedBox.shrink();
                return ProfileScreen(user: s.user);
              }),
            ]),
          ],
        ),

        // ── Top-level sub-screens (no bottom nav) ─────────────────────────
        GoRoute(path: '/notifications',           builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/events/:id',              builder: (_, st)  => EventDetailScreen(eventId: int.parse(st.pathParameters['id']!))),
        GoRoute(path: '/lavaggi/:id/settings',    builder: (_, st)  {
          final extra = st.extra;
          if (extra is LavvaggioModel) return LavaggioSettingsScreen(lavvaggio: extra);
          return const Scaffold(body: Center(child: Text('Lavaggio context missing')));
        }),
        GoRoute(path: '/reports/new',             builder: (_, __) => const CreateReportScreen()),
        GoRoute(path: '/profile/account',         builder: (_, __) => const AccountSettingsScreen()),
        GoRoute(path: '/profile/notifications',   builder: (_, __) => const NotificationSettingsScreen()),
        GoRoute(path: '/profile/camera',          builder: (_, __) => const CameraConfigScreen()),
        GoRoute(path: '/profile/network',         builder: (_, __) => const NetworkScreen()),
        GoRoute(path: '/profile/privacy',         builder: (_, __) => const _NotImplementedScreen(title: 'Privacy & Security')),
      ],
    );
  }
}

/// Bridges AuthBloc state changes to GoRouter so redirects re-evaluate when
/// the user logs in or out.
class _AuthListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _AuthListenable(AuthBloc bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Stub for routes that point to screens we have not yet built (Privacy
/// & Security). Linked from Profile menu.
class _NotImplementedScreen extends StatelessWidget {
  final String title;
  const _NotImplementedScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F1E),
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Coming soon', style: TextStyle(color: Color(0xFF6A8FAD))),
      ),
    );
  }
}
