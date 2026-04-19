import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';

/// CustomerService - خدمة إدارة العملاء
/// تستخدم ApiClient للتواصل مع API بدلاً من Supabase
class CustomerService {
  final ApiClient _apiClient = ApiClient();

  /// إنشاء عميل جديد - لا ترسل ID، السيرفر يولده
  Future<Map<String, dynamic>> createCustomer({
    required String fullName,
    required String phone,
    String? nationalId,
    String? address,
    String? customerImagePath,
    String? docFrontPath,
    String? docBackPath,
    String? residenceCardPath,
  }) async {
    try {
      // بناء البيانات بدون ID - السيرفر يولد UUID
      final requestData = {
        'full_name': fullName,
        'phone': phone,
        if (nationalId != null && nationalId.isNotEmpty) 'national_id': nationalId,
        if (address != null && address.isNotEmpty) 'address': address,
        if (customerImagePath != null) 'customer_image_path': customerImagePath,
        if (docFrontPath != null) 'doc_front_path': docFrontPath,
        if (docBackPath != null) 'doc_back_path': docBackPath,
        if (residenceCardPath != null) 'residence_card_path': residenceCardPath,
      };

      debugPrint('📤 Creating customer via API: ${requestData['full_name']}');

      final response = await _apiClient.dio.post(
        '/customers',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data?['data'],
          'message': response.data?['message'] ?? 'تم إنشاء العميل بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['error'] ?? 'فشل إنشاء العميل',
        };
      }
    } on DioException catch (e) {
      debugPrint('❌ CustomerService Error: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data?['error'] ?? 'فشل الاتصال بالخادم: ${e.message}',
      };
    } catch (e) {
      debugPrint('❌ CustomerService Exception: $e');
      return {
        'success': false,
        'message': 'حدث خطأ: $e',
      };
    }
  }

  /// تحديث بيانات العميل
  Future<Map<String, dynamic>> updateCustomer({
    required String customerId,
    required String fullName,
    required String phone,
    String? nationalId,
    String? address,
    String? customerImagePath,
    String? docFrontPath,
    String? docBackPath,
    String? residenceCardPath,
  }) async {
    try {
      final requestData = {
        'full_name': fullName,
        'phone': phone,
        if (nationalId != null) 'national_id': nationalId,
        if (address != null) 'address': address,
        if (customerImagePath != null) 'customer_image_path': customerImagePath,
        if (docFrontPath != null) 'doc_front_path': docFrontPath,
        if (docBackPath != null) 'doc_back_path': docBackPath,
        if (residenceCardPath != null) 'residence_card_path': residenceCardPath,
      };

      final response = await _apiClient.dio.put(
        '/customers/$customerId',
        data: requestData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data?['data'],
          'message': response.data?['message'] ?? 'تم تحديث العميل بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['error'] ?? 'فشل تحديث العميل',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['error'] ?? 'فشل الاتصال بالخادم',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ: $e',
      };
    }
  }

  /// جلب قائمة العملاء
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final response = await _apiClient.dio.get('/customers');

      if (response.statusCode == 200) {
        final data = response.data?['data']?['customers'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ getCustomers error: $e');
      return [];
    }
  }

  /// جلب تفاصيل عميل
  Future<Map<String, dynamic>?> getCustomerDetail(String customerId) async {
    try {
      final response = await _apiClient.dio.get('/customers/$customerId');

      if (response.statusCode == 200) {
        return response.data?['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ getCustomerDetail error: $e');
      return null;
    }
  }

  /// حذف عميل
  Future<Map<String, dynamic>> deleteCustomer(String customerId) async {
    try {
      final response = await _apiClient.dio.delete('/customers/$customerId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data?['message'] ?? 'تم حذف العميل بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['error'] ?? 'فشل حذف العميل',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['error'] ?? 'فشل الاتصال بالخادم',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ: $e',
      };
    }
  }
}
