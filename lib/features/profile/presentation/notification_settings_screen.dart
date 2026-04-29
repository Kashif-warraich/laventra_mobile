import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/lav_toggle.dart';
import '../../../core/widgets/sub_header.dart';

/// Local-only preferences for now — backend doesn't yet persist them. Will
/// be wired up when /users/me/preferences arrives.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<String, bool> _v = {
    'email':   true,
    'push':    true,
    'offline': true,
    'events':  false,
    'reports': true,
  };

  static const _items = [
    _Item('email',   'Email Alerts',          'Receive alerts by email'),
    _Item('push',    'Push Notifications',    'In-app push alerts'),
    _Item('offline', 'Device Offline',         'Alert when camera/AI goes offline'),
    _Item('events',  'Every Event',            'Notify on each detection'),
    _Item('reports', 'Daily Reports',          'Morning summary email'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: 'Notification Settings', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:        AppTokens.bgCard,
                      borderRadius: BorderRadius.circular(AppTokens.rLg),
                      border:       Border.all(color: AppTokens.border),
                    ),
                    child: Column(
                      children: List.generate(_items.length * 2 - 1, (i) {
                        if (i.isOdd) return const Divider(color: AppTokens.border, height: 1);
                        final item = _items[i ~/ 2];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.label, style: const TextStyle(color: AppTokens.tp, fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(item.sub,   style: const TextStyle(color: AppTokens.ts, fontSize: 12)),
                                  ],
                                ),
                              ),
                              LavToggle(
                                value: _v[item.key]!,
                                onChanged: (v) => setState(() => _v[item.key] = v),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final String key;
  final String label;
  final String sub;
  const _Item(this.key, this.label, this.sub);
}
