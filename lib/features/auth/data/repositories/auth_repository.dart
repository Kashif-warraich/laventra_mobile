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

    // Persist session and biometric credentials
    await _storage.setToken(token);
    await _storage.setUser(user.toJsonString());
    await _storage.setBiometricCredentials(email, password);

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
}