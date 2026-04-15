import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// ApiService - خدمة الاتصال بالـ API مع Dio و Interceptors
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = 'http://192.168.0.196:3000/api';
  late final Dio _dio;
  final AuthService _authService = AuthService();

  Dio get dio => _dio;

  /// تهيئة Dio مع Interceptors
  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // إضافة Interceptors للـ Logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('═══════════════════════════════════════════');
          debugPrint('🚀 REQUEST');
          debugPrint('═══════════════════════════════════════════');
          debugPrint('➡️  Method: ${options.method}');
          debugPrint('➡️  URL: ${options.uri}');
          debugPrint('➡️  Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('➡️  Body: ${options.data}');
          }
          debugPrint('═══════════════════════════════════════════\n');

          // إضافة التوكن إذا كان موجوداً
          final token = await _authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔐 Token added to request: Bearer $token');
          } else {
            debugPrint('⚠️ No token available');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('═══════════════════════════════════════════');
          debugPrint('✅ RESPONSE');
          debugPrint('═══════════════════════════════════════════');
          debugPrint('⬅️  Status Code: ${response.statusCode}');
          debugPrint('⬅️  URL: ${response.requestOptions.uri}');
          debugPrint('⬅️  Data: ${response.data}');
          debugPrint('═══════════════════════════════════════════\n');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('═══════════════════════════════════════════');
          debugPrint('❌ ERROR');
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

  /// GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST Request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT Request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE Request
  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// معالجة الأخطاء
  Exception _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return Exception('انتهت مهلة الاتصال، تأكد من تشغيل الـ API');
    }

    if (error.response?.statusCode == 401) {
      return Exception('غير مصرح، يرجى تسجيل الدخول مرة أخرى');
    }

    if (error.response?.statusCode == 500) {
      return Exception('خطأ في السيرفر (500)، تحقق من logs');
    }

    return Exception(error.message ?? 'حدث خطأ غير متوقع');
  }

  /// جلب بيانات المتجر
  Future<Map<String, dynamic>?> fetchStoreData() async {
    try {
      final response = await get('/store');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error fetching store data: $e');
      rethrow;
    }
    return null;
  }

  /// جلب بيانات الـ Dashboard
  Future<Map<String, dynamic>?> fetchDashboardData() async {
    try {
      final response = await get('/dashboard');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      rethrow;
    }
    return null;
  }
}
