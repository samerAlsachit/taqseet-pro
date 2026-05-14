import '../models/dashboard_stats.dart';
import 'api_client.dart';

class DashboardService {
  final _api = ApiClient();

  Future<DashboardStats> getStats() async {
    try {
      final res = await _api.get('/dashboard/stats');
      if (res['success'] == true) {
        return DashboardStats.fromJson(res['data']);
      }
    } catch (_) {}
    return DashboardStats.empty();
  }

  Future<List<Map<String, dynamic>>> getLatestInstallments({int limit = 5}) async {
    try {
      final res = await _api.get('/installments', params: {'limit': limit});
      if (res['success'] == true) {
        final list = res['data']['installments'] as List?;
        return list?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
}
