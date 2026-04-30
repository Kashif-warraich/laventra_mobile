import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import '../../lavvaggios/bloc/lavvaggio_bloc.dart';
import '../../lavvaggios/bloc/lavvaggio_event.dart';
import '../../lavvaggios/bloc/lavvaggio_state.dart';
import '../bloc/event_bloc.dart';
import '../bloc/event_event.dart';
import '../bloc/event_state.dart';
import '../data/models/event_model.dart';

enum _DateFilter { today, week, month, custom }

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _searchCtrl = TextEditingController();
  _DateFilter _dateFilter = _DateFilter.today;
  String?     _statusFilter;        // null = all, else 'success' | 'error'
  int?        _lavvaggioFilter;     // null = all
  DateTime    _customFrom = DateTime.now().subtract(const Duration(days: 7));
  DateTime    _customTo   = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<LavvaggioBloc>().add(const LavvaggiosLoadRequested());
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    final range = _resolveRange();
    context.read<EventBloc>().add(EventsLoadRequested(
      lavvaggioId: _lavvaggioFilter,
      from:        range?.from.toIso8601String(),
      to:          range?.to.toIso8601String(),
      status:      _statusFilter,
      search:      _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    ));
  }

  ({DateTime from, DateTime to})? _resolveRange() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case _DateFilter.today:
        return (from: DateTime(now.year, now.month, now.day), to: now);
      case _DateFilter.week:
        return (from: now.subtract(const Duration(days: 7)), to: now);
      case _DateFilter.month:
        return (from: DateTime(now.year, now.month, 1), to: now);
      case _DateFilter.custom:
        return (from: _customFrom, to: _customTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Events',
                  style: TextStyle(color: AppTokens.tp, fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            _SearchBar(controller: _searchCtrl, onChanged: (_) => _reload()),
            const SizedBox(height: 10),
            _FilterRow(
              dateFilter:       _dateFilter,
              statusFilter:     _statusFilter,
              lavvaggioFilter:  _lavvaggioFilter,
              onDateChanged:    (f) => setState(() { _dateFilter = f; _reload(); }),
              onStatusChanged:  (s) => setState(() { _statusFilter = s; _reload(); }),
              onLavChanged:     (l) => setState(() { _lavvaggioFilter = l; _reload(); }),
              onCustomTap:      _pickCustomRange,
            ),
            if (_dateFilter == _DateFilter.custom)
              _RangeSummary(from: _customFrom, to: _customTo),
            const SizedBox(height: 6),
            Expanded(
              child: BlocBuilder<EventBloc, EventState>(
                builder: (context, s) {
                  if (s is EventLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppTokens.blue));
                  }
                  if (s is EventError) {
                    return EmptyState(icon: Icons.cloud_off_rounded, title: 'Failed to load', subtitle: s.message, accent: AppTokens.red);
                  }
                  if (s is EventsLoaded) {
                    if (s.events.isEmpty) {
                      return const EmptyState(icon: Icons.search_off_rounded, title: 'No events match', subtitle: 'Try a different range or filter');
                    }
                    return RefreshIndicator(
                      color: AppTokens.blue,
                      backgroundColor: AppTokens.bgCard,
                      onRefresh: () async {
                        _reload();
                        await context.read<EventBloc>().stream.firstWhere((s) => s is! EventLoading);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                        itemCount: s.events.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10, left: 4),
                              child: Text('${s.events.length} event${s.events.length == 1 ? '' : 's'}',
                                style: const TextStyle(color: AppTokens.ts, fontSize: 12)),
                            );
                          }
                          final e = s.events[i - 1];
                          return _EventCard(event: e);
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

  Future<void> _pickCustomRange() async {
    final res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate:  DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _customFrom, end: _customTo),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor:  AppTokens.blue,
              brightness: Brightness.dark,
            ),
            dialogBackgroundColor: AppTokens.bgCard,
          ),
          child: child!,
        );
      },
    );
    if (res != null) {
      setState(() {
        _customFrom = res.start;
        _customTo   = res.end;
        _dateFilter = _DateFilter.custom;
        _reload();
      });
    }
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController  controller;
  final ValueChanged<String>   onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged:  onChanged,
        style: const TextStyle(color: AppTokens.tp),
        decoration: const InputDecoration(
          hintText:   'Search plate or location…',
          prefixIcon: Icon(Icons.search_rounded, color: AppTokens.ts, size: 18),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _DateFilter            dateFilter;
  final String?                statusFilter;
  final int?                   lavvaggioFilter;
  final ValueChanged<_DateFilter> onDateChanged;
  final ValueChanged<String?>     onStatusChanged;
  final ValueChanged<int?>        onLavChanged;
  final VoidCallback              onCustomTap;

  const _FilterRow({
    required this.dateFilter,
    required this.statusFilter,
    required this.lavvaggioFilter,
    required this.onDateChanged,
    required this.onStatusChanged,
    required this.onLavChanged,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:         const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('Today',  dateFilter == _DateFilter.today,  () => onDateChanged(_DateFilter.today)),
          _chip('Week',   dateFilter == _DateFilter.week,   () => onDateChanged(_DateFilter.week)),
          _chip('Month',  dateFilter == _DateFilter.month,  () => onDateChanged(_DateFilter.month)),
          _chipIcon(Icons.calendar_month_rounded, 'Range',
            dateFilter == _DateFilter.custom, onCustomTap),
          const SizedBox(width: 8),
          _statusChip('All',     null,        statusFilter == null,        AppTokens.blue, onStatusChanged),
          _statusChip('Success', 'success',  statusFilter == 'success',   AppTokens.teal, onStatusChanged),
          _statusChip('Error',   'error',    statusFilter == 'error',     AppTokens.red,  onStatusChanged),
          const SizedBox(width: 8),
          _LavDropdown(value: lavvaggioFilter, onChanged: onLavChanged),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color:        active ? AppTokens.blue : AppTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: active ? AppTokens.blue : AppTokens.border),
        ),
        child: Text(label,
          style: TextStyle(
            color:      active ? Colors.white : AppTokens.ts,
            fontSize:   12, fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );

  Widget _chipIcon(IconData icon, String label, bool active, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:        active ? AppTokens.blue.withOpacity(0.18) : AppTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: active ? AppTokens.blue : AppTokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? AppTokens.blue : AppTokens.ts),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              color: active ? AppTokens.blue : AppTokens.ts, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );

  Widget _statusChip(String label, String? value, bool active, Color color, ValueChanged<String?> on) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => on(value),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:        active ? color.withOpacity(0.18) : AppTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: active ? color : AppTokens.border),
        ),
        child: Text(label, style: TextStyle(
          color: active ? color : AppTokens.ts, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ),
  );
}

class _LavDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const _LavDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LavvaggioBloc, LavvaggioState>(
      builder: (_, s) {
        final lavs = s is LavvaggiosLoaded ? s.lavvaggios : <dynamic>[];
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:        AppTokens.bgCard,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: AppTokens.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value:    value,
              dropdownColor: AppTokens.bgCard,
              icon:     const Icon(Icons.keyboard_arrow_down_rounded, color: AppTokens.ts, size: 16),
              style:    const TextStyle(color: AppTokens.ts, fontSize: 12, fontWeight: FontWeight.w700),
              hint:     const Text('All Lavaggi', style: TextStyle(color: AppTokens.ts, fontSize: 12, fontWeight: FontWeight.w700)),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(value: null, child: Text('All Lavaggi')),
                for (final l in lavs)
                  DropdownMenuItem<int?>(value: l.id as int, child: Text(l.name as String)),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

class _RangeSummary extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  const _RangeSummary({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Text('Range: ${fmt.format(from)} → ${fmt.format(to)}',
        style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event.isSuccess ? AppTokens.teal : AppTokens.red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.rLg),
          onTap:        () => context.push('/events/${event.id}'),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              border:       Border.all(color: AppTokens.border),
              borderRadius: BorderRadius.circular(AppTokens.rLg),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color:        color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.directions_car_rounded, color: color, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.vehiclePlate,
                            style: const TextStyle(color: AppTokens.tp, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                          const SizedBox(height: 1),
                          Text('${event.formattedDate} · ${event.formattedStartTime}',
                            style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                        ],
                      ),
                    ),
                    StatusPill.byType(event.status),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: AppTokens.border, height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppTokens.ts, size: 12),
                    const SizedBox(width: 4),
                    Text(event.lavvaggioName ?? '—',
                      style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                    const Spacer(),
                    Text('${event.deviceName ?? event.deviceSerial ?? '—'} · ${event.formattedConfidence}',
                      style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
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
