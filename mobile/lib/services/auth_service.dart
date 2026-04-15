import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AuthService - خدمة التوثيق
/// تتعامل مع تسجيل الدخول والخروج وحفظ التوكن بشكل آمن
class AuthService {
  static const String _baseUrl = 'http://192.168.0.196:3000/api';
  static const String _tokenKey = 'auth_token';
  static const String _storeIdKey = 'store_id';
  static const String _userDataKey = 'user_data';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add Logging Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('═══════════════════════════════════════════');
          debugPrint('🚀 AUTH REQUEST');
          debugPrint('═══════════════════════════════════════════');
          debugPrint('➡️  Method: ${options.method}');
          debugPrint('➡️  URL: ${options.uri}');
          debugPrint('➡️  Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('➡️  Body: ${options.data}');
          }
          debugPrint('═══════════════════════════════════════════\n');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('═══════════════════════════════════════════');
          debugPrint('✅ AUTH RESPONSE');
          debugPrint('═══════════════════════════════════════════');
          debugPrint('⬅️  Status Code: ${response.statusCode}');
          debugPrint('⬅️  URL: ${response.requestOptions.uri}');
          debugPrint('⬅️  Data: ${response.data}');
          debugPrint('═══════════════════════════════════════════\n');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('═══════════════════════════════════════════');
          debugPrint('❌ AUTH ERROR');
          debugPrint('═══════════════════════════════════════════');
          debugPrint('⬅️  Status Code: ${error.response?.statusCode}');
          debugPrint('⬅️  URL: ${error.requestOptions.uri}');
          debugPrint('⬅️  Error: ${error.message}');
          if (error.response?.data != null) {
            debugPrint('⬅️  Response Data: ${error.response?.data}');
          }
          debugPrint('═══════════════════════════════════════════\n');
          return handler.next(error);
        },
      ),
    );
  }

  /// تسجيل الدخول
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // حفظ التوكن والبيانات بشكل آمن
        await _secureStorage.write(key: _tokenKey, value: data['token']);
        await _secureStorage.write(key: _storeIdKey, value: data['store_id']?.toString());
        await _secureStorage.write(key: _userDataKey, value: jsonEncode(data));

        return AuthResult.success(
          token: data['token'],
          storeId: data['store_id']?.toString(),
          userData: data,
        );
      } else if (response.statusCode == 401) {
        return AuthResult.error('اسم المستخدم أو كلمة المرور غير صحيحة');
      } else {
        final error = response.data;
        return AuthResult.error(error['message'] ?? 'حدث خطأ غير متوقع');
      }
    } on DioException catch (e) {
      debugPrint('AuthService.login DioException: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return AuthResult.error('انتهت مهلة الاتصال (15 ثانية)، تأكد من تشغيل الـ API');
      }
      if (e.response?.statusCode == 401) {
        return AuthResult.error('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      return AuthResult.error('تعذر الاتصال بالخادم: ${e.message}');
    } catch (e) {
      debugPrint('AuthService.login error: $e');
      return AuthResult.error('تعذر الاتصال بالخادم، تأكد من تشغيل الـ API');
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _storeIdKey);
    await _secureStorage.delete(key: _userDataKey);
  }

  /// التحقق من وجود توكن محفوظ (للدخول التلقائي)
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// الحصول على التوكن
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// الحصول على معرف المتجر
  Future<String?> getStoreId() async {
    return await _secureStorage.read(key: _storeIdKey);
  }

  /// الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _secureStorage.read(key: _userDataKey);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }
}

/// نتيجة عملية التوثيق
class AuthResult {
  final bool success;
  final String? token;
  final String? storeId;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  AuthResult._({
    required this.success,
    this.token,
    this.storeId,
    this.userData,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String token,
    String? storeId,
    Map<String, dynamic>? userData,
  }) {
    return AuthResult._(
      success: true,
      token: token,
      storeId: storeId,
      userData: userData,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      success: false,
      errorMessage: message,
    );
  }
}
