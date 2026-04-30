import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  SecureStorage._();
  static SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> setToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<void> setUser(String userJson) async {
    await _storage.write(key: AppConstants.userKey, value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: AppConstants.userKey);
  }

  Future<void> removeUser() async {
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clears auth session but preserves biometric credentials and preference
  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<bool> getBiometricEnabled() async {
    final val = await _storage.read(key: AppConstants.biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<void> setBiometricCredentials(String email, String password) async {
    await _storage.write(key: AppConstants.biometricEmailKey, value: email);
    await _storage.write(key: AppConstants.biometricPasswordKey, value: password);
  }

  Future<({String email, String password})?> getBiometricCredentials() async {
    final email    = await _storage.read(key: AppConstants.biometricEmailKey);
    final password = await _storage.read(key: AppConstants.biometricPasswordKey);
    if (email != null && password != null) return (email: email, password: password);
    return null;
  }

  Future<void> clearBiometricCredentials() async {
    await _storage.delete(key: AppConstants.biometricEmailKey);
    await _storage.delete(key: AppConstants.biometricPasswordKey);
    await _storage.delete(key: AppConstants.biometricEnabledKey);
  }
}