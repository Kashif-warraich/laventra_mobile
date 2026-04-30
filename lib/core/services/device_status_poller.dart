import 'dart:async';
import '../../features/device_logs/data/models/device_log_model.dart';
import '../../features/device_logs/data/repositories/device_log_repository.dart';

/// Emitted when the poller detects a new online/offline device log.
class DeviceStatusChangedNotification {
  final DeviceLogModel log;
  const DeviceStatusChangedNotification(this.log);
}

/// Singleton polling service. Started after login (from HomeScreen), stopped on
/// logout. Every [pollInterval] it asks the backend for logs with
/// `since=<last_check_time>` and broadcasts any online/offline transitions on
/// [stream].
class DeviceStatusPoller {
  DeviceStatusPoller._();
  static final DeviceStatusPoller instance = DeviceStatusPoller._();

  static const Duration pollInterval = Duration(seconds: 30);

  final DeviceLogRepository _repository = DeviceLogRepository();
  final StreamController<DeviceStatusChangedNotification> _controller =
      StreamController<DeviceStatusChangedNotification>.broadcast();

  Timer?    _timer;
  DateTime? _lastCheck;
  bool      _running = false;

  Stream<DeviceStatusChangedNotification> get stream => _controller.stream;

  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running   = true;
    // Start "since" slightly in the past so the first tick surfaces anything
    // that happened in the last minute.
    _lastCheck = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    _timer     = Timer.periodic(pollInterval, (_) => _poll());
    // Fire one immediately instead of waiting 30s
    _poll();
  }

  void stop() {
    _timer?.cancel();
    _timer   = null;
    _running = false;
  }

  Future<void> _poll() async {
    try {
      final result = await _repository.fetchLogs(
        since:   _lastCheck,
        page:    1,
        perPage: 50,
      );
      // Advance cursor regardless of whether there were logs — avoids re-polling
      // the same window after a quiet period.
      _lastCheck = DateTime.now().toUtc();

      if (result.data.isEmpty) return;

      // Notify in chronological order so the UI shows events in the order they
      // happened.
      final ordered = [...result.data]
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

      for (final log in ordered) {
        if (log.isOnline || log.isOffline) {
          _controller.add(DeviceStatusChangedNotification(log));
        }
      }
    } catch (_) {
      // Polling is best-effort — never bubble errors up to the UI
    }
  }
}
