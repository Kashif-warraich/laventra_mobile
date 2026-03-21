import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';
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

    // Persist both
    await _storage.setToken(token);
    await _storage.setUser(user.toJsonString());

    return user;
  }

  Future<void> logout() async {
    try {
      await _dio.delete(ApiConstants.logout);
    } finally {
      // Always clear local storage even if API call fails
      await _storage.clearAll();
    }
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
}