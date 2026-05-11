import '../datasources/remote/api_service.dart';
import '../datasources/local/hive_service.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final _api = ApiService();
  final _hive = HiveService();

  Future<List<CustomerModel>> getAll({String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get('/customers', params: params);
      if (res['success'] == true) {
        final customers = ((res['data'] is List ? res['data'] : res['data']['customers']) as List).map((e) => CustomerModel.fromJson(e)).toList();
        await _hive.putList('customers', customers.map((e) => e.toJson()).toList());
        return customers;
      }
    } catch (_) {}
    final cached = _hive.getList('customers');
    return cached?.map((e) => CustomerModel.fromJson(e)).toList() ?? [];
  }

  Future<CustomerModel> getById(String id) async {
    final res = await _api.get('/customers/$id');
    if (res['success'] != true) throw Exception('فشل جلب بيانات العميل');
    final customerData = res['data']['customer'] ?? res['data'];
    return CustomerModel.fromJson(customerData);
  }

  Future<CustomerModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/customers', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل إضافة العميل');
    final customerData = res['data']['customer'] ?? res['data'];
    return CustomerModel.fromJson(customerData);
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/customers/$id', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل تحديث العميل');
    final customerData = res['data']['customer'] ?? res['data'];
    return CustomerModel.fromJson(customerData);
  }

  Future<void> delete(String id) async {
    final res = await _api.delete('/customers/$id');
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل حذف العميل');
  }
}
