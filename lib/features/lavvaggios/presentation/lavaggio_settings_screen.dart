import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/sub_header.dart';
import '../bloc/lavvaggio_bloc.dart';
import '../bloc/lavvaggio_event.dart';
import '../bloc/lavvaggio_state.dart';
import '../data/models/lavvaggio_model.dart';
import '../../devices/bloc/device_bloc.dart';
import '../../devices/bloc/device_event.dart';
import '../../devices/bloc/device_state.dart';
import '../../devices/data/models/device_model.dart';

class LavaggioSettingsScreen extends StatefulWidget {
  final LavvaggioModel lavvaggio;
  const LavaggioSettingsScreen({super.key, required this.lavvaggio});

  @override
  State<LavaggioSettingsScreen> createState() => _LavaggioSettingsScreenState();
}

class _LavaggioSettingsScreenState extends State<LavaggioSettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.lavvaggio.name);
    _addrCtrl = TextEditingController(text: widget.lavvaggio.address);
    context.read<DeviceBloc>().add(DevicesLoadRequested(lavvaggioId: widget.lavvaggio.id));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<LavvaggioBloc>().add(LavvaggioUpdateRequested(
      lavvaggioId: widget.lavvaggio.id,
      data: {
        'name':    _nameCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: '${widget.lavvaggio.name} Settings', onBack: () => context.pop()),
            Expanded(
              child: BlocListener<LavvaggioBloc, LavvaggioState>(
                listener: (context, state) {
                  if (state is LavvaggioUpdateSuccess) {
                    AppAlerts.success(context, 'Settings saved');
                  } else if (state is LavvaggioError) {
                    AppAlerts.error(context, state.message);
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  children: [
                    _SectionCard(
                      title: 'Location Info',
                      children: [
                        _Field(label: 'Name',    controller: _nameCtrl),
                        const SizedBox(height: 12),
                        _Field(label: 'Address', controller: _addrCtrl),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DevicesCard(lavvaggioId: widget.lavvaggio.id),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Stats',
                      children: [
                        _statRow('Today',     '${widget.lavvaggio.todayWashes}'),
                        _statRow('This month', '${widget.lavvaggio.monthlyWashes}'),
                        _statRow('AI devices',     '${widget.lavvaggio.aiCount}'),
                        _statRow('Cameras',        '${widget.lavvaggio.cameraCount}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<LavvaggioBloc, LavvaggioState>(
                      buildWhen: (_, s) => s is LavvaggioUpdating || s is LavvaggioUpdateSuccess || s is LavvaggioError,
                      builder: (context, state) {
                        final saving = state is LavvaggioUpdating;
                        return SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTokens.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: saving
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                              : const Text('Save Changes',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        onPressed: () async {
                          final ok = await ConfirmDialog.show(
                            context,
                            title:        'Remove Location',
                            message:      'Remove "${widget.lavvaggio.name}"? This action cannot be undone.',
                            confirmLabel: 'Remove',
                            destructive:  true,
                          );
                          if (ok == true && context.mounted) {
                            AppAlerts.info(context, 'Lavaggio removal is admin-only — use the web dashboard');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTokens.red.withOpacity(0.12),
                          foregroundColor: AppTokens.red,
                          side: BorderSide(color: AppTokens.red.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Remove Location',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _DevicesCard extends StatelessWidget {
  final int lavvaggioId;
  const _DevicesCard({required this.lavvaggioId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (_, state) {
        final devices = state is DevicesLoaded
          ? state.devices.where((d) => d.lavvaggioId == lavvaggioId).toList()
          : <DeviceModel>[];
        return _SectionCard(
          title: 'Devices (${devices.length})',
          children: devices.isEmpty
            ? [const _Empty(label: 'No devices linked')]
            : List.generate(devices.length * 2 - 1, (i) {
                if (i.isOdd) return const Divider(color: AppTokens.border, height: 1);
                final d = devices[i ~/ 2];
                final color = d.isOnline ? (d.isAi ? AppTokens.purple : AppTokens.blue) : AppTokens.red;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(d.isAi ? Icons.memory_rounded : Icons.videocam_outlined,
                          size: 16, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.displayName,
                              style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 1),
                            Text(d.ipAddress ?? d.serialNumber,
                              style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  final String                 label;
  final TextEditingController  controller;
  const _Field({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: const TextStyle(color: AppTokens.ts, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style:      const TextStyle(color: AppTokens.tp),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String        title;
  final List<Widget>  children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String label;
  const _Empty({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(child: Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 12))),
  );
}
