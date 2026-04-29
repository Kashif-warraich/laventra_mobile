import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/empty_state.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';
import '../data/models/report_model.dart';
import '../data/repositories/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = ReportRepository();
  Timer?   _pollTimer;
  String?  _lastFlashShown;

  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(const ReportsLoadRequested());
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollGenerating());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _pollGenerating() {
    final s = context.read<ReportBloc>().state;
    if (s is ReportsLoaded) {
      for (final r in s.reports) {
        if (r.isGenerating) {
          context.read<ReportBloc>().add(ReportPollRequested(r.id));
        }
      }
    }
  }

  Future<void> _download(ReportModel report) async {
    AppAlerts.info(context, 'Downloading ${report.name}…');
    try {
      final file = await _repo.downloadReport(report);
      if (mounted) AppAlerts.success(context, 'Saved to ${file.path}');
    } catch (e) {
      if (mounted) AppAlerts.error(context, 'Download failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: BlocConsumer<ReportBloc, ReportState>(
          listener: (context, state) {
            if (state is ReportsLoaded && state.flashMessage != null && state.flashMessage != _lastFlashShown) {
              _lastFlashShown = state.flashMessage;
              AppAlerts.info(context, state.flashMessage!);
            } else if (state is ReportError) {
              AppAlerts.error(context, state.message);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _Header(reportCount: state is ReportsLoaded ? state.reports.length : 0),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ReportState state) {
    if (state is ReportLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTokens.blue));
    }
    if (state is ReportError) {
      return EmptyState(icon: Icons.cloud_off_rounded, title: 'Failed to load', subtitle: state.message, accent: AppTokens.red);
    }
    if (state is ReportsLoaded) {
      if (state.reports.isEmpty) {
        return const EmptyState(icon: Icons.description_rounded, title: 'No reports yet',
          subtitle: 'Tap + to generate your first report');
      }
      return RefreshIndicator(
        color: AppTokens.blue,
        backgroundColor: AppTokens.bgCard,
        onRefresh: () async {
          context.read<ReportBloc>().add(const ReportsRefreshRequested());
          await context.read<ReportBloc>().stream.firstWhere((s) => s is! ReportLoading);
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          itemCount: state.reports.length,
          itemBuilder: (_, i) => _ReportCard(
            report:     state.reports[i],
            onDownload: () => _download(state.reports[i]),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _Header extends StatelessWidget {
  final int reportCount;
  const _Header({required this.reportCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reports',
                  style: TextStyle(color: AppTokens.tp, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('$reportCount report${reportCount == 1 ? '' : 's'} available',
                  style: const TextStyle(color: AppTokens.ts, fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/reports/new'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTokens.blue, Color(0xFF5B9FFF)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppTokens.blue.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel  report;
  final VoidCallback onDownload;

  const _ReportCard({required this.report, required this.onDownload});

  Color get _formatColor {
    switch (report.format) {
      case ReportFormat.pdf:  return AppTokens.red;
      case ReportFormat.csv:  return AppTokens.teal;
      case ReportFormat.xlsx: return AppTokens.amber;
      default:                return AppTokens.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg + 2),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format badge
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color:        _formatColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                  border:       Border.all(color: _formatColor.withOpacity(0.35)),
                ),
                child: Center(
                  child: report.isGenerating
                    ? SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_formatColor)))
                    : Text(report.formatLabel,
                        style: TextStyle(color: _formatColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.name, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTokens.tp, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        Text(_dateLabel(report.createdAt),
                          style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                        const Text('·', style: TextStyle(color: AppTokens.tm, fontSize: 11)),
                        Text(report.scopeLabel,
                          style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                        if (!report.isGenerating) ...[
                          const Text('·', style: TextStyle(color: AppTokens.tm, fontSize: 11)),
                          Text(report.formattedSize,
                            style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                        ],
                      ],
                    ),
                    if (report.isGenerating) ...[
                      const SizedBox(height: 8),
                      _ProgressBar(color: _formatColor),
                      const SizedBox(height: 4),
                      const Text('Generating…',
                        style: TextStyle(color: AppTokens.ts, fontSize: 10)),
                    ],
                    if (report.isFailed) ...[
                      const SizedBox(height: 6),
                      Text(report.error ?? 'Generation failed',
                        style: const TextStyle(color: AppTokens.red, fontSize: 11)),
                    ],
                  ],
                ),
              ),
              if (report.isReady) ...[
                _IconBtn(icon: Icons.visibility_outlined, color: AppTokens.blue,
                  onTap: () => AppAlerts.info(context, 'Preview ${report.name}')),
                const SizedBox(width: 6),
                _IconBtn(icon: Icons.download_rounded, color: AppTokens.teal, onTap: onDownload),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '${t.year}-$m-$d';
  }
}

class _ProgressBar extends StatefulWidget {
  final Color color;
  const _ProgressBar({required this.color});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(color: AppTokens.bgEl, borderRadius: BorderRadius.circular(2)),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, __) => Align(
          alignment: Alignment(-1 + 2 * _ac.value, 0),
          child: FractionallySizedBox(
            widthFactor: 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.color.withOpacity(0), widget.color, widget.color.withOpacity(0)]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color:        color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withOpacity(0.35)),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
