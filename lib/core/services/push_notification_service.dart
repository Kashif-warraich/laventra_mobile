/// Push notification service — disabled until Firebase is configured.
/// To re-enable: uncomment firebase_core, firebase_messaging, and
/// flutter_local_notifications in pubspec.yaml, add GoogleService-Info.plist
/// (iOS) and google-services.json (Android), then restore this file from git.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  Future<void> initialize() async {}
  Future<void> registerToken() async {}
  Future<void> requestPermissions() async {}
  Future<String?> getToken() async => null;
}
