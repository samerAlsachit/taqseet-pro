import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPath}',
        connectTimeout: AppConstants.syncTimeout,
        receiveTimeout: AppConstants.syncTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception('انتهت مهلة الاتصال');
        case DioExceptionType.sendTimeout:
          return Exception('انتهت مهلة الإرسال');
        case DioExceptionType.receiveTimeout:
          return Exception('انتهت مهلة الاستلام');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'خطأ في الخادم';
          return Exception('خطأ $statusCode: $message');
        case DioExceptionType.cancel:
          return Exception('تم إلغاء الطلب');
        case DioExceptionType.connectionError:
          return Exception('خطأ في الاتصال بالإنترنت');
        case DioExceptionType.badCertificate:
          return Exception('شهادة SSL غير صالحة');
        case DioExceptionType.unknown:
          return Exception('خطأ غير معروف: ${error.message}');
      }
    }
    return Exception('خطأ: $error');
  }
}
