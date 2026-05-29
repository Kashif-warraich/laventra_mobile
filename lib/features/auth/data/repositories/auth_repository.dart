import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/push_notification_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _dio     = ApiClient.instance.dio;
  final _storage = SecureStorage.instance;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'user': {
          'email':    email,
          'password': password,
        },
      },
    );

    final data  = response.data['data'];
    final token = data['token'] as String;
    final user  = UserModel.fromJson(data['user']);

    // Persist session. Biometric credentials are only stored once the user
    // has a "real" password — for first-time activation logins (random
    // password from the email) we wait until change-password succeeds.
    await _storage.setToken(token);
    await _storage.setUser(user.toJsonString());
    if (!user.mustChangePassword) {
      await _storage.setBiometricCredentials(email, password);
    }

    // Initialize push notifications and register FCM token with backend
    try {
      await PushNotificationService.instance.initialize();
      await PushNotificationService.instance.registerToken();
    } catch (_) {
      // Non-fatal — push registration can be retried later
    }

    return user;
  }

  Future<void> logout({bool preserveForBiometric = false}) async {
    try {
      await _dio.delete(ApiConstants.logout);
    } catch (_) {}
    if (!preserveForBiometric) {
      await _storage.clearAll();
    }
    // If preserveForBiometric=true, local token+user stay in Keychain so Face ID
    // can unlock the session on next launch (same pattern as banking apps).
    // The server session is already invalidated above.
  }

  Future<UserModel?> getStoredUser() async {
    final userStr = await _storage.getUser();
    if (userStr == null) return null;
    return UserModel.fromJsonString(userStr);
  }

  Future<bool> hasToken() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<({String email, String password})?> getBiometricCredentials() async {
    return await _storage.getBiometricCredentials();
  }

  /// Sets a new password for the currently logged-in user. Used by the
  /// post-activation change-password screen. The server clears
  /// must_change_password in the response, and we persist both the updated
  /// user and the new biometric credentials.
  Future<UserModel> changePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _dio.post(
      ApiConstants.changePassword,
      data: {
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final user = UserModel.fromJson(res.data['data']);
    await _storage.setUser(user.toJsonString());
    await _storage.setBiometricCredentials(user.email, password);
    return user;
  }
}