import 'package:equatable/equatable.dart';
import '../../devices/data/models/device_model.dart';
import '../../events/data/models/event_model.dart';
import '../../lavvaggios/data/models/lavvaggio_model.dart';
import '../../notifications/data/models/notification_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState { const DashboardInitial(); }
class DashboardLoading extends DashboardState { const DashboardLoading(); }

class DashboardLoaded extends DashboardState {
  final List<LavvaggioModel>    lavaggi;
  final List<DeviceModel>       devices;
  final List<EventModel>        recentEvents;
  final List<NotificationModel> alerts;        // type=error | alert, top 4
  final int                     unreadCount;

  const DashboardLoaded({
    required this.lavaggi,
    required this.devices,
    required this.recentEvents,
    required this.alerts,
    required this.unreadCount,
  });

  // Aggregated stats — derived once for the dashboard cards.
  int get todaysWashes        => lavaggi.fold(0, (sum, l) => sum + l.todayWashes);
  int get onlineDevicesCount  => devices.where((d) => d.isOnline).length;
  int get offlineDevicesCount => devices.length - onlineDevicesCount;
  int get errorEventsToday    => recentEvents.where((e) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return e.isError && e.startedAt.isAfter(start);
  }).length;

  @override
  List<Object?> get props => [lavaggi, devices, recentEvents, alerts, unreadCount];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
