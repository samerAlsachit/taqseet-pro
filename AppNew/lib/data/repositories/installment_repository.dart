import '../datasources/remote/api_service.dart';
import '../models/installment_model.dart';
import '../models/payment_model.dart';

class InstallmentRepository {
  final _api = ApiService();

  Future<List<InstallmentModel>> getAll({String? search, String? status, String? customerId}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null) params['status'] = status;
      if (customerId != null && customerId.isNotEmpty) params['customer_id'] = customerId;
      final res = await _api.get('/installments', params: params);
      if (res['success'] == true) {
        final list = (res['data']['installments'] as List?)?.map((e) => InstallmentModel.fromJson(e)).toList() ?? [];
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<InstallmentModel> getById(String id) async {
    final res = await _api.get('/installments/$id');
    if (res['success'] != true) throw Exception('فشل جلب بيانات القسط');
    final planData = res['data']['plan'] ?? res['data'];
    return InstallmentModel.fromJson(planData);
  }

  Future<InstallmentModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/installments', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل إنشاء القسط');
    final planData = res['data']['plan'] ?? res['data'];
    return InstallmentModel.fromJson(planData);
  }

  Future<List<ScheduleModel>> getSchedules(String planId) async {
    final res = await _api.get('/installments/$planId');
    if (res['success'] != true) return [];
    final schedules = (res['data']['schedules'] as List?)?.map((e) => ScheduleModel.fromJson(e)).toList() ?? [];
    return schedules;
  }

  Future<List<PaymentModel>> getPayments(String planId) async {
    try {
      final res = await _api.get('/payments/statement/$planId');
      if (res['success'] == true) {
        return (res['data'] as List?)?.map((e) => PaymentModel.fromJson(e)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
}
