import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../../devices/data/repositories/device_repository.dart';
import '../../events/data/repositories/event_repository.dart';
import '../../lavvaggios/data/repositories/lavvaggio_repository.dart';
import '../../notifications/data/repositories/notification_repository.dart';
import '../../notifications/data/models/notification_model.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Aggregates 4 list endpoints into a single state for the dashboard. Calls
/// run in parallel via Future.wait — first error fails the whole state.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final LavvaggioRepository    _lav;
  final DeviceRepository       _dev;
  final EventRepository        _evt;
  final NotificationRepository _notif;

  DashboardBloc({
    required LavvaggioRepository    lavRepo,
    required DeviceRepository       deviceRepo,
    required EventRepository        eventRepo,
    required NotificationRepository notifRepo,
  })  : _lav   = lavRepo,
        _dev   = deviceRepo,
        _evt   = eventRepo,
        _notif = notifRepo,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(DashboardLoadRequested e, Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(DashboardRefreshRequested e, Emitter<DashboardState> emit) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<DashboardState> emit) async {
    try {
      final results = await Future.wait([
        _lav.getLavvaggios(perPage: 100),
        _dev.getDevices(perPage: 100),
        _evt.getEvents(perPage: 8),
        _notif.getNotifications(perPage: 6),
      ]);

      // ignore: avoid_dynamic_calls
      final lavPage    = results[0] as dynamic;
      // ignore: avoid_dynamic_calls
      final devPage    = results[1] as dynamic;
      // ignore: avoid_dynamic_calls
      final evtPage    = results[2] as dynamic;
      final notifPage  = results[3] as NotificationListPage;

      final alerts = (notifPage.page.data as List<NotificationModel>)
          .where((n) => n.isError || n.isAlert)
          .take(4)
          .toList();

      emit(DashboardLoaded(
        lavaggi:      lavPage.data,
        devices:      devPage.data,
        recentEvents: evtPage.data,
        alerts:       alerts,
        unreadCount:  notifPage.unreadCount,
      ));
    } on DioException catch (e) {
      emit(DashboardError(_msg(e, 'Failed to load dashboard')));
    } catch (e) {
      emit(DashboardError('Unexpected error: $e'));
    }
  }

  String _msg(DioException e, String fallback) =>
      (e.response?.data?['errors']?[0] as String?) ?? fallback;
}
