import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';

class ApiService {
  late Dio _dio;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

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
    try {
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      debugPrint(
          '🔑 Token read: ${token != null ? 'exists (${token.substring(0, 10)}...)' : 'null'}');
      return token;
    } catch (e) {
      debugPrint('❌ Error reading token: $e');
      return null;
    }
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
          debugPrint('❌ Response data is null');
          return LoginResult(
            success: false,
            message: 'Invalid response: data is null',
          );
        }

        final token = data['token'];
        final userData = data['user'];

        debugPrint(
            '🔐 Token from server: ${token != null ? 'received' : 'null'}');
        debugPrint(
            '👤 User from server: ${userData != null ? 'received' : 'null'}');

        if (userData == null || userData is! Map<String, dynamic>) {
          debugPrint('❌ User data is invalid');
          return LoginResult(
            success: false,
            message: 'Invalid response: user data is missing or invalid',
          );
        }

        if (token == null) {
          debugPrint('❌ Token is null from server');
          return LoginResult(
            success: false,
            message: 'Invalid response: token is missing',
          );
        }

        return LoginResult(
          success: true,
          token: token.toString(),
          user: UserModel.fromJson(userData),
          message: response.data['message']?.toString(),
        );
      } else {
        debugPrint('❌ Login response not successful: ${response.data}');
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

  // Customer APIs
  Future<ApiResult> getCustomers() async {
    return get(ApiConstants.customers);
  }

  Future<ApiResult> getCustomerById(String id) async {
    return get(ApiConstants.customerById.replaceAll('{id}', id));
  }

  Future<ApiResult> createCustomer(Map<String, dynamic> data) async {
    return post(ApiConstants.customers, data: data);
  }

  Future<ApiResult> updateCustomer(String id, Map<String, dynamic> data) async {
    return put(ApiConstants.customerById.replaceAll('{id}', id), data: data);
  }

  Future<ApiResult> deleteCustomer(String id) async {
    return delete(ApiConstants.customerById.replaceAll('{id}', id));
  }

  Future<ApiResult> createCustomerWithImages({
    required Map<String, dynamic> data,
    File? avatarFile,
    File? idCardFrontFile,
    File? idCardBackFile,
    File? residenceFrontFile,
    File? residenceBackFile,
  }) async {
    try {
      final formData = FormData();

      // Add text fields
      data.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add files
      if (avatarFile != null && await avatarFile.exists()) {
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatarFile.path, filename: 'avatar.jpg'),
        ));
      }
      if (idCardFrontFile != null && await idCardFrontFile.exists()) {
        formData.files.add(MapEntry(
          'id_card_front',
          await MultipartFile.fromFile(idCardFrontFile.path,
              filename: 'id_card_front.jpg'),
        ));
      }
      if (idCardBackFile != null && await idCardBackFile.exists()) {
        formData.files.add(MapEntry(
          'id_card_back',
          await MultipartFile.fromFile(idCardBackFile.path,
              filename: 'id_card_back.jpg'),
        ));
      }
      if (residenceFrontFile != null && await residenceFrontFile.exists()) {
        formData.files.add(MapEntry(
          'residence_front',
          await MultipartFile.fromFile(residenceFrontFile.path,
              filename: 'residence_front.jpg'),
        ));
      }
      if (residenceBackFile != null && await residenceBackFile.exists()) {
        formData.files.add(MapEntry(
          'residence_back',
          await MultipartFile.fromFile(residenceBackFile.path,
              filename: 'residence_back.jpg'),
        ));
      }

      final response = await _dio.post(
        ApiConstants.customers,
        data: formData,
        options: Options(headers: await _getHeaders()),
      );

      return ApiResult(
        success: response.statusCode == 200 || response.statusCode == 201,
        data: response.data['data'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? e.message ?? 'Upload failed',
      );
    } catch (e) {
      return ApiResult(success: false, message: e.toString());
    }
  }

  Future<ApiResult> updateCustomerWithImages({
    required String id,
    required Map<String, dynamic> data,
    File? avatarFile,
    File? idCardFrontFile,
    File? idCardBackFile,
    File? residenceFrontFile,
    File? residenceBackFile,
  }) async {
    try {
      final formData = FormData();

      // Add text fields
      data.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add files
      if (avatarFile != null && await avatarFile.exists()) {
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatarFile.path, filename: 'avatar.jpg'),
        ));
      }
      if (idCardFrontFile != null && await idCardFrontFile.exists()) {
        formData.files.add(MapEntry(
          'id_card_front',
          await MultipartFile.fromFile(idCardFrontFile.path,
              filename: 'id_card_front.jpg'),
        ));
      }
      if (idCardBackFile != null && await idCardBackFile.exists()) {
        formData.files.add(MapEntry(
          'id_card_back',
          await MultipartFile.fromFile(idCardBackFile.path,
              filename: 'id_card_back.jpg'),
        ));
      }
      if (residenceFrontFile != null && await residenceFrontFile.exists()) {
        formData.files.add(MapEntry(
          'residence_front',
          await MultipartFile.fromFile(residenceFrontFile.path,
              filename: 'residence_front.jpg'),
        ));
      }
      if (residenceBackFile != null && await residenceBackFile.exists()) {
        formData.files.add(MapEntry(
          'residence_back',
          await MultipartFile.fromFile(residenceBackFile.path,
              filename: 'residence_back.jpg'),
        ));
      }

      final url = ApiConstants.customerById.replaceAll('{id}', id);
      final response = await _dio.put(
        url,
        data: formData,
        options: Options(headers: await _getHeaders()),
      );

      return ApiResult(
        success: response.statusCode == 200,
        data: response.data['data'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResult(
        success: false,
        message: e.response?.data?['error'] ?? e.message ?? 'Upload failed',
      );
    } catch (e) {
      return ApiResult(success: false, message: e.toString());
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
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
