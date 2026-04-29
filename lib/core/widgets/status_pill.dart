import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Rounded badge used for status labels everywhere — devices, events,
/// lavaggi operational state, notification types, etc.
class StatusPill extends StatelessWidget {
  final String label;
  final Color  color;
  final double fontSize;
  final bool   solid;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
    this.solid    = false,
  });

  /// Convenience for the success/error/alert palette so callers don't repeat
  /// the color mapping.
  factory StatusPill.byType(String type, {String? label, double fontSize = 10}) {
    final c = switch (type) {
      'success' => AppTokens.teal,
      'error'   => AppTokens.red,
      'alert'   => AppTokens.amber,
      'info'    => AppTokens.blue,
      _         => AppTokens.ts,
    };
    return StatusPill(label: (label ?? type).toUpperCase(), color: c, fontSize: fontSize);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:        solid ? color : color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border:       solid ? null : Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
        style: TextStyle(
          color:        solid ? Colors.white : color,
          fontSize:     fontSize,
          fontWeight:   FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
