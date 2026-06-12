import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';
import 'core/widgets/no_scroll_glow.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/devices/bloc/device_bloc.dart';
import 'features/devices/data/repositories/device_repository.dart';
import 'features/events/bloc/event_bloc.dart';
import 'features/events/data/repositories/event_repository.dart';
import 'features/lavvaggios/bloc/lavvaggio_bloc.dart';
import 'features/lavvaggios/data/repositories/lavvaggio_repository.dart';
import 'features/notifications/bloc/notification_bloc.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/profile/bloc/profile_bloc.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/reports/bloc/report_bloc.dart';
import 'features/reports/data/repositories/report_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.light,
    systemNavigationBarColor:          AppTokens.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  ApiClient.instance.init();

  runApp(const LaventraApp());
}

class LaventraApp extends StatefulWidget {
  const LaventraApp({super.key});

  @override
  State<LaventraApp> createState() => _LaventraAppState();
}

class _LaventraAppState extends State<LaventraApp> {
  // ── Root-scoped blocs ───────────────────────────────────────────────────
  // These hold reference data (lavaggi list, devices list, events list,
  // notifications list) that multiple screens consume. Keeping them at the
  // root means a tab switch doesn't drop loaded state and sub-screens can
  // reach the same instance via `context.read<...>()`.
  late final AuthBloc          _auth;
  late final LavvaggioBloc     _lav;
  late final DeviceBloc        _dev;
  late final EventBloc         _evt;
  late final NotificationBloc  _notif;
  late final ReportBloc        _report;
  late final ProfileBloc       _profile;

  // Cached router so DeepLinkService can push routes from outside the widget
  // tree. Built once when _auth is ready.
  late final _router = AppRouter.build(_auth);

  /// Re-registers the FCM token on every fresh authentication so
  /// notifications keep working after re-installs / token rotations.
  /// Login itself already calls registerToken; this catches the cold-start
  /// path where AuthStarted finds a stored session.
  late final dynamic _fcmAuthSub;

  @override
  void initState() {
    super.initState();
    _auth    = AuthBloc(repository: AuthRepository());
    _lav     = LavvaggioBloc(repository: LavvaggioRepository());
    _dev     = DeviceBloc(repository: DeviceRepository());
    _evt     = EventBloc(repository: EventRepository());
    _notif   = NotificationBloc(repository: NotificationRepository());
    _report  = ReportBloc(repository: ReportRepository());
    _profile = ProfileBloc(repository: ProfileRepository());

    // Route incoming laventra:// links (welcome email) into the app — the
    // service decodes the payload and dispatches an auto-login.
    DeepLinkService.instance.init(_auth);

    _fcmAuthSub = _auth.stream.listen((state) async {
      if (state is AuthAuthenticated) {
        try {
          await PushNotificationService.instance.initialize();
          await PushNotificationService.instance.registerToken();
        } catch (_) {
          // Non-fatal — backend will work without push, user just won't get
          // system tray alerts until next launch.
        }
      }
    });
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    _fcmAuthSub?.cancel();
    _auth.close();
    _lav.close();
    _dev.close();
    _evt.close();
    _notif.close();
    _report.close();
    _profile.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _auth),
        BlocProvider.value(value: _lav),
        BlocProvider.value(value: _dev),
        BlocProvider.value(value: _evt),
        BlocProvider.value(value: _notif),
        BlocProvider.value(value: _report),
        BlocProvider.value(value: _profile),
      ],
      child: MaterialApp.router(
        title:                      'Laventra',
        debugShowCheckedModeBanner: false,
        theme:                       AppTheme.theme,
        scrollBehavior:              const NoScrollGlow(),
        routerConfig:                _router,
      ),
    );
  }
}
