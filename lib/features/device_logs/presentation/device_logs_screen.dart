import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/device_log_bloc.dart';
import '../bloc/device_log_event.dart';
import '../bloc/device_log_state.dart';
import '../data/models/device_log_model.dart';
import '../../lavvaggios/data/models/lavvaggio_model.dart';
import '../../lavvaggios/data/repositories/lavvaggio_repository.dart';
import '../../../../core/theme/app_theme.dart';

class DeviceLogsScreen extends StatefulWidget {
  const DeviceLogsScreen({super.key});

  @override
  State<DeviceLogsScreen> createState() => _DeviceLogsScreenState();
}

class _DeviceLogsScreenState extends State<DeviceLogsScreen> {
  int?    _selectedLavvaggioId;
  String? _selectedLavvaggioName;

  List<LavvaggioModel> _lavvaggios        = [];
  bool                 _lavvaggiosLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLavvaggios();
    _loadLogs();
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

  void _loadLogs() {
    context.read<DeviceLogBloc>().add(
          DeviceLogsFetchRequested(lavvaggioId: _selectedLavvaggioId),
        );
  }

  Future<void> _onRefresh() async {
    context.read<DeviceLogBloc>().add(
          DeviceLogsRefreshRequested(lavvaggioId: _selectedLavvaggioId),
        );
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _clearLavvaggioFilter() {
    setState(() {
      _selectedLavvaggioId   = null;
      _selectedLavvaggioName = null;
    });
    _loadLogs();
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
            title: const Text('Device Logs',
                style: TextStyle(color: Colors.white)),
            actions: [
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
        ],

        body: BlocBuilder<DeviceLogBloc, DeviceLogState>(
          builder: (context, state) {
            if (state is DeviceLogsInitial || state is DeviceLogsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DeviceLogsError) {
              return _ErrorView(message: state.message, onRetry: _loadLogs);
            }

            if (state is DeviceLogsLoaded) {
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  slivers: [
                    if (_selectedLavvaggioId != null)
                      SliverToBoxAdapter(
                        child: _ActiveFilterChip(
                          label:  _selectedLavvaggioName ?? 'Filter',
                          onClear: _clearLavvaggioFilter,
                        ),
                      ),
                    if (state.logs.isEmpty)
                      const SliverFillRemaining(child: _EmptyView())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child:   _LogCard(log: state.logs[i]),
                            ),
                            childCount: state.logs.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
          _loadLogs();
        },
      ),
    );
  }
}

// ── Log Card ──────────────────────────────────────────────────────────────────
class _LogCard extends StatelessWidget {
  final DeviceLogModel log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final Color color = log.isOnline ? AppColors.success : AppColors.error;
    final IconData icon =
        log.isOnline ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color:   Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width:  44, height: 44,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color:      color,
                        fontSize:   13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (log.deviceSerial != null)
                      Text(
                        log.deviceSerial!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize:   12,
                          color:      AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (log.message != null)
                  Text(
                    log.message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color:    AppColors.textPrimary,
                        ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.store_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.lavvaggioName ?? '—',
                        style: const TextStyle(
                          color:    AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                log.formattedTime,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                log.formattedDate,
                style: const TextStyle(
                  color:    AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active Filter Chip ────────────────────────────────────────────────────────
class _ActiveFilterChip extends StatelessWidget {
  final String       label;
  final VoidCallback onClear;

  const _ActiveFilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:        AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color:      AppColors.primary,
                      fontSize:   12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
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
              decoration: BoxDecoration(
                color:        AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filter by Lavvaggio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _SheetOption(
            label:      'All Lavvaggios',
            isSelected: selectedId == null,
            icon:       Icons.store_rounded,
            onTap:      () => onSelect(null),
          ),
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
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary),
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
                    Text(subtitle!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (statusColor != null)
              Container(
                width: 8, height: 8,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_rounded,
                    color: AppColors.primary, size: 18),
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
          const Icon(Icons.event_note_rounded, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text('No device logs yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  )),
          const SizedBox(height: 6),
          Text('Device state changes will appear here',
              style: Theme.of(context).textTheme.bodyMedium),
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
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:      const Icon(Icons.refresh_rounded),
              label:     const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
