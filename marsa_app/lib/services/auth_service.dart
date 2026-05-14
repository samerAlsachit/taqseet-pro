import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/app_config.dart';
import 'api_client.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _storeIdKey = 'store_id';
  static const String _storeNameKey = 'store_name';
  static const String _userDataKey = 'user_data';
  static const String _savedUsernameKey = 'saved_username';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.API_URL,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
  }

  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {'username': username, 'password': password});
      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData['data'];
        final token = data?['token'];
        if (token == null) return AuthResult.error('خطأ في البيانات: التوكن غير موجود');

        final user = data?['user'];
        final storeId = user?['store_id']?.toString();
        final storeName = data?['store']?['name']?.toString()
            ?? data?['store']?['store_name']?.toString()
            ?? data?['store_name']?.toString()
            ?? user?['store_name']?.toString();
        final role = user?['role'];

        if (data['store'] != null && data['store']['is_active'] == false) {
          return AuthResult.error('هذا المحل غير نشط. يرجى التواصل مع الدعم.');
        }

        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _storeIdKey, value: storeId ?? '');
        await _secureStorage.write(key: _savedUsernameKey, value: username);
        if (storeName != null && storeName.isNotEmpty) {
          await _secureStorage.write(key: _storeNameKey, value: storeName);
        }
        await _secureStorage.write(key: _userDataKey, value: jsonEncode({'token': token, 'user': user, 'store': data['store']}));

        return AuthResult.success(token: token, storeId: storeId, role: role, userData: {'token': token, 'user': user, 'store': data['store']});
      }
      final error = response.data;
      return AuthResult.error(error['error'] ?? 'فشل تسجيل الدخول');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return AuthResult.error('انتهت مهلة الاتصال، تأكد من تشغيل الخادم');
      }
      if (e.response?.statusCode == 401) {
        return AuthResult.error('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      return AuthResult.error('تعذر الاتصال بالخادم: ${e.message}');
    } catch (e) {
      return AuthResult.error('تعذر الاتصال بالخادم');
    }
  }

  Future<AuthResult> verifyCode(String code) async {
    try {
      final response = await _dio.post('/auth/verify-code', data: {'code': code});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return AuthResult.success(token: '');
      }
      return AuthResult.error(response.data['error'] ?? 'الكود غير صالح');
    } on DioException catch (e) {
      return AuthResult.error('تعذر الاتصال بالخادم: ${e.message}');
    } catch (e) {
      return AuthResult.error('تعذر الاتصال بالخادم');
    }
  }

  Future<AuthResult> activate(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/activate', data: data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data;
        final resultData = responseData['data'];
        final token = resultData?['token'];
        final storeId = resultData?['user']?['store_id']?.toString();
        final storeName = resultData?['store']?['name']?.toString();

        if (token != null) {
          await _secureStorage.write(key: _tokenKey, value: token);
          await _secureStorage.write(key: _storeIdKey, value: storeId ?? '');
          if (storeName != null && storeName.isNotEmpty) {
            await _secureStorage.write(key: _storeNameKey, value: storeName);
          }
          await _secureStorage.write(key: _userDataKey, value: jsonEncode(resultData));
        }

        return AuthResult.success(token: token, storeId: storeId, userData: resultData);
      }
      return AuthResult.error(response.data['error'] ?? 'فشل في تفعيل المحل');
    } on DioException catch (e) {
      return AuthResult.error('تعذر الاتصال بالخادم: ${e.message}');
    } catch (e) {
      return AuthResult.error('تعذر الاتصال بالخادم');
    }
  }

  Future<AuthResult> registerTrial(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register-trial', data: data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data;
        final resultData = responseData['data'];
        final token = resultData?['token'];
        final storeId = resultData?['user']?['store_id']?.toString();
        final storeName = resultData?['store']?['name']?.toString();

        if (token != null) {
          await _secureStorage.write(key: _tokenKey, value: token);
          await _secureStorage.write(key: _storeIdKey, value: storeId ?? '');
          if (storeName != null && storeName.isNotEmpty) {
            await _secureStorage.write(key: _storeNameKey, value: storeName);
          }
          await _secureStorage.write(key: _userDataKey, value: jsonEncode(resultData));
        }

        return AuthResult.success(token: token, storeId: storeId, userData: resultData);
      }
      return AuthResult.error(response.data['error'] ?? 'فشل في إنشاء الحساب');
    } on DioException catch (e) {
      return AuthResult.error('تعذر الاتصال بالخادم: ${e.message}');
    } catch (e) {
      return AuthResult.error('تعذر الاتصال بالخادم');
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _storeIdKey);
    await _secureStorage.delete(key: _userDataKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> fetchStoreName() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final res = await ApiClient().get('/store/settings');
      if (res['success'] == true) {
        final d = res['data'];
        final storeName = d is Map
            ? (d['name']?.toString() ?? d['store_name']?.toString())
            : null;
        if (storeName != null && storeName.isNotEmpty) {
          await _secureStorage.write(key: _storeNameKey, value: storeName);
          return storeName;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getToken() async => await _secureStorage.read(key: _tokenKey);
  Future<String?> getStoreId() async => await _secureStorage.read(key: _storeIdKey);
  Future<String?> getStoreName() async => await _secureStorage.read(key: _storeNameKey);
  Future<String?> getSavedUsername() async => await _secureStorage.read(key: _savedUsernameKey);
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _secureStorage.read(key: _userDataKey);
    return data != null ? jsonDecode(data) : null;
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final String? storeId;
  final String? role;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  AuthResult._({required this.success, this.token, this.storeId, this.role, this.userData, this.errorMessage});

  factory AuthResult.success({String? token, String? storeId, String? role, Map<String, dynamic>? userData}) {
    return AuthResult._(success: true, token: token, storeId: storeId, role: role, userData: userData);
  }

  factory AuthResult.error(String message) => AuthResult._(success: false, errorMessage: message);
}
