import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static const _key = 'biometric_enabled';
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final deviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || deviceSupported;
    } catch (e) {
      debugPrint('BiometricService.isAvailable error: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'التحقق من بصمة الإصبع للدخول إلى التطبيق',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('BiometricService.authenticate error: $e');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final stored = await _storage.read(key: _key);
    return stored == 'true';
  }

  Future<void> setEnabled(bool value) async {
    await _storage.write(key: _key, value: value.toString());
  }
}
