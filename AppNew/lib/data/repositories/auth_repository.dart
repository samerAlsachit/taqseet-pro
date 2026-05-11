import '../../core/logger/app_logger.dart';
import '../../services/auth_service.dart';
import '../datasources/remote/api_service.dart';
import '../models/auth_response.dart';
import '../models/plan_model.dart';
import '../datasources/local/hive_service.dart';

class AuthRepository {
  final _api = ApiService();
  final _auth = AuthService();
  final _hive = HiveService();

  Future<AuthResponse> login(String username, String password) async {
    final res = await _api.post('/auth/login', data: {
      'username': username, 'password': password,
    });
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل تسجيل الدخول');
    final authRes = AuthResponse.fromJson(res['data']);
    await _auth.saveToken(authRes.token);
    _api.setToken(authRes.token);
    await _hive.putJson('store', {
      'id': authRes.store.id, 'name': authRes.store.name, 'is_active': authRes.store.isActive,
    });
    return authRes;
  }

  Future<AuthResponse> activate(String code) async {
    final res = await _api.post('/auth/activate', data: {'code': code});
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل التفعيل');
    final authRes = AuthResponse.fromJson(res['data']);
    await _auth.saveToken(authRes.token);
    _api.setToken(authRes.token);
    return authRes;
  }

  Future<AuthResponse> registerTrial(Map<String, dynamic> storeData) async {
    final res = await _api.post('/auth/register-trial', data: storeData);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل إنشاء الحساب');
    final authRes = AuthResponse.fromJson(res['data']);
    await _auth.saveToken(authRes.token);
    _api.setToken(authRes.token);
    return authRes;
  }

  Future<List<PlanModel>> getPlans() async {
    final res = await _api.get('/plans');
    if (res['success'] != true) return [];
    return (res['data'] as List).map((e) => PlanModel.fromJson(e)).toList();
  }

  Future<void> logout() async {
    await _auth.deleteToken();
    _api.setToken(null);
    await _hive.clear();
  }

  Future<bool> tryAutoLogin() async {
    final token = await _auth.getToken();
    if (token == null) return false;
    _api.setToken(token);
    try {
      final res = await _api.get('/auth/me');
      if (res['success'] == true) {
        await _hive.putJson('store', res['data']['store']);
        return true;
      }
    } catch (e) {
      AppLogger.warn('Auto login failed: $e');
    }
    return false;
  }
}
