import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Custom toggle matching the design (rounded pill + slide knob, blue when on).
class LavToggle extends StatelessWidget {
  final bool             value;
  final ValueChanged<bool>? onChanged;

  const LavToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve:    Curves.easeOut,
        width:    42,
        height:   24,
        decoration: BoxDecoration(
          color:        value ? AppTokens.blue : AppTokens.bgEl,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: value ? AppTokens.blue : AppTokens.border),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve:    Curves.easeOut,
              left:     value ? 20 : 2,
              top:      2,
              bottom:   2,
              child: Container(
                width: 18,
                decoration: BoxDecoration(
                  color: value ? Colors.white : AppTokens.ts,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
