import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationEvent {
  final String? type;       // 'success' | 'error' | 'alert' or null = all
  final bool    unreadOnly;
  const NotificationsLoadRequested({this.type, this.unreadOnly = false});
  @override
  List<Object?> get props => [type, unreadOnly];
}

class NotificationsRefreshRequested extends NotificationEvent {
  final String? type;
  final bool    unreadOnly;
  const NotificationsRefreshRequested({this.type, this.unreadOnly = false});
  @override
  List<Object?> get props => [type, unreadOnly];
}

class NotificationMarkReadRequested extends NotificationEvent {
  final int id;
  const NotificationMarkReadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllReadRequested extends NotificationEvent {
  const NotificationsMarkAllReadRequested();
}

class NotificationDeleteRequested extends NotificationEvent {
  final int id;
  const NotificationDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// Light-weight side request just to refresh the global unread badge from
/// elsewhere in the app (e.g. dashboard bell).
class NotificationUnreadCountRequested extends NotificationEvent {
  const NotificationUnreadCountRequested();
}
