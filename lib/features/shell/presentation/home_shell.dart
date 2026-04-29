import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';

/// Bottom-nav host for the 5 main tabs: Home / Events / Lavaggi / Reports /
/// Profile. Uses go_router's StatefulShellRoute so each tab keeps its own
/// navigation stack and BLoC state across switches.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const HomeShell({super.key, required this.shell});

  static const _items = [
    _NavItem(icon: Icons.home_outlined,           selected: Icons.home_rounded,             label: 'Home'),
    _NavItem(icon: Icons.calendar_month_outlined, selected: Icons.calendar_month_rounded,   label: 'Events'),
    _NavItem(icon: Icons.local_car_wash_outlined, selected: Icons.local_car_wash_rounded,   label: 'Lavaggi'),
    _NavItem(icon: Icons.description_outlined,    selected: Icons.description_rounded,     label: 'Reports'),
    _NavItem(icon: Icons.person_outline_rounded,  selected: Icons.person_rounded,           label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: shell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTokens.bgCard,
          border: Border(top: BorderSide(color: AppTokens.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == shell.currentIndex;
                final item     = _items[i];
                final color    = selected ? AppTokens.blue : AppTokens.ts;
                return Expanded(
                  child: InkWell(
                    onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(selected ? item.selected : item.icon, color: color, size: 22),
                        const SizedBox(height: 3),
                        Text(item.label,
                          style: TextStyle(
                            color:      color,
                            fontSize:   10.5,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selected;
  final String   label;
  const _NavItem({required this.icon, required this.selected, required this.label});
}
