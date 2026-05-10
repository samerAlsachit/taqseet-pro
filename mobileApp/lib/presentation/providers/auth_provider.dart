import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../services/api/api_service.dart';

class AuthProvider extends ChangeNotifier {
  // Use same secure storage instance across the app
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final _localAuth = LocalAuthentication();
  final _apiService = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoading = true; // Start as true during initialization
  String? _error;
  bool _isBiometricEnabled = false;
  bool _isSubscriptionExpired = false;
  String? _subscriptionErrorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isSubscriptionExpired => _isSubscriptionExpired;
  String? get subscriptionErrorMessage => _subscriptionErrorMessage;

  AuthProvider() {
    // Load stored auth in background
    Future.microtask(() => _loadStoredAuth());
  }

  Future<void> _loadStoredAuth() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      final userJson = await _secureStorage.read(key: AppConstants.userKey);
      final biometricEnabled = await _secureStorage.read(
        key: AppConstants.biometricEnabledKey,
      );

      debugPrint('🔑 Stored Token: ${token != null ? 'found' : 'not found'}');
      debugPrint('👤 Stored User: ${userJson != null ? 'found' : 'not found'}');

      if (token != null && userJson != null) {
        try {
          _token = token;
          _user = UserModel.fromJson(jsonDecode(userJson));
          _isBiometricEnabled = biometricEnabled == 'true';
          debugPrint('✅ Auth loaded successfully: ${_user?.username}');
        } catch (e) {
          debugPrint('❌ Error parsing stored user data: $e');
          // Clear corrupted data
          await _secureStorage.delete(key: AppConstants.tokenKey);
          await _secureStorage.delete(key: AppConstants.userKey);
          _token = null;
          _user = null;
        }
      } else {
        debugPrint('ℹ️ No stored auth found - user needs to login');
        _token = null;
        _user = null;
      }
    } catch (e) {
      debugPrint('❌ Error loading auth from secure storage: $e');
      _token = null;
      _user = null;
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

      if (result.success && result.token != null && result.user != null) {
        _token = result.token;
        _user = result.user;

        debugPrint(
            '✅ Login successful, saving token: ${_token?.substring(0, 10)}...');

        try {
          // Save to secure storage
          await _secureStorage.write(
            key: AppConstants.tokenKey,
            value: _token!,
          );
          await _secureStorage.write(
            key: AppConstants.userKey,
            value: jsonEncode(_user!.toJson()),
          );

          // Verify token was saved
          final savedToken =
              await _secureStorage.read(key: AppConstants.tokenKey);
          debugPrint(
              '🔐 Token saved verification: ${savedToken != null ? 'success ✓' : 'failed ✗'}');

          if (savedToken == null) {
            _error = 'فشل حفظ بيانات الدخول';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (storageError) {
          debugPrint('❌ Storage error: $storageError');
          _error = 'خطأ في حفظ البيانات: $storageError';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'فشل تسجيل الدخول';
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

  /// Set subscription expired status when API returns 403
  void setSubscriptionExpired(String? message) {
    _isSubscriptionExpired = true;
    _subscriptionErrorMessage =
        message ?? 'انتهى اشتراكك. يرجى التجديد للاستمرار.';
    debugPrint('🔴 Subscription expired set: $_subscriptionErrorMessage');
    notifyListeners();
  }

  /// Clear subscription expired status (after renewal)
  void clearSubscriptionExpired() {
    _isSubscriptionExpired = false;
    _subscriptionErrorMessage = null;
    debugPrint('✅ Subscription expired cleared');
    notifyListeners();
  }

  /// Check if error is subscription-related and set status
  bool checkAndHandleSubscriptionError(String? errorMessage) {
    if (errorMessage == null) return false;

    final subscriptionKeywords = [
      'subscription',
      'اشتراك',
      'منتهي',
      'expired',
      'تجديد',
      'renew',
      '403',
    ];

    final isSubscriptionError = subscriptionKeywords.any(
      (keyword) => errorMessage.toLowerCase().contains(keyword.toLowerCase()),
    );

    if (isSubscriptionError) {
      setSubscriptionExpired(errorMessage);
      return true;
    }
    return false;
  }
}
