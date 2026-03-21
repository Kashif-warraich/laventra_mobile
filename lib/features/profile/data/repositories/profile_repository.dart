import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRepository {
  final _dio     = ApiClient.instance.dio;
  final _storage = SecureStorage.instance;

  Future<UserModel> getProfile(int userId) async {
    final response = await _dio.get('${ApiConstants.users}/$userId');
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> updateProfile({
    required int    userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.users}/$userId',
      data: {'user': data},
    );
    final updated = UserModel.fromJson(response.data['data']);
    // Keep storage in sync
    await _storage.setUser(updated.toJsonString());
    return updated;
  }

  Future<UserModel> updatePassword({
    required int    userId,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.users}/$userId',
      data: {
        'user': {
          'password':              password,
          'password_confirmation': passwordConfirmation,
        },
      },
    );
    return UserModel.fromJson(response.data['data']);
  }
}