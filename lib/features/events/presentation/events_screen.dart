import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/event_bloc.dart';
import '../bloc/event_event.dart';
import '../bloc/event_state.dart';
import '../data/models/event_model.dart';
import '../../lavvaggios/data/models/lavvaggio_model.dart';
import '../../lavvaggios/data/repositories/lavvaggio_repository.dart';
import '../../../../core/theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {

  String         _dateFilter            = 'today';
  DateTimeRange? _customRange;
  int?           _selectedLavvaggioId;
  String?        _selectedLavvaggioName;

  List<LavvaggioModel> _lavvaggios        = [];
  bool                 _lavvaggiosLoading = true;

  // Cached events list — kept across EventCompleting so the UI does not flicker
  List<EventModel> _cachedEvents = [];
  bool             _hasNextPage  = false;

  final _searchCtrl   = TextEditingController();
  String _searchQuery = '';
  bool   _showSearch  = false;

  @override
  void initState() {
    super.initState();
    _loadLavvaggios();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLavvaggios() async {
    try {
      final result = await LavvaggioRepository().getLavvaggios();
      setState(() {
        _lavvaggios        = result.data;
        _lavvaggiosLoading = false;
      });
    } catch (_) {
      setState(() => _lavvaggiosLoading = false);
    }
  }

  Map<String, String> _getDateRange() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_dateFilter == 'custom' && _customRange != null) {
      return {
        'from': _customRange!.start.toIso8601String(),
        'to':   _customRange!.end
            .add(const Duration(hours: 23, minutes: 59))
            .toIso8601String(),
      };
    }

    return switch (_dateFilter) {
      'today' => {
        'from': today.toIso8601String(),
        'to':   now.toIso8601String(),
      },
      'week' => {
        'from': today.subtract(const Duration(days: 7)).toIso8601String(),
        'to':   now.toIso8601String(),
      },
      'month' => {
        'from': today.subtract(const Duration(days: 30)).toIso8601String(),
        'to':   now.toIso8601String(),
      },
      _ => {
        'from': today.toIso8601String(),
        'to':   now.toIso8601String(),
      },
    };
  }

  void _loadEvents() {
    final range = _getDateRange();
    context.read<EventBloc>().add(
      EventsLoadRequested(
        lavvaggioId: _selectedLavvaggioId,
        from:        range['from'],
        to:          range['to'],
      ),
    );
  }

  Future<void> _onRefresh() async {
    final range = _getDateRange();
    context.read<EventBloc>().add(
      EventsRefreshRequested(
        lavvaggioId: _selectedLavvaggioId,
        from:        range['from'],
        to:          range['to'],
      ),
    );
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(2020),
      lastDate:         DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColors.primary,
            onPrimary: Colors.white,
            surface:   AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _dateFilter  = 'custom';
      });
      _loadEvents();
    }
  }

  List<EventModel> _filterEvents(List<EventModel> events) {
    if (_searchQuery.isEmpty) return events;
    final q = _searchQuery.toLowerCase();
    return events.where((e) {
      return e.vehiclePlate.toLowerCase().contains(q) ||
          e.vehicleType.toLowerCase().contains(q)  ||
          (e.lavvaggioName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  String _customRangeLabel() {
    if (_customRange == null) return 'Custom';
    final s = _customRange!.start;
    final e = _customRange!.end;
    return '${s.day}/${s.month} – ${e.day}/${e.month}';
  }

  void _clearLavvaggioFilter() {
    setState(() {
      _selectedLavvaggioId   = null;
      _selectedLavvaggioName = null;
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [

          SliverAppBar(
            floating:        true,
            snap:            true,
            backgroundColor: AppColors.dark,
            title: _showSearch
                ? TextField(
              controller: _searchCtrl,
              autofocus:  true,
              style:      const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:       'Search plate, type...',
                hintStyle:      TextStyle(color: Colors.white.withOpacity(0.5)),
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
                : const Text('Events', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                onPressed: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }
                }),
                icon: Icon(
                  _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _showLavvaggioFilter,
                icon: Stack(
                  children: [
                    const Icon(Icons.filter_list_rounded, color: Colors.white),
                    if (_selectedLavvaggioId != null)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Date chips ──
          SliverToBoxAdapter(
            child: Container(
              color:   AppColors.dark,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _DateChips(
                selected:    _dateFilter,
                customLabel: _dateFilter == 'custom' ? _customRangeLabel() : null,
                onChanged: (val) {
                  if (val == 'custom') {
                    _pickCustomRange();
                  } else {
                    setState(() => _dateFilter = val);
                    _loadEvents();
                  }
                },
              ),
            ),
          ),
        ],

        body: BlocConsumer<EventBloc, EventState>(
          listener: (context, state) {
            if (state is EventsLoaded) {
              setState(() {
                _cachedEvents = state.events;
                _hasNextPage  = state.meta.hasNextPage;
              });
            } else if (state is EventCompleted) {
              setState(() => _cachedEvents = state.updatedEvents);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:         Text('Wash marked as complete'),
                  backgroundColor: AppColors.success,
                  duration:        Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {

            if (state is EventInitial || state is EventLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is EventError) {
              return _ErrorView(message: state.message, onRetry: _loadEvents);
            }

            // For any loaded/completing/completed state, render the events UI
            if (state is EventsLoaded   ||
                state is EventCompleting ||
                state is EventCompleted) {
              final int? completingEventId = state is EventCompleting
                  ? state.eventId
                  : null;
              final filtered = _filterEvents(_cachedEvents);

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  slivers: [

                    // ── Stats bar (total only) ──
                    SliverToBoxAdapter(
                      child: _StatsBar(
                        total:         _cachedEvents.length,
                        dateFilter:    _dateFilter,
                        customRange:   _customRange,
                        lavvaggioName: _selectedLavvaggioName,
                      ),
                    ),

                    // ── Active filter chips ──
                    if (_selectedLavvaggioId != null || _searchQuery.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _ActiveFilters(
                          lavvaggioName: _selectedLavvaggioName,
                          searchQuery:   _searchQuery.isNotEmpty ? _searchQuery : null,
                          onClearLavvaggio: _clearLavvaggioFilter,
                          onClearSearch: () => setState(() {
                            _searchQuery = '';
                            _searchCtrl.clear();
                            _showSearch  = false;
                          }),
                        ),
                      ),

                    if (filtered.isEmpty)
                      const SliverFillRemaining(child: _EmptyView())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver:  _GroupedEventList(
                          events:            filtered,
                          completingEventId: completingEventId,
                        ),
                      ),

                    // ── Load More ──
                    if (_hasNextPage)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          child: OutlinedButton(
                            onPressed: _loadEvents,
                            child: const Text('Load More'),
                          ),
                        ),
                      )
                    else
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showLavvaggioFilter() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _LavvaggioFilterSheet(
        lavvaggios: _lavvaggios,
        isLoading:  _lavvaggiosLoading,
        selectedId: _selectedLavvaggioId,
        onSelect: (lav) {
          setState(() {
            _selectedLavvaggioId   = lav?.id;
            _selectedLavvaggioName = lav?.name;
          });
          Navigator.pop(context);
          _loadEvents();
        },
      ),
    );
  }
}

// ── Date Chips ────────────────────────────────────────────────────────────────
class _DateChips extends StatelessWidget {
  final String               selected;
  final String?              customLabel;
  final ValueChanged<String> onChanged;

  const _DateChips({
    required this.selected,
    required this.onChanged,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('today', 'Today', null),
      ('week',  'Week',  null),
      ('month', 'Month', null),
      ('custom', customLabel ?? 'Custom', Icons.date_range_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (f.$3 != null) ...[
                      Icon(f.$3,
                        size:  13,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      f.$2,
                      style: TextStyle(
                        color:      isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Stats Bar (total + period label only) ─────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final int            total;
  final String         dateFilter;
  final DateTimeRange? customRange;
  final String?        lavvaggioName;

  const _StatsBar({
    required this.total,
    required this.dateFilter,
    this.customRange,
    this.lavvaggioName,
  });

  String get _period => switch (dateFilter) {
    'today'  => 'Today',
    'week'   => 'Last 7 days',
    'month'  => 'Last 30 days',
    'custom' => customRange != null
        ? '${customRange!.start.day}/${customRange!.start.month} – '
        '${customRange!.end.day}/${customRange!.end.month}'
        : 'Selected period',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF0F172A), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _period,
                style: TextStyle(
                  color:      Colors.white.withOpacity(0.7),
                  fontSize:   12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (lavvaggioName != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lavvaggioName!,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   36,
                  fontWeight: FontWeight.w800,
                  height:     1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 6),
                child: Text(
                  'washes',
                  style: TextStyle(
                    color:    Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active Filters ────────────────────────────────────────────────────────────
class _ActiveFilters extends StatelessWidget {
  final String?      lavvaggioName;
  final String?      searchQuery;
  final VoidCallback onClearLavvaggio;
  final VoidCallback onClearSearch;

  const _ActiveFilters({
    this.lavvaggioName,
    this.searchQuery,
    required this.onClearLavvaggio,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (lavvaggioName != null)
            _FilterChip(label: lavvaggioName!, icon: Icons.store_rounded, onClear: onClearLavvaggio),
          if (searchQuery != null)
            _FilterChip(label: '"$searchQuery"', icon: Icons.search_rounded, onClear: onClearSearch),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final VoidCallback onClear;

  const _FilterChip({required this.label, required this.icon, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Grouped Event List ────────────────────────────────────────────────────────
class _GroupedEventList extends StatelessWidget {
  final List<EventModel> events;
  final int?             completingEventId;
  const _GroupedEventList({required this.events, this.completingEventId});

  Map<String, List<EventModel>> _groupByDate() {
    final grouped = <String, List<EventModel>>{};
    for (final e in events) {
      grouped.putIfAbsent(e.formattedDate, () => []).add(e);
    }
    return grouped;
  }

  String _todayLabel() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/'
        '${n.month.toString().padLeft(2, '0')}/'
        '${n.year}';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates   = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final date    = dates[index];
          final dayEvs  = grouped[date]!;
          final isToday = date == _todayLabel();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color:        isToday ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isToday ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isToday) ...[
                            const Icon(Icons.circle, size: 7, color: AppColors.primary),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isToday ? 'Today  $date' : date,
                            style: TextStyle(
                              color:      isToday ? AppColors.primary : AppColors.textSecondary,
                              fontSize:   12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dayEvs.length} wash${dayEvs.length == 1 ? '' : 'es'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ...dayEvs.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:   _EventCard(
                  event:       e,
                  isCompleting: completingEventId == e.id,
                ),
              )),
            ],
          );
        },
        childCount: dates.length,
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool       isCompleting;
  const _EventCard({required this.event, this.isCompleting = false});

  Color get _typeColor => switch (event.vehicleType.toLowerCase()) {
    'sedan' => const Color(0xFF3B82F6),
    'suv'   => const Color(0xFF8B5CF6),
    'truck' => const Color(0xFFF59E0B),
    'van'   => const Color(0xFF10B981),
    _       => AppColors.primary,
  };

  String _vehicleEmoji(String type) => switch (type.toLowerCase()) {
    'sedan' => '🚗',
    'suv'   => '🚙',
    'truck' => '🚚',
    'van'   => '🚐',
    'bike'  => '🏍️',
    _       => '🚘',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji badge
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color:        _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(_vehicleEmoji(event.vehicleType), style: const TextStyle(fontSize: 20)),
                  ),
                ),

                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.vehiclePlate,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontSize:   15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:        _typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.vehicleType.toUpperCase(),
                              style: TextStyle(color: _typeColor, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            event.completed
                                ? '${event.formattedStartTime} → ${event.formattedEndTime}'
                                : 'Started ${event.formattedStartTime}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      if (event.lavvaggioName != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.store_outlined, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              event.lavvaggioName!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Duration (right side — only if completed)
                if (event.completed && event.durationSeconds != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      event.formattedDuration,
                      style: const TextStyle(
                        color:      AppColors.textSecondary,
                        fontSize:   12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Complete Wash button — only for in-progress events ──
            if (!event.completed) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: isCompleting
                    ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: () => _showCompleteConfirmation(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side:            const BorderSide(color: AppColors.success),
                          padding:         const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize:     Size.zero,
                          tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
                          shape:           RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Complete Wash',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCompleteConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Mark as Complete'),
        content: const Text('Mark this wash as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child:     const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<EventBloc>().add(EventCompleteRequested(event.id));
      }
    });
  }
}

// ── Lavvaggio Filter Sheet ────────────────────────────────────────────────────
class _LavvaggioFilterSheet extends StatelessWidget {
  final List<LavvaggioModel>          lavvaggios;
  final bool                          isLoading;
  final int?                          selectedId;
  final ValueChanged<LavvaggioModel?> onSelect;

  const _LavvaggioFilterSheet({
    required this.lavvaggios,
    required this.isLoading,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filter by Lavvaggio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _SheetOption(label: 'All Lavvaggios', isSelected: selectedId == null, icon: Icons.store_rounded, onTap: () => onSelect(null)),
          const Divider(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ...lavvaggios.map((lav) => _SheetOption(
              label:       lav.name,
              subtitle:    lav.city,
              isSelected:  selectedId == lav.id,
              icon:        Icons.local_car_wash_rounded,
              statusColor: lav.isActive ? AppColors.success : AppColors.error,
              onTap:       () => onSelect(lav),
            )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String       label;
  final String?      subtitle;
  final bool         isSelected;
  final IconData     icon;
  final Color?       statusColor;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin:  const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:      isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (statusColor != null)
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_outlined, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text('No events found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('Try changing the date or filter', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}