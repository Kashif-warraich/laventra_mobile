import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/sub_header.dart';
import '../../lavvaggios/bloc/lavvaggio_bloc.dart';
import '../../lavvaggios/bloc/lavvaggio_event.dart';
import '../../lavvaggios/bloc/lavvaggio_state.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LavvaggioBloc>().add(const LavvaggiosLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: 'Network & Connectivity', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                children: [
                  _Card(
                    title: 'Connection Status',
                    child: BlocBuilder<LavvaggioBloc, LavvaggioState>(
                      builder: (_, state) {
                        final lavs = state is LavvaggiosLoaded ? state.lavvaggios : [];
                        return Column(
                          children: [
                            _Row(label: 'API Server', ok: true, value: 'Connected'),
                            for (final l in lavs)
                              _Row(label: l.name, ok: l.isOnline, value: l.isOnline ? 'Online' : 'Offline'),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    title: 'System Info',
                    child: const Column(
                      children: [
                        _InfoRow(label: 'App Version', value: '1.0.0'),
                        _InfoRow(label: 'API Base',    value: ApiConstants.baseUrl),
                      ],
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

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

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
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final bool   ok;
  final String value;
  const _Row({required this.label, required this.ok, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppTokens.teal : AppTokens.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppTokens.tp, fontSize: 13)),
          ),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 13)),
        Flexible(
          child: Text(value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTokens.tp, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
