import '../datasources/remote/api_service.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final _api = ApiService();

  Future<PaymentModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/payments', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل تسجيل الدفعة');
    final paymentData = res['data']['payment'] ?? res['data'];
    return PaymentModel.fromJson(paymentData);
  }

  Future<PaymentModel> fullSettlement(Map<String, dynamic> data) async {
    final res = await _api.post('/payments/full-settlement', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل تسديد كامل المبلغ');
    final paymentData = res['data']['payment'] ?? res['data'];
    return PaymentModel.fromJson(paymentData);
  }

  Future<String> getReceiptHtml(String receiptNumber) async {
    final res = await _api.get('/payments/receipt/$receiptNumber/print');
    if (res['success'] != true) throw Exception('فشل جلب الوصل');
    return res['data']['html'] ?? '';
  }
}
