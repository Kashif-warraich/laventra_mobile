class ApiConstants {
  ApiConstants._();

  // ── Change only this when going to production ──
  // ngrok tunnel for on-device testing against the local Rails server.
  // Swap to the production URL when shipping.
  static const String baseUrl = 'https://3fe4-94-167-196-116.ngrok-free.app/api/v1';

  // ── Auth ──
  static const String login  = '/login';
  static const String logout = '/logout';
  static const String signup = '/signup';

  // ── Resources ──
  static const String users          = '/users';
  static const String pushToken      = '/users/push_token';
  static const String lavvaggios     = '/lavvaggios';
  static const String devices        = '/devices';
  static const String events         = '/car_wash_events';
  static const String carWashEvents  = '/car_wash_events';
  static const String deviceLogs     = '/device_logs';
  static const String reports        = '/reports';
  static const String notifications  = '/notifications';

  // ── Computed paths ──
  static String lavvaggioStats(int id)   => '/lavvaggios/$id/stats';
  static String reportDownload(int id)   => '/reports/$id/download';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsMarkAllRead = '/notifications/mark_all_read';
  static const String notificationsUnreadCount = '/notifications/unread_count';
}
