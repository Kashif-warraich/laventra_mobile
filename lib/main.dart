import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before anything else
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  Brightness.light,
    ),
  );

  ApiClient.instance.init();

  runApp(const LaventraApp());
}

class LaventraApp extends StatelessWidget {
  const LaventraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(repository: AuthRepository()),
      child: MaterialApp(
        title:                   'Laventra',
        debugShowCheckedModeBanner: false,
        theme:                    AppTheme.theme,
        initialRoute:             '/',
        routes: {
          '/':      (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/home':  (_) => const HomeScreen(),
        },
      ),
    );
  }
}