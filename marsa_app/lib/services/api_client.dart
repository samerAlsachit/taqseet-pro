import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  Dio? _dio;

  Dio get client {
    if (_dio == null) _init();
    return _dio!;
  }

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.API_URL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) debugPrint('🌐 ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onError: (error, handler) {
        if (kDebugMode) debugPrint('❌ API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    final response = await client.get(path, queryParameters: params);
    return response.data;
  }
}
