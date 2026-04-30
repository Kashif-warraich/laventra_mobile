import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationsRefreshRequested>(_onRefresh);
    on<NotificationMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationDeleteRequested>(_onDelete);
    on<NotificationUnreadCountRequested>(_onUnreadCount);
  }

  Future<void> _onLoad(NotificationsLoadRequested e, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    try {
      final p = await _repository.getNotifications(type: e.type, unreadOnly: e.unreadOnly);
      emit(NotificationsLoaded(p.page.data, p.page.meta, p.unreadCount));
    } on DioException catch (e) {
      emit(NotificationError(_msg(e, 'Failed to load notifications')));
    } catch (_) {
      emit(const NotificationError('An unexpected error occurred'));
    }
  }

  Future<void> _onRefresh(NotificationsRefreshRequested e, Emitter<NotificationState> emit) async {
    try {
      final p = await _repository.getNotifications(type: e.type, unreadOnly: e.unreadOnly);
      emit(NotificationsLoaded(p.page.data, p.page.meta, p.unreadCount));
    } on DioException catch (e) {
      emit(NotificationError(_msg(e, 'Failed to refresh notifications')));
    } catch (_) {}
  }

  Future<void> _onMarkRead(NotificationMarkReadRequested e, Emitter<NotificationState> emit) async {
    final s = state;
    try {
      await _repository.markRead(e.id);
      if (s is NotificationsLoaded) {
        final updated = s.notifications.map((n) => n.id == e.id ? n.copyWith(read: true, readAt: DateTime.now()) : n).toList();
        final newUnread = (s.unreadCount - 1).clamp(0, 1 << 30);
        emit(s.copyWith(notifications: updated, unreadCount: newUnread));
      }
    } on DioException catch (e) {
      emit(NotificationError(_msg(e, 'Failed to mark as read')));
    }
  }

  Future<void> _onMarkAllRead(NotificationsMarkAllReadRequested e, Emitter<NotificationState> emit) async {
    final s = state;
    try {
      await _repository.markAllRead();
      if (s is NotificationsLoaded) {
        final updated = s.notifications.map((n) => n.copyWith(read: true, readAt: DateTime.now())).toList();
        emit(s.copyWith(notifications: updated, unreadCount: 0));
      }
    } on DioException catch (e) {
      emit(NotificationError(_msg(e, 'Failed to mark all as read')));
    }
  }

  Future<void> _onDelete(NotificationDeleteRequested e, Emitter<NotificationState> emit) async {
    final s = state;
    try {
      await _repository.delete(e.id);
      if (s is NotificationsLoaded) {
        final removed = s.notifications.firstWhere((n) => n.id == e.id, orElse: () => s.notifications.first);
        final updated = s.notifications.where((n) => n.id != e.id).toList();
        final unread  = removed.read ? s.unreadCount : (s.unreadCount - 1).clamp(0, 1 << 30);
        emit(s.copyWith(notifications: updated, unreadCount: unread));
      }
    } on DioException catch (e) {
      emit(NotificationError(_msg(e, 'Failed to delete notification')));
    }
  }

  Future<void> _onUnreadCount(NotificationUnreadCountRequested e, Emitter<NotificationState> emit) async {
    final s = state;
    try {
      final count = await _repository.getUnreadCount();
      if (s is NotificationsLoaded) {
        emit(s.copyWith(unreadCount: count));
      }
    } catch (_) {
      // Non-fatal — the bell badge can be a tick stale.
    }
  }

  String _msg(DioException e, String fallback) =>
      (e.response?.data?['errors']?[0] as String?) ?? fallback;
}
