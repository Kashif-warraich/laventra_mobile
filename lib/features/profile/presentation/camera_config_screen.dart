import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/sub_header.dart';

/// Local-only sliders for now — these are planned to map to per-lavaggio
/// settings once the backend exposes that table.
class CameraConfigScreen extends StatefulWidget {
  const CameraConfigScreen({super.key});

  @override
  State<CameraConfigScreen> createState() => _CameraConfigScreenState();
}

class _CameraConfigScreenState extends State<CameraConfigScreen> {
  double _conf = 70;       // matches backend CONFIDENCE_THRESHOLD default
  double _fps  = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: 'Camera & AI Config', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                children: [
                  _Card(title: 'AI Detection', children: [
                    _Slider(
                      label: 'Min Confidence Threshold',
                      sub:   'Events below this are flagged as errors',
                      value: _conf, min: 50, max: 99, unit: '%',
                      onChanged: (v) => setState(() => _conf = v),
                    ),
                    const SizedBox(height: 14),
                    _Slider(
                      label: 'Frame Sampling Rate',
                      sub:   'Frames analyzed per second',
                      value: _fps, min: 1, max: 30, unit: ' FPS',
                      onChanged: (v) => setState(() => _fps = v),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const _Card(title: 'Model Info', children: [
                    _Row(label: 'Current Model', value: 'LV-AI v2.1'),
                    _Divider(),
                    _Row(label: 'Last Update',   value: 'Apr 20, 2026'),
                    _Divider(),
                    _Row(label: 'Avg Accuracy',  value: '96.4%'),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () => AppAlerts.success(context, 'Configuration saved (local-only for now)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Save Config', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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

class _Slider extends StatelessWidget {
  final String label;
  final String sub;
  final double value, min, max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _Slider({
    required this.label,
    required this.sub,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub,   style: const TextStyle(color: AppTokens.ts, fontSize: 11)),
                ],
              ),
            ),
            Text('${value.round()}$unit',
              style: const TextStyle(color: AppTokens.blue, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   AppTokens.blue,
            inactiveTrackColor: AppTokens.bgEl,
            thumbColor:         AppTokens.blue,
            overlayColor:       AppTokens.blue.withOpacity(0.18),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String        title;
  final List<Widget>  children;
  const _Card({required this.title, required this.children});

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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTokens.ts, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(color: AppTokens.border, height: 1);
}
