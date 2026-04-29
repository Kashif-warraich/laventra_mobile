import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../devices/data/models/device_model.dart';
import '../../events/data/models/event_model.dart';
import '../../notifications/data/models/notification_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

/// Top-level dashboard. All data comes from a single DashboardBloc fan-out.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final firstName = auth is AuthAuthenticated ? auth.user.firstName : '';

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            return RefreshIndicator(
              color:           AppTokens.blue,
              backgroundColor: AppTokens.bgCard,
              onRefresh:       () async {
                context.read<DashboardBloc>().add(const DashboardRefreshRequested());
                await context.read<DashboardBloc>().stream
                    .firstWhere((s) => s is! DashboardLoading);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _Header(firstName: firstName, unreadCount: _unreadFromState(state))),
                  if (state is DashboardLoading)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTokens.blue)))
                  else if (state is DashboardError)
                    SliverFillRemaining(child: EmptyState(icon: Icons.cloud_off_rounded, title: 'Could not load', subtitle: state.message, accent: AppTokens.red))
                  else if (state is DashboardLoaded)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _StatsGrid(state: state),
                          const SizedBox(height: 12),
                          _ActiveDevicesCard(devices: state.devices),
                          const SizedBox(height: 12),
                          _AlertsCard(alerts: state.alerts),
                          const SizedBox(height: 12),
                          _RecentEventsCard(events: state.recentEvents),
                        ]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _unreadFromState(DashboardState s) =>
      s is DashboardLoaded ? s.unreadCount : 0;
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String firstName;
  final int    unreadCount;

  const _Header({required this.firstName, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Row(
        children: [
          const AppLogo(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning${firstName.isNotEmpty ? ", $firstName" : ""}',
                  style: const TextStyle(color: AppTokens.ts, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                const Text('Dashboard',
                  style: TextStyle(color: AppTokens.tp, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          _BellButton(unreadCount: unreadCount),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int unreadCount;
  const _BellButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color:        AppTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppTokens.border),
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.notifications_outlined, color: AppTokens.ts, size: 18)),
            if (unreadCount > 0)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTokens.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stats grid (2x2) ──────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DashboardLoaded state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(label: "TODAY'S WASHES",  value: state.todaysWashes.toString(),       sub: '+ live count',           color: AppTokens.blue),
      _StatCard(label: 'ACTIVE DEVICES',  value: '${state.onlineDevicesCount}/${state.devices.length}', sub: '${state.offlineDevicesCount} offline', color: AppTokens.teal),
      _StatCard(label: 'PENDING ALERTS',  value: state.alerts.length.toString(),       sub: 'Needs review',           color: AppTokens.amber),
      _StatCard(label: 'ERRORS',          value: state.errorEventsToday.toString(),    sub: 'Today',                  color: AppTokens.red),
    ];
    return GridView.count(
      crossAxisCount:    2,
      mainAxisSpacing:   10,
      crossAxisSpacing:  10,
      shrinkWrap:        true,
      physics:           const NeverScrollableScrollPhysics(),
      childAspectRatio:  1.55,
      padding:           const EdgeInsets.symmetric(vertical: 4),
      children:          cards,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color  color;

  const _StatCard({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
          Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
          Text(sub,   style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Active devices ──────────────────────────────────────────────────────────────
class _ActiveDevicesCard extends StatelessWidget {
  final List<DeviceModel> devices;
  const _ActiveDevicesCard({required this.devices});

  @override
  Widget build(BuildContext context) {
    final online  = devices.where((d) => d.isOnline).length;
    final offline = devices.length - online;
    return _SectionCard(
      title:  'Active Devices',
      action: Text('$online online · $offline offline',
        style: const TextStyle(color: AppTokens.ts, fontSize: 11),
      ),
      maxChildHeight: 180,
      child: devices.isEmpty
        ? const _MiniEmpty(label: 'No devices yet')
        : ListView.separated(
            padding:    const EdgeInsets.symmetric(horizontal: 14),
            itemCount:  devices.length,
            separatorBuilder: (_, __) => const Divider(color: AppTokens.border, height: 1),
            itemBuilder: (_, i) {
              final d = devices[i];
              final accent = d.isOnline ? (d.isAi ? AppTokens.purple : AppTokens.blue) : AppTokens.red;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color:        accent.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(d.isAi ? Icons.memory_rounded : Icons.videocam_outlined,
                        size: 16, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.displayName, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 1),
                          Text('${d.lavvaggioName ?? '—'} · ${d.typeLabel}',
                            style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                        ],
                      ),
                    ),
                    StatusPill(label: d.isOnline ? 'On' : 'Off', color: d.isOnline ? AppTokens.teal : AppTokens.red),
                  ],
                ),
              );
            },
          ),
    );
  }
}

// ── Alerts (notifications excerpt) ──────────────────────────────────────────────
class _AlertsCard extends StatelessWidget {
  final List<NotificationModel> alerts;
  const _AlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title:  'Errors & Alerts',
      action: GestureDetector(
        onTap: () => context.push('/notifications'),
        child: const Text('View all', style: TextStyle(color: AppTokens.blueL, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
      maxChildHeight: 150,
      child: alerts.isEmpty
        ? const _MiniEmpty(label: 'No active alerts')
        : ListView.separated(
            padding:   const EdgeInsets.symmetric(horizontal: 14),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const Divider(color: AppTokens.border, height: 1),
            itemBuilder: (_, i) {
              final n     = alerts[i];
              final color = n.isError ? AppTokens.red : AppTokens.amber;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color:        color.withOpacity(0.15),
                        shape:        BoxShape.circle,
                        border:       Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Icon(n.isError ? Icons.close_rounded : Icons.priority_high_rounded,
                        color: color, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w600)),
                          if (n.body != null) ...[
                            const SizedBox(height: 1),
                            Text(n.body!, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                    Text(_relTime(n.createdAt),
                      style: const TextStyle(color: AppTokens.ts, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
    );
  }
}

// ── Recent events ──────────────────────────────────────────────────────────────
class _RecentEventsCard extends StatelessWidget {
  final List<EventModel> events;
  const _RecentEventsCard({required this.events});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Events',
      action: GestureDetector(
        onTap: () => context.go('/events'),
        child: const Text('See all', style: TextStyle(color: AppTokens.blueL, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
      maxChildHeight: 220,
      child: events.isEmpty
        ? const _MiniEmpty(label: 'No events yet')
        : ListView.separated(
            padding:   const EdgeInsets.symmetric(horizontal: 14),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(color: AppTokens.border, height: 1),
            itemBuilder: (_, i) {
              final e     = events[i];
              final color = e.isSuccess ? AppTokens.teal : AppTokens.red;
              return InkWell(
                onTap: () => context.push('/events/${e.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.directions_car_rounded, color: color, size: 17),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.vehiclePlate,
                              style: const TextStyle(color: AppTokens.tp, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                            const SizedBox(height: 1),
                            Text('${e.formattedStartTime} · ${e.deviceName ?? e.deviceSerial ?? "—"}',
                              style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                          ],
                        ),
                      ),
                      StatusPill(label: e.isSuccess ? 'Done' : 'Err', color: color),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}

// ── Reusable wrappers ──────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final double maxChildHeight;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.maxChildHeight,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg + 2),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AppTokens.tp, fontSize: 14, fontWeight: FontWeight.w800)),
                if (action != null) action!,
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxChildHeight),
            child: child,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  final String label;
  const _MiniEmpty({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 12)),
    ),
  );
}

String _relTime(DateTime t) {
  final now = DateTime.now();
  final d = now.difference(t);
  if (d.inMinutes < 1)   return 'now';
  if (d.inMinutes < 60)  return '${d.inMinutes}m';
  if (d.inHours < 24)    return '${d.inHours}h';
  return '${d.inDays}d';
}
