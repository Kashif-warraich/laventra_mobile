import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bloc/lavvaggio_bloc.dart';
import '../bloc/lavvaggio_event.dart';
import '../bloc/lavvaggio_state.dart';
import '../data/models/lavvaggio_model.dart';
import '../data/models/lavvaggio_stats_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

class LavvaggioDetailScreen extends StatefulWidget {
  final LavvaggioModel lavvaggio;
  const LavvaggioDetailScreen({super.key, required this.lavvaggio});

  @override
  State<LavvaggioDetailScreen> createState() => _LavvaggioDetailScreenState();
}

class _LavvaggioDetailScreenState extends State<LavvaggioDetailScreen> {
  // Edit
  final _formKey     = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _countryCtrl;
  String _selectedStatus = 'active';
  bool   _editMode       = false;

  // Events + filter
  List<Map<String, dynamic>> _events        = [];
  bool                       _eventsLoading = true;
  String                     _dateFilter    = 'today';
  DateTimeRange?             _customRange;

  // Stats
  LavvaggioStats? _stats;
  bool            _statsLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.lavvaggio.name);
    _addressCtrl = TextEditingController(text: widget.lavvaggio.address);
    _cityCtrl    = TextEditingController(text: widget.lavvaggio.city);
    _countryCtrl = TextEditingController(text: widget.lavvaggio.country);
    _selectedStatus = widget.lavvaggio.status;

    // Load fresh lavvaggio detail from API
    context.read<LavvaggioBloc>().add(
      LavvaggioDetailLoadRequested(widget.lavvaggio.id),
    );

    _loadEvents();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  // Sync form fields when bloc loads fresh data
  void _syncForm(LavvaggioModel lav) {
    _nameCtrl.text    = lav.name;
    _addressCtrl.text = lav.address;
    _cityCtrl.text    = lav.city;
    _countryCtrl.text = lav.country;
    _selectedStatus   = lav.status;
  }

  // ── Date range ──
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

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context:         context,
      firstDate:       DateTime(2020),
      lastDate:        DateTime.now(),
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

  Future<void> _loadEvents() async {
    setState(() {
      _eventsLoading = true;
      _statsLoading  = true;
    });

    final range = _getDateRange();

    // Dispatch stats load via BLoC
    context.read<LavvaggioBloc>().add(
      LavvaggioStatsLoadRequested(
        widget.lavvaggio.id,
        from: DateTime.tryParse(range['from']!),
        to:   DateTime.tryParse(range['to']!),
      ),
    );

    // Load raw events for the chart + list
    try {
      final res = await ApiClient.instance.dio.get(
        ApiConstants.events,
        queryParameters: {
          'lavvaggio_id': widget.lavvaggio.id,
          'from':         range['from'],
          'to':           range['to'],
        },
      );
      final list = (res.data['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      setState(() {
        _events        = list;
        _eventsLoading = false;
      });
    } catch (_) {
      setState(() => _eventsLoading = false);
    }
  }

  void _submitEdit(LavvaggioModel lav) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LavvaggioBloc>().add(
        LavvaggioUpdateRequested(
          lavvaggioId: lav.id,
          data: {
            'name':    _nameCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'city':    _cityCtrl.text.trim(),
            'country': _countryCtrl.text.trim(),
            'status':  _selectedStatus,
          },
        ),
      );
    }
  }

  // ── Chart data builders ──

  // Today → washes per hour (0-23)
  List<FlSpot> _buildHourlySpots() {
    final Map<int, int> counts = {};
    for (final e in _events) {
      final dt = DateTime.tryParse(e['started_at'] ?? '');
      if (dt != null) counts[dt.hour] = (counts[dt.hour] ?? 0) + 1;
    }
    return List.generate(24, (h) =>
        FlSpot(h.toDouble(), (counts[h] ?? 0).toDouble()));
  }

  // Week → washes per day (last 7 days)
  List<FlSpot> _buildDailySpots() {
    final now   = DateTime.now();
    final Map<int, int> counts = {};
    for (final e in _events) {
      final dt = DateTime.tryParse(e['started_at'] ?? '');
      if (dt != null) {
        final daysAgo = now.difference(dt).inDays;
        if (daysAgo <= 7) {
          counts[daysAgo] = (counts[daysAgo] ?? 0) + 1;
        }
      }
    }
    // 0 = today, 6 = 6 days ago — display oldest to newest
    return List.generate(7, (i) {
      final daysAgo = 6 - i;
      return FlSpot(i.toDouble(), (counts[daysAgo] ?? 0).toDouble());
    });
  }

  // Month → washes per week (last 4 weeks)
  List<FlSpot> _buildWeeklySpots() {
    final now = DateTime.now();
    final Map<int, int> counts = {};
    for (final e in _events) {
      final dt = DateTime.tryParse(e['started_at'] ?? '');
      if (dt != null) {
        final daysAgo  = now.difference(dt).inDays;
        final weekIndex = daysAgo ~/ 7; // 0=this week, 1=last week...
        if (weekIndex < 4) {
          counts[weekIndex] = (counts[weekIndex] ?? 0) + 1;
        }
      }
    }
    // Display oldest to newest
    return List.generate(4, (i) {
      final weekIndex = 3 - i;
      return FlSpot(i.toDouble(), (counts[weekIndex] ?? 0).toDouble());
    });
  }

  // Custom → daily spots across picked range
  List<FlSpot> _buildCustomSpots() {
    if (_customRange == null) return _buildDailySpots();
    final start    = _customRange!.start;
    final end      = _customRange!.end;
    final dayCount = end.difference(start).inDays + 1;
    final Map<int, int> counts = {};
    for (final e in _events) {
      final dt = DateTime.tryParse(e['started_at'] ?? '');
      if (dt != null) {
        final dayIndex = dt.difference(start).inDays;
        if (dayIndex >= 0 && dayIndex < dayCount) {
          counts[dayIndex] = (counts[dayIndex] ?? 0) + 1;
        }
      }
    }
    return List.generate(dayCount, (i) =>
        FlSpot(i.toDouble(), (counts[i] ?? 0).toDouble()));
  }

  List<FlSpot> get _chartSpots => switch (_dateFilter) {
    'today'  => _buildHourlySpots(),
    'week'   => _buildDailySpots(),
    'month'  => _buildWeeklySpots(),
    'custom' => _buildCustomSpots(),
    _        => _buildHourlySpots(),
  };

  String _chartXLabel(double value) {
    final i = value.toInt();
    return switch (_dateFilter) {
      'today' => '${i}h',
      'week' => () {
        final day = DateTime.now().subtract(Duration(days: 6 - i));
        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        return days[day.weekday - 1];
      }(),
      'month' => 'W${i + 1}',
      'custom' => () {
        if (_customRange == null) return '$i';
        final d = _customRange!.start.add(Duration(days: i));
        return '${d.day}/${d.month}';
      }(),
      _ => '$i',
    };
  }

  double get _chartInterval => switch (_dateFilter) {
    'today'  => 4.0,
    'week'   => 1.0,
    'month'  => 1.0,
    'custom' => () {
      if (_customRange == null) return 1.0;
      final days = _customRange!.end.difference(_customRange!.start).inDays;
      return (days / 5).ceilToDouble().clamp(1.0, double.infinity);
    }(),
    _ => 4.0,
  };

  String get _chartTitle => switch (_dateFilter) {
    'today'  => 'Washes per Hour',
    'week'   => 'Washes per Day (Last 7 Days)',
    'month'  => 'Washes per Week (Last 4 Weeks)',
    'custom' => 'Washes per Day',
    _        => 'Washes',
  };

  String _formatCustomRange() {
    if (_customRange == null) return 'Custom';
    final s = _customRange!.start;
    final e = _customRange!.end;
    return '${s.day}/${s.month} – ${e.day}/${e.month}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LavvaggioBloc, LavvaggioState>(
      listener: (context, state) {
        if (state is LavvaggioDetailLoaded) {
          _syncForm(state.lavvaggio);
        }
        if (state is LavvaggioUpdateSuccess) {
          setState(() => _editMode = false);
          _syncForm(state.lavvaggio);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:         Text('Lavvaggio updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state is LavvaggioError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:         Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is LavvaggioStatsLoading) {
          setState(() => _statsLoading = true);
        }
        if (state is LavvaggioStatsLoaded) {
          setState(() {
            _stats        = state.stats;
            _statsLoading = false;
          });
        }
      },
      builder: (context, state) {
        final lavvaggio = switch (state) {
          LavvaggioDetailLoaded  s => s.lavvaggio,
          LavvaggioUpdating      s => s.lavvaggio,
          LavvaggioUpdateSuccess s => s.lavvaggio,
          _                        => widget.lavvaggio,
        };

        final isUpdating = state is LavvaggioUpdating;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [

              // ── Sliver App Bar ──
              SliverAppBar(
                expandedHeight:  200,
                pinned:          true,
                backgroundColor: AppColors.dark,
                actions: [
                  IconButton(
                    onPressed: () =>
                        setState(() => _editMode = !_editMode),
                    icon: Icon(
                      _editMode
                          ? Icons.close_rounded
                          : Icons.edit_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), AppColors.primary],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:        Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_car_wash_rounded,
                                    color: Colors.white,
                                    size:  22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lavvaggio.name,
                                        style: const TextStyle(
                                          color:      Colors.white,
                                          fontSize:   20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        lavvaggio.fullAddress,
                                        style: TextStyle(
                                          color:    Colors.white.withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _HeaderBadge(
                                  label: lavvaggio.status.toUpperCase(),
                                  color: lavvaggio.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                if (lavvaggio.device != null)
                                  _HeaderBadge(
                                    label: lavvaggio.device!.isOnline
                                        ? 'DEVICE ONLINE'
                                        : 'DEVICE OFFLINE',
                                    color: lavvaggio.device!.isOnline
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Edit Form ──
                      if (_editMode) ...[
                        _EditForm(
                          formKey:         _formKey,
                          nameCtrl:        _nameCtrl,
                          addressCtrl:     _addressCtrl,
                          cityCtrl:        _cityCtrl,
                          countryCtrl:     _countryCtrl,
                          selectedStatus:  _selectedStatus,
                          isUpdating:      isUpdating,
                          onStatusChanged: (val) =>
                              setState(() => _selectedStatus = val),
                          onSubmit: () => _submitEdit(lavvaggio),
                          onCancel: () => setState(() => _editMode = false),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Date Filter Chips ──
                      _DateFilterChips(
                        selected:         _dateFilter,
                        customLabel:      _dateFilter == 'custom'
                            ? _formatCustomRange()
                            : null,
                        onChanged: (val) {
                          if (val == 'custom') {
                            _pickCustomRange();
                          } else {
                            setState(() => _dateFilter = val);
                            _loadEvents();
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Stats from API ──
                      if (_statsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child:   Center(child: CircularProgressIndicator()),
                        )
                      else if (_stats != null)
                        _StatsGrid(stats: _stats!),

                      const SizedBox(height: 24),

                      // ── Chart (built from raw events) ──
                      if (!_eventsLoading) ...[
                        _SectionTitle(title: _chartTitle),
                        const SizedBox(height: 12),
                        _WashChart(
                          spots:    _chartSpots,
                          interval: _chartInterval,
                          labelFn:  _chartXLabel,
                          isEmpty:  _events.isEmpty,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Device ──
                      if (lavvaggio.device != null) ...[
                        const _SectionTitle(title: 'Device'),
                        const SizedBox(height: 12),
                        _DeviceCard(device: lavvaggio.device!),
                        const SizedBox(height: 24),
                      ],

                      // ── Events List ──
                      _SectionTitle(
                        title: 'Events',
                        trailing: _eventsLoading
                            ? const SizedBox(
                          width:  16,
                          height: 16,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          '${_events.length} records',
                          style: const TextStyle(
                            color:    AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (_eventsLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child:   CircularProgressIndicator(),
                          ),
                        )
                      else if (_events.isEmpty)
                        _NoEvents(filter: _dateFilter)
                      else
                        ..._events.map(
                              (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child:   _EventCard(event: e),
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stats Grid (from real API) ────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final LavvaggioStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon:  Icons.water_drop_rounded,
            label: 'Total Washes',
            value: '${stats.totalWashes}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon:  Icons.timer_rounded,
            label: 'Avg Duration',
            value: stats.formattedAvgDuration,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     fullWidth;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding:     const EdgeInsets.all(8),
            decoration:  BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color:    AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize:   20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Total Wash Card ───────────────────────────────────────────────
class _TotalWashCard extends StatelessWidget {
  final int            total;
  final bool           isLoading;
  final String         dateFilter;
  final DateTimeRange? customRange;

  const _TotalWashCard({
    required this.total,
    required this.isLoading,
    required this.dateFilter,
    this.customRange,
  });

  String get _periodLabel => switch (dateFilter) {
    'today'  => 'today',
    'week'   => 'last 7 days',
    'month'  => 'last 30 days',
    'custom' => customRange != null
        ? '${customRange!.start.day}/${customRange!.start.month} – '
        '${customRange!.end.day}/${customRange!.end.month}'
        : 'selected period',
    _        => 'this period',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF0F172A), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding:     const EdgeInsets.all(12),
            decoration:  BoxDecoration(
              color:        Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Colors.white,
              size:  28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Washes',
                style: TextStyle(
                  color:    Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? const SizedBox(
                width:  20,
                height: 20,
                child:  CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       Colors.white,
                ),
              )
                  : Text(
                '$total',
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _periodLabel,
                style: TextStyle(
                  color:    Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Date Filter Chips ─────────────────────────────────────────────
class _DateFilterChips extends StatelessWidget {
  final String            selected;
  final String?           customLabel;
  final ValueChanged<String> onChanged;

  const _DateFilterChips({
    required this.selected,
    required this.onChanged,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('today',  'Today'),
      ('week',   'Week'),
      ('month',  'Month'),
      ('custom', customLabel ?? 'Custom'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          final isCustom   = f.$1 == 'custom';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical:   8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCustom) ...[
                      Icon(
                        Icons.date_range_rounded,
                        size:  14,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      f.$2,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize:   13,
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

// ── Wash Chart ────────────────────────────────────────────────────
class _WashChart extends StatelessWidget {
  final List<FlSpot>     spots;
  final double           interval;
  final String Function(double) labelFn;
  final bool             isEmpty;

  const _WashChart({
    required this.spots,
    required this.interval,
    required this.labelFn,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border),
      ),
      child: isEmpty
          ? const Center(
        child: Text(
          'No data for this period',
          style: TextStyle(
            color:    AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      )
          : LineChart(
        LineChartData(
          gridData: FlGridData(
            show:             true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color:       AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 28,
                interval:     1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color:    AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 22,
                interval:     interval,
                getTitlesWidget: (v, _) => Text(
                  labelFn(v),
                  style: const TextStyle(
                    fontSize: 10,
                    color:    AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            topTitles:   const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:            spots,
              isCurved:         true,
              color:            AppColors.primary,
              barWidth:         2.5,
              isStrokeCapRound: true,
              dotData:          FlDotData(
                show: spots.length <= 7,
              ),
              belowBarData: BarAreaData(
                show:  true,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Badge ──────────────────────────────────────────────────
class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _HeaderBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Card ───────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final DeviceSummary device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding:     const EdgeInsets.all(10),
            decoration:  BoxDecoration(
              color: device.isOnline
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              device.isOnline
                  ? Icons.sensors_rounded
                  : Icons.sensors_off_rounded,
              color: device.isOnline ? AppColors.success : AppColors.error,
              size:  22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.serialNumber,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontSize:   14,
                  ),
                ),
                Text(
                  'Firmware v${device.firmwareVersion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical:    4,
            ),
            decoration: BoxDecoration(
              color: device.isOnline
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              device.status.toUpperCase(),
              style: TextStyle(
                color:      device.isOnline ? AppColors.success : AppColors.error,
                fontSize:   11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final plate      = event['vehicle_plate'] ?? '';
    final type       = event['vehicle_type']  ?? '';
    final startedAt  = DateTime.tryParse(event['started_at'] ?? '');
    final endedAt    = DateTime.tryParse(event['ended_at']   ?? '');
    final duration   = (event['duration_seconds'] as num?)?.toDouble();

    String fmt(DateTime? dt) {
      if (dt == null) return '—';
      return '${dt.hour.toString().padLeft(2,'0')}:'
          '${dt.minute.toString().padLeft(2,'0')}';
    }

    String fmtDur(double? s) {
      if (s == null) return '';
      final m = (s / 60).floor();
      final sec = (s % 60).round();
      return '${m}m ${sec}s';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width:  4,
            height: 56,
            decoration: BoxDecoration(
              color:        AppColors.success,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plate,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${type.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmt(startedAt)} → ${fmt(endedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (duration != null)
            Text(
              fmtDur(duration),
              style: const TextStyle(
                color:      AppColors.textSecondary,
                fontSize:   12,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }
}

// ── Edit Form ─────────────────────────────────────────────────────
class _EditForm extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController countryCtrl;
  final String                selectedStatus;
  final bool                  isUpdating;
  final ValueChanged<String>  onStatusChanged;
  final VoidCallback          onSubmit;
  final VoidCallback          onCancel;

  const _EditForm({
    required this.formKey,
    required this.nameCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.countryCtrl,
    required this.selectedStatus,
    required this.isUpdating,
    required this.onStatusChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Edit Lavvaggio',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            _FormField(label: 'Name',    controller: nameCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            _FormField(label: 'Address', controller: addressCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormField(label: 'City', controller: cityCtrl,
                      validator: (v) => v!.isEmpty ? 'Required' : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(label: 'Country', controller: countryCtrl,
                      validator: (v) => v!.isEmpty ? 'Required' : null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Status',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: ['active', 'inactive'].map((s) {
                final isSelected = selectedStatus == s;
                final color = s == 'active' ? AppColors.success : AppColors.error;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onStatusChanged(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:        isSelected
                            ? color.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border:       Border.all(
                          color: isSelected ? color : AppColors.border,
                        ),
                      ),
                      child: Text(
                        s.toUpperCase(),
                        style: TextStyle(
                          color:      isSelected ? color : AppColors.textSecondary,
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String                    label;
  final TextEditingController     controller;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator:  validator,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String  title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── No Events ─────────────────────────────────────────────────────
class _NoEvents extends StatelessWidget {
  final String filter;
  const _NoEvents({required this.filter});

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      'today'  => 'today',
      'week'   => 'this week',
      'month'  => 'this month',
      'custom' => 'the selected period',
      _        => 'this period',
    };
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.water_drop_outlined,
              size: 40, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'No events $label',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}