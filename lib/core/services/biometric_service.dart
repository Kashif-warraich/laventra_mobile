import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();

  /// Whether the device supports biometrics (Face ID, Touch ID, fingerprint).
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      debugPrint('BiometricService.isAvailable: $e');
      return false;
    }
  }

  /// Returns the list of enrolled biometric types on the device.
  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricService.availableTypes: $e');
      return [];
    }
  }

  /// Prompt the user to authenticate. Returns true on success.
  Future<bool> authenticate({String reason = 'Verify your identity to sign in'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow passcode as fallback
          stickyAuth: true,     // keep prompt if app is backgrounded
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService.authenticate: $e');
      return false;
    }
  }

  /// Human-readable label for the strongest available biometric.
  Future<String> biometricLabel() async {
    final types = await availableTypes();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.strong)) return 'Biometrics';
    return 'Biometrics';
  }

  /// Icon name hint — callers use this to pick an icon.
  Future<bool> isFaceId() async {
    final types = await availableTypes();
    return types.contains(BiometricType.face);
  }
}
