import '../datasources/remote/api_service.dart';
import '../models/dashboard_stats.dart';
import '../models/installment_model.dart';

class DashboardRepository {
  final _api = ApiService();

  Future<DashboardStats?> getStats() async {
    try {
      final res = await _api.get('/dashboard/stats');
      if (res['success'] == true) {
        final stats = DashboardStats.fromJson(res['data']);
        return stats;
      }
    } catch (_) {}
    return null;
  }

  Future<List<InstallmentModel>> getRecentInstallments({int limit = 5}) async {
    try {
      final res = await _api.get('/installments', params: {'limit': limit});
      if (res['success'] == true) {
        final list = (res['data']['installments'] as List?)?.map((e) => InstallmentModel.fromJson(e)).toList() ?? [];
        return list;
      }
    } catch (_) {}
    return [];
  }
}
