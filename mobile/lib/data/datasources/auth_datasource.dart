import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

class AuthDataSource {
  final ApiClient _apiClient;
  final SharedPreferences _sharedPreferences;

  AuthDataSource(this._apiClient, this._sharedPreferences);

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final user = data['user'];
        
        // حفظ التوكن والبيانات
        await _sharedPreferences.setString(AppConstants.tokenKey, token);
        await _sharedPreferences.setString(AppConstants.userIdKey, user['id'].toString());
        await _sharedPreferences.setString(AppConstants.storeIdKey, user['store_id'].toString());
        
        _apiClient.setAuthToken(token);
        
        return {
          'success': true,
          'user': user,
          'token': token,
        };
      } else {
        throw Exception('فشل تسجيل الدخول');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> logout() async {
    try {
      // مسح التوكن من الـ API client
      _apiClient.clearAuthToken();
      
      // مسح البيانات من SharedPreferences
      await _sharedPreferences.remove(AppConstants.tokenKey);
      await _sharedPreferences.remove(AppConstants.userIdKey);
      await _sharedPreferences.remove(AppConstants.storeIdKey);
    } catch (e) {
      throw Exception('فشل تسجيل الخروج: $e');
    }
  }

  Future<String?> getToken() async {
    return _sharedPreferences.getString(AppConstants.tokenKey);
  }

  Future<String?> getUserId() async {
    return _sharedPreferences.getString(AppConstants.userIdKey);
  }

  Future<String?> getStoreId() async {
    return _sharedPreferences.getString(AppConstants.storeIdKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveToken(String token) async {
    await _sharedPreferences.setString(AppConstants.tokenKey, token);
    _apiClient.setAuthToken(token);
  }

  Future<void> initializeAuth() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
    }
  }
}
