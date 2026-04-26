class ApiConstants {
  ApiConstants._();

  // ── Change only this when going to production ──
  static const String baseUrl = 'https://3fe4-94-167-196-116.ngrok-free.app/api/v1';

  // ── Auth ──
  static const String login  = '/login';
  static const String logout = '/logout';
  static const String signup = '/signup';

  // ── Resources ──
  static const String users       = '/users';
  static const String lavvaggios  = '/lavvaggios';
  static const String devices     = '/devices';
  static const String events        = '/car_wash_events';
  static const String carWashEvents = '/car_wash_events';
  static const String deviceLogs    = '/device_logs';

  // ── Push notifications ──
  static const String pushToken = '/users/push_token';
}