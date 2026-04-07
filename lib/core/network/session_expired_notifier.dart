import 'dart:async';

/// A singleton stream that fires whenever the API returns a 401.
/// AuthBloc subscribes to this and emits AuthUnauthenticated automatically.
class SessionExpiredNotifier {
  SessionExpiredNotifier._();
  static final SessionExpiredNotifier instance = SessionExpiredNotifier._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}
