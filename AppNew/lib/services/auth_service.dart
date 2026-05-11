import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../core/logger/app_logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _tokenKey = 'jwt_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  Future<void> deleteToken() async => _storage.delete(key: _tokenKey);

  Future<bool> hasToken() async => (await _storage.read(key: _tokenKey)) != null;

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      AppLogger.warn('Biometric check failed: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'استخدم بصمتك لتسجيل الدخول',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (e) {
      AppLogger.warn('Biometric auth failed: $e');
      return false;
    }
  }
}
