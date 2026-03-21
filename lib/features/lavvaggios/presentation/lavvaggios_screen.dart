import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lavvaggio_bloc.dart';
import '../bloc/lavvaggio_event.dart';
import '../bloc/lavvaggio_state.dart';
import '../data/models/lavvaggio_model.dart';
import '../data/repositories/lavvaggio_repository.dart';
import 'lavvaggio_detail_screen.dart';
import '../../../../core/theme/app_theme.dart';

class LavvaggiosScreen extends StatefulWidget {
  const LavvaggiosScreen({super.key});

  @override
  State<LavvaggiosScreen> createState() => _LavvaggiosScreenState();
}

class _LavvaggiosScreenState extends State<LavvaggiosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LavvaggioBloc>().add(const LavvaggiosLoadRequested());
  }

  Future<void> _onRefresh() async {
    context.read<LavvaggioBloc>().add(const LavvaggioRefreshRequested());
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Lavvaggios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _onRefresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<LavvaggioBloc, LavvaggioState>(
        builder: (context, state) {
          if (state is LavvaggioLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LavvaggioError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<LavvaggioBloc>()
                  .add(const LavvaggiosLoadRequested()),
            );
          }

          if (state is LavvaggiosLoaded) {
            if (state.lavvaggios.isEmpty) {
              return const _EmptyView();
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: state.lavvaggios.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _LavvaggioCard(
                      lavvaggio: state.lavvaggios[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => LavvaggioBloc(
                                repository: LavvaggioRepository(),
                              ),
                              child: LavvaggioDetailScreen(
                                lavvaggio: state.lavvaggios[index],
                              ),
                            ),
                          ),
                        ).then((_) {
                          // Refresh list when returning from detail
                          context
                              .read<LavvaggioBloc>()
                              .add(const LavvaggiosLoadRequested());
                        });
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Lavvaggio Card ────────────────────────────────────────────────
class _LavvaggioCard extends StatelessWidget {
  final LavvaggioModel lavvaggio;
  final VoidCallback   onTap;

  const _LavvaggioCard({
    required this.lavvaggio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive       = lavvaggio.isActive;
    final deviceOnline   = lavvaggio.device?.isOnline ?? false;
    final statusColor    = isActive ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [

            // ── Header ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                  colors: isActive
                      ? [const Color(0xFF0F172A), AppColors.primary]
                      : [const Color(0xFF374151), const Color(0xFF6B7280)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width:  48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_car_wash_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Name + address
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lavvaggio.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            color:      Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lavvaggio.fullAddress,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color:    Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines:  1,
                          overflow:  TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status dot
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical:   4,
                    ),
                    decoration: BoxDecoration(
                      color:        statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(
                        color: statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width:       6,
                          height:      6,
                          decoration:  BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          lavvaggio.status.toUpperCase(),
                          style: TextStyle(
                            color:      statusColor,
                            fontSize:   10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Info Row ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical:   16,
              ),
              child: Row(
                children: [
                  // Device status
                  Expanded(
                    child: _InfoTile(
                      icon:  deviceOnline
                          ? Icons.sensors_rounded
                          : Icons.sensors_off_rounded,
                      iconColor: deviceOnline
                          ? AppColors.success
                          : AppColors.error,
                      label: 'Device',
                      value: lavvaggio.device == null
                          ? 'Not assigned'
                          : deviceOnline
                          ? 'Online'
                          : lavvaggio.device!.status.toUpperCase(),
                    ),
                  ),

                  // Divider
                  Container(
                    width:  1,
                    height: 36,
                    color:  AppColors.border,
                  ),

                  // Serial
                  Expanded(
                    child: _InfoTile(
                      icon:      Icons.memory_rounded,
                      iconColor: AppColors.textSecondary,
                      label:     'Serial',
                      value:     lavvaggio.device?.serialNumber ?? '—',
                    ),
                  ),

                  // Divider
                  Container(
                    width:  1,
                    height: 36,
                    color:  AppColors.border,
                  ),

                  // Firmware
                  Expanded(
                    child: _InfoTile(
                      icon:      Icons.system_update_alt_rounded,
                      iconColor: AppColors.textSecondary,
                      label:     'Firmware',
                      value:     lavvaggio.device != null
                          ? 'v${lavvaggio.device!.firmwareVersion}'
                          : '—',
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical:   12,
              ),
              decoration: BoxDecoration(
                color:        AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft:  Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to view details & events',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size:  14,
                    color: AppColors.textSecondary,
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 10,
            color:    AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Empty View ────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.store_mall_directory_outlined,
            size:  64,
            color: AppColors.border,
          ),
          const SizedBox(height: 16),
          Text(
            'No lavvaggios found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact your admin to assign lavvaggios',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────
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
            const Icon(
              Icons.wifi_off_rounded,
              size:  64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}