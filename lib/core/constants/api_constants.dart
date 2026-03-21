class ApiConstants {
  ApiConstants._();

  // ── Change only this when going to production ──
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // ── Auth ──
  static const String login  = '/login';
  static const String logout = '/logout';
  static const String signup = '/signup';

  // ── Resources ──
  static const String users       = '/users';
  static const String lavvaggios  = '/lavvaggios';
  static const String devices     = '/devices';
  static const String events      = '/car_wash_events';
}