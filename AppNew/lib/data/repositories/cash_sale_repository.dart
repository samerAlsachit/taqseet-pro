import '../datasources/remote/api_service.dart';

class CashSaleRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _api.post('/cash-sales', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل تسجيل البيع');
    return res['data'];
  }
}
