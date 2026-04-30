import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sub_header.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _typeFilter;        // null = all

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const NotificationsLoadRequested());
  }

  void _setFilter(String? type) {
    setState(() => _typeFilter = type);
    context.read<NotificationBloc>().add(NotificationsLoadRequested(type: type));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            final unread = state is NotificationsLoaded ? state.unreadCount : 0;
            return Column(
              children: [
                SubHeader(
                  title: 'Notifications',
                  onBack: () => context.pop(),
                  action: TextButton(
                    onPressed: unread == 0 ? null : () {
                      context.read<NotificationBloc>().add(const NotificationsMarkAllReadRequested());
                      AppAlerts.success(context, 'All marked as read');
                    },
                    style: TextButton.styleFrom(foregroundColor: AppTokens.blueL),
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
                if (unread > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('$unread unread',
                        style: const TextStyle(color: AppTokens.ts, fontSize: 12)),
                    ),
                  ),
                _Tabs(
                  current: _typeFilter,
                  counts:  state is NotificationsLoaded ? _counts(state.notifications, _typeFilter) : const {},
                  onChanged: _setFilter,
                ),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, int> _counts(List<NotificationModel> notifs, String? activeFilter) {
    return {
      'all':     notifs.length,
      'success': notifs.where((n) => n.isSuccess).length,
      'error':   notifs.where((n) => n.isError).length,
      'alert':   notifs.where((n) => n.isAlert).length,
    };
  }

  Widget _body(BuildContext context, NotificationState state) {
    if (state is NotificationLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTokens.blue));
    }
    if (state is NotificationError) {
      return EmptyState(icon: Icons.cloud_off_rounded, title: 'Failed to load', subtitle: state.message, accent: AppTokens.red);
    }
    if (state is NotificationsLoaded) {
      if (state.notifications.isEmpty) {
        return const EmptyState(icon: Icons.notifications_off_outlined, title: 'No notifications',
          subtitle: "You're all caught up");
      }
      return RefreshIndicator(
        color: AppTokens.blue,
        backgroundColor: AppTokens.bgCard,
        onRefresh: () async {
          context.read<NotificationBloc>().add(NotificationsRefreshRequested(type: _typeFilter));
          await context.read<NotificationBloc>().stream.firstWhere((s) => s is! NotificationLoading);
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          itemCount: state.notifications.length,
          itemBuilder: (_, i) => _NotifTile(
            notif: state.notifications[i],
            onTap: () {
              if (!state.notifications[i].read) {
                context.read<NotificationBloc>().add(NotificationMarkReadRequested(state.notifications[i].id));
              }
            },
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _Tabs extends StatelessWidget {
  final String?           current;
  final Map<String, int>  counts;
  final ValueChanged<String?> onChanged;

  const _Tabs({required this.current, required this.counts, required this.onChanged});

  Color _colorFor(String key) {
    switch (key) {
      case 'success': return AppTokens.teal;
      case 'error':   return AppTokens.red;
      case 'alert':   return AppTokens.amber;
      default:        return AppTokens.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:         const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          _tab('all',     'All',     null),
          _tab('success', 'Success', 'success'),
          _tab('error',   'Error',   'error'),
          _tab('alert',   'Alert',   'alert'),
        ],
      ),
    );
  }

  Widget _tab(String key, String label, String? value) {
    final color  = _colorFor(key);
    final active = current == value;
    final count  = counts[key] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color:        active ? color.withOpacity(0.18) : AppTokens.bgCard,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: active ? color : AppTokens.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(
                color: active ? color : AppTokens.ts, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:        active ? color.withOpacity(0.25) : AppTokens.bgEl,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                  style: TextStyle(color: active ? color : AppTokens.ts, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback      onTap;
  const _NotifTile({required this.notif, required this.onTap});

  Color get _color {
    if (notif.isSuccess) return AppTokens.teal;
    if (notif.isError)   return AppTokens.red;
    return AppTokens.amber;
  }

  IconData get _icon {
    if (notif.isSuccess) return Icons.check_rounded;
    if (notif.isError)   return Icons.close_rounded;
    return Icons.priority_high_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color:        notif.read ? AppTokens.bgCard : AppTokens.bgEl,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.rLg),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              border: Border.all(color: notif.read ? AppTokens.border : AppTokens.borderL),
              borderRadius: BorderRadius.circular(AppTokens.rLg),
            ),
            child: Stack(
              children: [
                if (!notif.read)
                  Positioned(left: -13, top: 0, bottom: 0,
                    child: Container(width: 3, color: _color)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color:        _color.withOpacity(0.18),
                        shape:        BoxShape.circle,
                        border:       Border.all(color: _color.withOpacity(0.4)),
                      ),
                      child: Icon(_icon, color: _color, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(notif.title, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTokens.tp, fontSize: 14, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 6),
                              Text(_relTime(notif.createdAt),
                                style: const TextStyle(color: AppTokens.ts, fontSize: 10)),
                            ],
                          ),
                          if (notif.body != null) ...[
                            const SizedBox(height: 3),
                            Text(notif.body!,
                              style: const TextStyle(color: AppTokens.ts, fontSize: 13, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _relTime(DateTime t) {
  final now = DateTime.now();
  final d = now.difference(t);
  if (d.inMinutes < 1)  return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24)   return '${d.inHours}h';
  return '${d.inDays}d';
}
