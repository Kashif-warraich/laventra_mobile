import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Toast types (mirrors the design's success/error/warning/info).
enum AppAlertType { success, error, warning, info }

/// Globally accessible toast overlay with the auto-dismiss progress bar from
/// the design. Use via `AppAlerts.show(context, ...)`. Old toasts are replaced
/// by new ones — only one shows at a time.
class AppAlerts {
  AppAlerts._();

  static OverlayEntry?  _entry;
  static Timer?         _timer;

  static void show(
    BuildContext context, {
    required AppAlertType type,
    required String       message,
    Duration              duration = const Duration(milliseconds: 3200),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _dismiss();

    final entry = OverlayEntry(
      builder: (_) => _AppAlertView(
        type:     type,
        message:  message,
        duration: duration,
        onTap:    _dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
    _timer = null;
  }

  // Convenience shortcuts — match the design's showAlert calls.
  static void success(BuildContext c, String m) => show(c, type: AppAlertType.success, message: m);
  static void error  (BuildContext c, String m) => show(c, type: AppAlertType.error,   message: m);
  static void warning(BuildContext c, String m) => show(c, type: AppAlertType.warning, message: m);
  static void info   (BuildContext c, String m) => show(c, type: AppAlertType.info,    message: m);
}

class _AppAlertView extends StatefulWidget {
  final AppAlertType type;
  final String       message;
  final Duration     duration;
  final VoidCallback onTap;

  const _AppAlertView({
    required this.type,
    required this.message,
    required this.duration,
    required this.onTap,
  });

  @override
  State<_AppAlertView> createState() => _AppAlertViewState();
}

class _AppAlertViewState extends State<_AppAlertView> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.type) {
      case AppAlertType.success: return AppTokens.teal;
      case AppAlertType.error:   return AppTokens.red;
      case AppAlertType.warning: return AppTokens.amber;
      case AppAlertType.info:    return AppTokens.blue;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AppAlertType.success: return Icons.check_circle_outline_rounded;
      case AppAlertType.error:   return Icons.error_outline_rounded;
      case AppAlertType.warning: return Icons.warning_amber_rounded;
      case AppAlertType.info:    return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      top:   media.padding.top + 16,
      left:  16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: widget.onTap,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 280),
            tween:    Tween(begin: 0, end: 1),
            curve:    Curves.easeOutBack,
            builder:  (_, t, child) => Opacity(
              opacity: t.clamp(0, 1),
              child:   Transform.translate(offset: Offset(0, -18 * (1 - t)), child: child),
            ),
            child: Container(
              decoration: BoxDecoration(
                color:        AppTokens.bgCard,
                borderRadius: BorderRadius.circular(AppTokens.rLg),
                border:       Border.all(color: _color.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize:        MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color:        _color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(_icon, color: _color, size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(widget.message, style: const TextStyle(color: AppTokens.tp, fontWeight: FontWeight.w600, fontSize: 13.5))),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _ac,
                    builder: (_, __) => SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value:           1 - _ac.value,
                        backgroundColor: AppTokens.bgEl,
                        valueColor:      AlwaysStoppedAnimation(_color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
