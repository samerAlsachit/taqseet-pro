import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../services/api/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _apiService = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isBiometricEnabled = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isBiometricEnabled => _isBiometricEnabled;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      final userJson = await _secureStorage.read(key: AppConstants.userKey);
      final biometricEnabled = await _secureStorage.read(
        key: AppConstants.biometricEnabledKey,
      );

      if (token != null && userJson != null) {
        _token = token;
        _user = UserModel.fromJson(jsonDecode(userJson));
        _isBiometricEnabled = biometricEnabled == 'true';
      }
    } catch (e) {
      print('Error loading auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(username, password);

      if (result.success) {
        _token = result.token;
        _user = result.user;

        debugPrint(
            '✅ Login successful, saving token: ${_token?.substring(0, 10)}...');

        // Save to secure storage
        await _secureStorage.write(
          key: AppConstants.tokenKey,
          value: _token,
        );
        await _secureStorage.write(
          key: AppConstants.userKey,
          value: jsonEncode(_user!.toJson()),
        );

        // Verify token was saved
        final savedToken =
            await _secureStorage.read(key: AppConstants.tokenKey);
        debugPrint(
            '🔐 Token saved verification: ${savedToken != null ? 'success' : 'failed'}');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'فشل في تسجيل الدخول: $e';
      debugPrint('❌ AuthProvider login error: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    if (!_isBiometricEnabled) return false;

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'استخدم البصمة للدخول إلى التطبيق',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  Future<void> enableBiometric(bool enable) async {
    _isBiometricEnabled = enable;
    await _secureStorage.write(
      key: AppConstants.biometricEnabledKey,
      value: enable ? 'true' : 'false',
    );
    notifyListeners();
  }

  Future<bool> checkBiometricAvailability() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final availableBiometrics = await _localAuth.getAvailableBiometrics();
    return isAvailable && availableBiometrics.isNotEmpty;
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _error = 'فشل في إرسال طلب استعادة كلمة المرور';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.resetPassword(token, newPassword);
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _error = 'فشل في إعادة تعيين كلمة المرور';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _secureStorage.delete(key: AppConstants.tokenKey);
      await _secureStorage.delete(key: AppConstants.userKey);
      // Keep biometric setting

      _token = null;
      _user = null;
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
