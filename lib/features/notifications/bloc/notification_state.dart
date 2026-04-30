import 'package:equatable/equatable.dart';
import '../data/models/notification_model.dart';
import '../../../../core/models/pagination_meta.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState { const NotificationInitial(); }
class NotificationLoading extends NotificationState { const NotificationLoading(); }

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final PaginationMeta          meta;
  final int                     unreadCount;
  const NotificationsLoaded(this.notifications, this.meta, this.unreadCount);

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    PaginationMeta?          meta,
    int?                     unreadCount,
  }) => NotificationsLoaded(
    notifications ?? this.notifications,
    meta          ?? this.meta,
    unreadCount   ?? this.unreadCount,
  );

  @override
  List<Object?> get props => [notifications, meta, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}
