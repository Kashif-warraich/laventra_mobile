import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Bottom-sheet confirmation matching the design (logout, delete lavaggio,
/// remove notification, etc.). Returns `true` if confirmed, `false`/`null`
/// if dismissed.
class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel  = 'Cancel',
    bool   destructive  = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (_) => _Sheet(
        title:        title,
        message:      message,
        confirmLabel: confirmLabel,
        cancelLabel:  cancelLabel,
        destructive:  destructive,
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool   destructive;

  const _Sheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppTokens.red : AppTokens.blue;
    return SafeArea(
      child: Container(
        margin:  const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color:        AppTokens.bgCard,
          borderRadius: BorderRadius.circular(AppTokens.rXl),
          border:       Border.all(color: AppTokens.border),
        ),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38, height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppTokens.tp, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppTokens.ts, fontSize: 14, height: 1.4)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTokens.bgEl,
                      foregroundColor: AppTokens.tp,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
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
