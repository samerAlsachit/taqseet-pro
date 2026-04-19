import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'thabit_pull_sync_service.dart';

/// InstallmentService - خدمة إدارة الأقساط
/// تستخدم endpoint: POST /api/installments (المسار الصحيح في السيرفر)
class InstallmentService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  /// إنشاء قسط جديد - يتوافق مع API السيرفر
  Future<Map<String, dynamic>> createInstallment({
    required String customerId,
    required List<Map<String, dynamic>> products,
    required double totalPrice,
    required double downPayment,
    required double installmentAmount,
    required String frequency,
    required DateTime startDate,
    String currency = 'IQD',
    String? notes,
  }) async {
    try {
      // التحقق من البيانات الأساسية
      if (customerId.isEmpty) {
        return {
          'success': false,
          'message': 'يجب اختيار العميل',
        };
      }

      if (products.isEmpty) {
        return {
          'success': false,
          'message': 'يجب اختيار منتج واحد على الأقل',
        };
      }

      if (installmentAmount <= 0) {
        return {
          'success': false,
          'message': 'مبلغ القسط يجب أن يكون أكبر من صفر',
        };
      }

      // بناء البيانات للإرسال - تتوافق مع السيرفر
      final requestData = {
        'customer_id': customerId.toString(),
        'products': products.map((p) => {
          'product_id': p['product_id'].toString(),
          'quantity': (p['quantity'] as num).toInt(),
          'price': (p['price'] as num).toDouble(),
        }).toList(),
        'total_price': totalPrice.toDouble(),
        'down_payment': downPayment.toDouble(),
        'installment_amount': installmentAmount.toDouble(),
        'frequency': frequency,
        'start_date': startDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'currency': currency,
        'notes': notes ?? '',
      };

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📦 INSTALLMENT SERVICE - POST /api/installments');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('➡️  customer_id: $customerId');
      debugPrint('➡️  products: ${products.length}');
      debugPrint('➡️  total_price: $totalPrice');
      debugPrint('➡️  down_payment: $downPayment');
      debugPrint('➡️  installment_amount: $installmentAmount');
      debugPrint('➡️  frequency: $frequency');
      debugPrint('➡️  start_date: ${requestData['start_date']}');
      debugPrint('➡️  Request: ${jsonEncode(requestData)}');
      debugPrint('═══════════════════════════════════════════\n');

      // إرسال الطلب - المسار الصحيح /api/installments
      final response = await _apiClient.dio.post(
        '/installments',
        data: requestData,
      );

      debugPrint('═══════════════════════════════════════════');
      debugPrint('✅ INSTALLMENT SERVICE - Response');
      debugPrint('⬅️  Status: ${response.statusCode}');
      debugPrint('⬅️  Data: ${response.data}');
      debugPrint('═══════════════════════════════════════════\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // مزامنة البيانات من السيرفر
        try {
          final syncService = ThabitPullSyncService();
          await syncService.fetchLatestData(clearCache: true);
          debugPrint('✅ Sync completed after save');
        } catch (syncError) {
          debugPrint('⚠️ Sync error (non-fatal): $syncError');
        }

        return {
          'success': true,
          'data': response.data?['data'],
          'message': response.data?['message'] ?? 'تم إنشاء القسط بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['error'] ?? 'فشل إنشاء القسط',
        };
      }
    } on DioException catch (e) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('❌ INSTALLMENT SERVICE ERROR');
      debugPrint('⬅️  Status: ${e.response?.statusCode}');
      debugPrint('⬅️  URL: ${e.requestOptions.uri}');
      debugPrint('⬅️  Error: ${e.message}');
      debugPrint('⬅️  Response: ${e.response?.data}');
      debugPrint('═══════════════════════════════════════════\n');

      return {
        'success': false,
        'message': e.response?.data?['error'] ??
            'فشل الاتصال بالخادم: ${e.message}',
      };
    } catch (e) {
      debugPrint('❌ InstallmentService Exception: $e');
      return {
        'success': false,
        'message': 'حدث خطأ: $e',
      };
    }
  }

  /// حساب جدول الأقساط - GET /api/installments/calculate
  Future<Map<String, dynamic>> calculateSchedule({
    required double totalPrice,
    required double downPayment,
    required double installmentAmount,
    required String frequency,
    required String startDate,
    String currency = 'IQD',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/installments/calculate',
        data: {
          'total_price': totalPrice,
          'down_payment': downPayment,
          'installment_amount': installmentAmount,
          'frequency': frequency,
          'start_date': startDate,
          'currency': currency,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data?['data'],
        };
      }
      return {'success': false, 'message': 'فشل الحساب'};
    } catch (e) {
      debugPrint('❌ calculateSchedule error: $e');
      return {'success': false, 'message': 'فشل الحساب: $e'};
    }
  }

  /// جلب جميع الأقساط - GET /api/installments
  Future<List<Map<String, dynamic>>> getInstallments() async {
    try {
      final response = await _apiClient.dio.get('/installments');

      if (response.statusCode == 200) {
        final data = response.data?['data']?['installments'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ getInstallments error: $e');
      return [];
    }
  }

  /// جلب تفاصيل قسط محدد
  Future<Map<String, dynamic>?> getInstallmentDetail(String planId) async {
    try {
      final response = await _apiClient.dio.get('/installments/$planId');

      if (response.statusCode == 200) {
        return response.data?['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ getInstallmentDetail error: $e');
      return null;
    }
  }
}
