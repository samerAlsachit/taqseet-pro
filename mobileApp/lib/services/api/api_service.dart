import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectionTimeout),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 - Token expired
          if (error.response?.statusCode == 401) {
            // Try to refresh token or logout
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _getToken() async {
    // Implementation using secure storage
    return null;
  }

  // Auth APIs
  Future<LoginResult> login(String username, String password) async {
    try {
      debugPrint(
          '🔌 Attempting login to: ${ApiConstants.apiBaseUrl}${ApiConstants.login}');
      debugPrint('📤 Sending: username=$username, password=***');

      final response = await _dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      debugPrint('📥 Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data == null) {
          return LoginResult(
            success: false,
            message: 'Invalid response: data is null',
          );
        }
        final userData = data['user'];
        if (userData == null || userData is! Map<String, dynamic>) {
          return LoginResult(
            success: false,
            message: 'Invalid response: user data is missing or invalid',
          );
        }
        return LoginResult(
          success: true,
          token: data['token']?.toString(),
          user: UserModel.fromJson(userData),
          message: response.data['message']?.toString(),
        );
      } else {
        return LoginResult(
          success: false,
          message: response.data['error'] ??
              response.data['message'] ??
              'Login failed',
        );
      }
    } on DioException catch (e) {
      String errorMessage;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout - check if server is running';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Cannot connect to server at ${ApiConstants.apiBaseUrl}\\nPlease check:\\n1. Server is running\\n2. Phone & PC on same WiFi\\n3. IP address is correct';
          break;
        case DioExceptionType.badResponse:
          errorMessage =
              'Server error: ${e.response?.statusCode} - ${e.response?.data?['error'] ?? e.response?.statusMessage}';
          break;
        default:
          errorMessage = 'Network error: ${e.message}';
      }

      debugPrint('❌ Login error: $errorMessage');
      debugPrint('   DioException type: ${e.type}');
      debugPrint('   DioException message: ${e.message}');

      return LoginResult(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return LoginResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ApiResult> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );

      return ApiResult(
        success: response.statusCode == 200 && response.data['success'],
        message: response.data['message'],
        data: response.data,
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? 'Network error',
      );
    }
  }

  Future<ApiResult> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {'token': token, 'new_password': newPassword},
      );

      return ApiResult(
        success: response.statusCode == 200 && response.data['success'],
        message: response.data['message'],
        data: response.data,
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? 'Network error',
      );
    }
  }

  // Generic GET
  Future<ApiResult> get(String endpoint, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: params);
      return ApiResult(
        success: response.statusCode == 200,
        data: response.data,
        message: response.data?['message'],
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? 'Network error',
      );
    }
  }

  // Generic POST
  Future<ApiResult> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return ApiResult(
        success: response.statusCode == 200 || response.statusCode == 201,
        data: response.data,
        message: response.data?['message'],
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? 'Network error',
      );
    }
  }

  // Generic PUT
  Future<ApiResult> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return ApiResult(
        success: response.statusCode == 200,
        data: response.data,
        message: response.data?['message'],
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? 'Network error',
      );
    }
  }

  // Generic DELETE
  Future<ApiResult> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return ApiResult(
        success: response.statusCode == 200,
        data: response.data,
        message: response.data?['message'],
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? 'Network error',
      );
    }
  }
}

class LoginResult {
  final bool success;
  final String? token;
  final UserModel? user;
  final String? message;

  LoginResult({
    required this.success,
    this.token,
    this.user,
    this.message,
  });
}

class ApiResult {
  final bool success;
  final dynamic data;
  final String? message;

  ApiResult({
    required this.success,
    this.data,
    this.message,
  });
}
