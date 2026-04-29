class ApiConstants {
  ApiConstants._();

  // ── Change only this when going to production ──
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // ── Auth ──
  static const String login  = '/login';
  static const String logout = '/logout';
  static const String signup = '/signup';

  // ── Resources ──
  static const String users          = '/users';
  static const String userPushToken  = '/users/push_token';
  static const String lavvaggios     = '/lavvaggios';
  static const String devices        = '/devices';
  static const String events         = '/car_wash_events';
  static const String carWashEvents  = '/car_wash_events';
  static const String reports        = '/reports';
  static const String notifications  = '/notifications';

  // ── Computed paths ──
  static String lavvaggioStats(int id)  => '/lavvaggios/$id/stats';
  static String reportDownload(int id)  => '/reports/$id/download';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsMarkAllRead = '/notifications/mark_all_read';
  static const String notificationsUnreadCount = '/notifications/unread_count';
}
