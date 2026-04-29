import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/sub_header.dart';
import '../data/models/event_model.dart';
import '../data/repositories/event_repository.dart';

/// Loaded by id. Self-fetches via EventRepository so this route can be
/// linked to from anywhere (dashboard, events list, notification deep-link).
class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _repo = EventRepository();
  EventModel? _event;
  String?     _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final e = await _repo.getEvent(widget.eventId);
      if (mounted) setState(() => _event = e);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load event');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title:  _event != null ? 'Event #${_event!.id}' : 'Event Detail',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _error != null
                ? EmptyState(icon: Icons.cloud_off_rounded, title: 'Failed to load', subtitle: _error, accent: AppTokens.red)
                : _event == null
                  ? const Center(child: CircularProgressIndicator(color: AppTokens.blue))
                  : _Body(event: _event!),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final EventModel event;
  const _Body({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event.isSuccess ? AppTokens.teal : AppTokens.red;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        // Snapshot placeholder
        Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0A1A2E), Color(0xFF0D2540)],
            ),
            borderRadius: BorderRadius.circular(AppTokens.rLg),
            border:       Border.all(color: AppTokens.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_outlined, color: AppTokens.tm, size: 32),
              const SizedBox(height: 6),
              Text('${event.deviceName ?? event.deviceSerial ?? "—"} · SNAPSHOT',
                style: const TextStyle(color: AppTokens.tm, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Plate display + confidence
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color:        AppTokens.bgCard,
            borderRadius: BorderRadius.circular(AppTokens.rLg),
            border:       Border.all(color: AppTokens.border),
          ),
          child: Column(
            children: [
              const Text('DETECTED PLATE',
                style: TextStyle(color: AppTokens.ts, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [AppTokens.blue, Color(0xFF8BBFFF)],
                ).createShader(rect),
                child: Text(event.vehiclePlate,
                  style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800,
                    fontFamily: 'monospace', letterSpacing: 4, color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: color, size: 14),
                  const SizedBox(width: 5),
                  Text('AI Confidence: ${event.formattedConfidence}',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              StatusPill.byType(event.status, label: event.status, fontSize: 10),
            ],
          ),
        ),
        const SizedBox(height: 8),

        _row('Location', event.lavvaggioName ?? '—'),
        _row('Date',     event.formattedDate),
        _row('Time',     '${event.formattedStartTime} → ${event.formattedEndTime}'),
        _row('Camera',   event.deviceName ?? event.deviceSerial ?? '—'),
        _row('Duration', event.formattedDuration),
        _row('Vehicle',  event.vehicleType),

        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _action(context, 'Export', AppTokens.blue,
              () => AppAlerts.success(context, 'Event exported to PDF'))),
            const SizedBox(width: 10),
            Expanded(child: _action(context, 'Review', AppTokens.amber,
              () => AppAlerts.warning(context, 'Flagged for manual review'))),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Container(
    margin:  const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color:        AppTokens.bgCard,
      borderRadius: BorderRadius.circular(AppTokens.rMd + 1),
      border:       Border.all(color: AppTokens.border),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _action(BuildContext context, String label, Color color, VoidCallback onTap) => Material(
    color:        color.withOpacity(0.18),
    borderRadius: BorderRadius.circular(AppTokens.rLg),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.rLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border:       Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(AppTokens.rLg),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    ),
  );
}
