import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import '../../devices/bloc/device_bloc.dart';
import '../../devices/bloc/device_event.dart';
import '../../devices/bloc/device_state.dart';
import '../../devices/data/models/device_model.dart';
import '../bloc/lavvaggio_bloc.dart';
import '../bloc/lavvaggio_event.dart';
import '../bloc/lavvaggio_state.dart';
import '../data/models/lavvaggio_model.dart';

class LavaggiScreen extends StatefulWidget {
  const LavaggiScreen({super.key});

  @override
  State<LavaggiScreen> createState() => _LavaggiScreenState();
}

class _LavaggiScreenState extends State<LavaggiScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LavvaggioBloc>().add(const LavvaggiosLoadRequested());
    context.read<DeviceBloc>().add(const DevicesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lavaggi',
                          style: TextStyle(color: AppTokens.tp, fontSize: 22, fontWeight: FontWeight.w800)),
                        SizedBox(height: 3),
                        Text('Manage your car wash points',
                          style: TextStyle(color: AppTokens.ts, fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AppAlerts.info(context, 'Adding lavaggi is admin-only — use the web dashboard'),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTokens.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<LavvaggioBloc, LavvaggioState>(
                builder: (context, lavState) {
                  if (lavState is LavvaggioLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppTokens.blue));
                  }
                  if (lavState is LavvaggioError) {
                    return EmptyState(icon: Icons.cloud_off_rounded, title: 'Failed to load', subtitle: lavState.message, accent: AppTokens.red);
                  }
                  if (lavState is LavvaggiosLoaded) {
                    if (lavState.lavvaggios.isEmpty) {
                      return const EmptyState(icon: Icons.local_car_wash_rounded, title: 'No lavaggi yet', subtitle: 'Ask an admin to set one up for you');
                    }
                    return RefreshIndicator(
                      color: AppTokens.blue,
                      backgroundColor: AppTokens.bgCard,
                      onRefresh: () async {
                        context.read<LavvaggioBloc>().add(const LavvaggioRefreshRequested());
                        context.read<DeviceBloc>().add(const DevicesRefreshRequested());
                        await context.read<LavvaggioBloc>().stream.firstWhere((s) => s is! LavvaggioLoading);
                      },
                      child: BlocBuilder<DeviceBloc, DeviceState>(
                        builder: (context, devState) {
                          final allDevices = devState is DevicesLoaded ? devState.devices : <DeviceModel>[];
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                            itemCount: lavState.lavvaggios.length,
                            itemBuilder: (_, i) {
                              final lav     = lavState.lavvaggios[i];
                              final devices = allDevices.where((d) => d.lavvaggioId == lav.id).toList();
                              return _LavaggioCard(lavvaggio: lav, devices: devices);
                            },
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LavaggioCard extends StatelessWidget {
  final LavvaggioModel    lavvaggio;
  final List<DeviceModel> devices;

  const _LavaggioCard({required this.lavvaggio, required this.devices});

  @override
  Widget build(BuildContext context) {
    final operational = lavvaggio.isOnline ? AppTokens.teal : AppTokens.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg + 2),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color:        operational.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.local_car_wash_rounded, color: operational, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lavvaggio.name, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTokens.tp, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTokens.ts, size: 11),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('${lavvaggio.address}, ${lavvaggio.city}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTokens.ts, fontSize: 11.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusPill(label: lavvaggio.isOnline ? 'ONLINE' : 'OFFLINE', color: operational),
            ],
          ),
          const SizedBox(height: 12),
          // Device chips (horizontal scrollable)
          if (devices.isNotEmpty)
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:       devices.length,
                separatorBuilder:(_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final d  = devices[i];
                  final cc = d.isOnline ? (d.isAi ? AppTokens.purple : AppTokens.blue) : AppTokens.red;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        AppTokens.bgEl,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(d.isAi ? Icons.memory_rounded : Icons.videocam_outlined,
                          size: 12, color: cc),
                        const SizedBox(width: 5),
                        Text(d.displayName,
                          style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                        const SizedBox(width: 5),
                        Container(width: 5, height: 5,
                          decoration: BoxDecoration(color: cc, shape: BoxShape.circle)),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (devices.isNotEmpty) const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _stat('Today',   lavvaggio.todayWashes.toString()),
              _stat('Monthly', lavvaggio.monthlyWashes.toString()),
              _stat('Devices', '${lavvaggio.aiCount + lavvaggio.cameraCount}'),
            ],
          ),
          const SizedBox(height: 12),
          // Buttons
          Row(
            children: [
              Expanded(child: _button(context, Icons.settings_rounded, 'Settings',
                () => context.push('/lavaggi/${lavvaggio.id}/settings', extra: lavvaggio))),
              const SizedBox(width: 8),
              Expanded(child: _button(context, Icons.videocam_outlined, 'Cameras',
                () => AppAlerts.info(context, 'Live cameras at ${lavvaggio.name}'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:        AppTokens.bgEl,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppTokens.tp, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 10)),
        ],
      ),
    ),
  );

  Widget _button(BuildContext context, IconData icon, String label, VoidCallback onTap) => Material(
    color:        AppTokens.blue.withOpacity(0.13),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border:       Border.all(color: AppTokens.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTokens.blueL, size: 14),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: AppTokens.blueL, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ),
  );
}
