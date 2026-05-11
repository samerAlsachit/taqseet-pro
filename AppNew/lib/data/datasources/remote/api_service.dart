import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/logger/app_logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  late final Dio _dio;
  String? _token;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.API_URL,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        AppLogger.debug('🌐 ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug('✅ ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.error('❌ ${error.response?.statusCode} ${error.requestOptions.path}', error);
        handler.next(error);
      },
    ));
  }

  void setToken(String? token) => _token = token;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    final res = await _dio.get(path, queryParameters: params);
    return res.data;
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final res = await _dio.post(path, data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    final res = await _dio.put(path, data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _dio.delete(path);
    return res.data;
  }

  Future<Map<String, dynamic>> uploadFile(String path, String filePath, String field) async {
    final form = FormData.fromMap({
      field: await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post(path, data: form);
    return res.data;
  }

  Future<Map<String, dynamic>> uploadFiles(String path, List<MapEntry<String, String>> files) async {
    final form = FormData();
    for (final entry in files) {
      form.files.add(MapEntry(entry.key, await MultipartFile.fromFile(entry.value)));
    }
    final res = await _dio.post(path, data: form);
    return res.data;
  }
}
