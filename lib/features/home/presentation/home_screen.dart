import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/data/repositories/profile_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../lavvaggios/bloc/lavvaggio_bloc.dart';
import '../../lavvaggios/data/repositories/lavvaggio_repository.dart';
import '../../lavvaggios/presentation/lavvaggios_screen.dart';
import '../../events/bloc/event_bloc.dart';
import '../../events/data/repositories/event_repository.dart';
import '../../events/presentation/events_screen.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int          _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Get user once — before build runs
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    // Build screens ONCE here — never inside build()
    // IndexedStack keeps them alive; BlocProviders are never recreated
    _screens = [
      BlocProvider(
        create: (_) => EventBloc(repository: EventRepository()),
        child:  const EventsScreen(),
      ),
      BlocProvider(
        create: (_) => LavvaggioBloc(repository: LavvaggioRepository()),
        child:  const LavvaggiosScreen(),
      ),
      if (user != null)
        BlocProvider(
          create: (_) => ProfileBloc(repository: ProfileRepository()),
          child:  ProfileScreen(user: user),
        )
      else
        const SizedBox.shrink(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSessionExpiredState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please log in again.'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index:    _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex:         _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor:       AppColors.surface,
          indicatorColor:        AppColors.primary.withOpacity(0.12),
          labelBehavior:
          NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon:         Icon(Icons.local_car_wash_outlined),
              selectedIcon: Icon(
                Icons.local_car_wash_rounded,
                color: AppColors.primary,
              ),
              label: 'Events',
            ),
            NavigationDestination(
              icon:         Icon(Icons.store_outlined),
              selectedIcon: Icon(
                Icons.store_rounded,
                color: AppColors.primary,
              ),
              label: 'Lavvaggios',
            ),
            NavigationDestination(
              icon:         Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}