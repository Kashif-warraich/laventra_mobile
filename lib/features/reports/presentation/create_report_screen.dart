import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/sub_header.dart';
import '../../lavvaggios/bloc/lavvaggio_bloc.dart';
import '../../lavvaggios/bloc/lavvaggio_event.dart';
import '../../lavvaggios/bloc/lavvaggio_state.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../data/models/report_model.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  DateTime  _from   = DateTime.now().subtract(const Duration(days: 30));
  DateTime  _to     = DateTime.now();
  int?      _lavId;            // null = all lavaggi
  String    _format = ReportFormat.pdf;

  @override
  void initState() {
    super.initState();
    context.read<LavvaggioBloc>().add(const LavvaggiosLoadRequested());
  }

  void _generate() {
    context.read<ReportBloc>().add(ReportCreateRequested(
      format:      _format,
      lavvaggioId: _lavId,
      dateFrom:    _from,
      dateTo:      _to,
    ));
    context.pop();
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _from : _to;
    final res = await showDatePicker(
      context:    context,
      initialDate: initial,
      firstDate:  DateTime(2020),
      lastDate:   DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppTokens.blue, brightness: Brightness.dark),
          dialogBackgroundColor: AppTokens.bgCard,
        ),
        child: child!,
      ),
    );
    if (res != null) {
      setState(() {
        if (isFrom) _from = res; else _to = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: 'New Report', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                children: [
                  _Card(
                    title: 'Date Range',
                    child: Row(
                      children: [
                        Expanded(child: _DateField(label: 'From', value: fmt.format(_from), onTap: () => _pickDate(true))),
                        const SizedBox(width: 10),
                        Expanded(child: _DateField(label: 'To',   value: fmt.format(_to),   onTap: () => _pickDate(false))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    title: 'Location',
                    child: BlocBuilder<LavvaggioBloc, LavvaggioState>(
                      builder: (_, s) {
                        final lavs = s is LavvaggiosLoaded ? s.lavvaggios : [];
                        return Column(
                          children: [
                            _Radio(label: 'All Lavaggi', selected: _lavId == null,
                              onTap: () => setState(() => _lavId = null)),
                            ...lavs.map((l) => _Radio(label: l.name, selected: _lavId == l.id,
                              onTap: () => setState(() => _lavId = l.id))),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    title: 'Format',
                    child: Row(
                      children: [
                        _FormatBtn(label: 'PDF',   selected: _format == ReportFormat.pdf,
                          color: AppTokens.red,   onTap: () => setState(() => _format = ReportFormat.pdf)),
                        const SizedBox(width: 8),
                        _FormatBtn(label: 'CSV',   selected: _format == ReportFormat.csv,
                          color: AppTokens.teal,  onTap: () => setState(() => _format = ReportFormat.csv)),
                        const SizedBox(width: 8),
                        _FormatBtn(label: 'EXCEL', selected: _format == ReportFormat.xlsx,
                          color: AppTokens.amber, onTap: () => setState(() => _format = ReportFormat.xlsx)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.description_rounded, color: Colors.white, size: 18),
                      label: const Text('Generate Report',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rLg)),
                        elevation: 0,
                      ),
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
            style: const TextStyle(color: AppTokens.ts, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color:        AppTokens.bgEl,
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: AppTokens.border),
            ),
            child: Text(value,
              style: const TextStyle(color: AppTokens.tp, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onTap;
  const _Radio({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color:        selected ? AppTokens.blue.withOpacity(0.15) : AppTokens.bgEl,
            borderRadius: BorderRadius.circular(AppTokens.rMd),
            border:       Border.all(color: selected ? AppTokens.blue : AppTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppTokens.blue : AppTokens.ts, width: 2),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: selected ? 8 : 0, height: selected ? 8 : 0,
                    decoration: const BoxDecoration(color: AppTokens.blue, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                  style: TextStyle(
                    color: selected ? AppTokens.tp : AppTokens.ts,
                    fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatBtn extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   selected;
  final VoidCallback onTap;

  const _FormatBtn({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:        selected ? color.withOpacity(0.18) : AppTokens.bgEl,
            borderRadius: BorderRadius.circular(AppTokens.rMd),
            border:       Border.all(color: selected ? color : AppTokens.border),
          ),
          child: Text(label,
            style: TextStyle(
              color:        selected ? color : AppTokens.ts,
              fontSize:     12, fontWeight: FontWeight.w800, letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
