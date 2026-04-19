import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/app_config.dart';
import '../screens/login_screen.dart';

/// ApiClient - عميل HTTP مركزي
/// يضيف التوكن تلقائياً ويعالج أخطاء 401
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Dio? _dio;
  bool _isInitialized = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  void clearContext() {
    _context = null;
  }

  /// Initialize the Dio client with interceptors
  void init() {
    if (_isInitialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.API_URL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _isInitialized = true;

    // Add Token Interceptor
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Bearer token to all requests except login
          if (!options.path.contains('/auth/login')) {
            final token = await _secureStorage.read(key: _tokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              if (kDebugMode) {
                print('🔐 ApiClient: Added Bearer token to ${options.path}');
              }
            } else {
              if (kDebugMode) {
                print('⚠️ ApiClient: No token found for ${options.path}');
              }
            }
          }

          if (kDebugMode) {
            print('═══════════════════════════════════════════');
            print('🚀 API REQUEST');
            print('═══════════════════════════════════════════');
            print('➡️  Method: ${options.method}');
            print('➡️  URL: ${options.uri}');
            print('➡️  Headers: ${options.headers}');
            if (options.data != null) {
              print('➡️  Body: ${options.data}');
            }
            print('═══════════════════════════════════════════\n');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('═══════════════════════════════════════════');
            print('✅ API RESPONSE');
            print('═══════════════════════════════════════════');
            print('⬅️  Status Code: ${response.statusCode}');
            print('⬅️  URL: ${response.requestOptions.uri}');
            print('⬅️  Data: ${response.data}');
            print('═══════════════════════════════════════════\n');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (kDebugMode) {
            print('═══════════════════════════════════════════');
            print('❌ API ERROR');
            print('═══════════════════════════════════════════');
            print('⬅️  Status Code: ${error.response?.statusCode}');
            print('⬅️  URL: ${error.requestOptions.uri}');
            print('⬅️  Error: ${error.message}');
            if (error.response?.data != null) {
              print('⬅️  Response Data: ${error.response?.data}');
            }
            print('═══════════════════════════════════════════\n');
          }

          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            print('🔒 ApiClient: 401 Unauthorized - Token expired or invalid');

            // Clear stored token
            await _secureStorage.delete(key: _tokenKey);
            await _secureStorage.delete(key: 'store_id');
            await _secureStorage.delete(key: 'user_data');

            // Navigate to login if context is available
            if (_context != null && _context!.mounted) {
              print('🔄 ApiClient: Navigating to login screen...');
              Navigator.pushAndRemoveUntil(
                _context!,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Get the Dio instance
  Dio get dio {
    if (!_isInitialized) {
      init();
    }
    return _dio!;
  }

  /// Check if the client is initialized
  bool get isInitialized => _isInitialized;

  /// Save token after login
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    print('💾 ApiClient: Token saved to secure storage');
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Clear token (logout)
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: 'store_id');
    await _secureStorage.delete(key: 'user_data');
    print('🗑️ ApiClient: Token cleared from secure storage');
  }
}
