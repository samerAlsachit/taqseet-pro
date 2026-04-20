import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'api_client.dart';

/// CustomerService - خدمة إدارة العملاء
/// تستخدم ApiClient للتواصل مع API مع دعم رفع الصور إلى Supabase Storage
class CustomerService {
  final ApiClient _apiClient = ApiClient();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// رفع صورة إلى Supabase Storage
  /// [filePath]: مسار الملف المحلي
  /// [bucketName]: اسم الـ bucket (افتراضي: 'customers')
  /// [folder]: المجلد الفرعي (مثال: 'avatars' أو 'documents')
  /// تعيد: رابط URL العام للصورة أو null في حال الفشل
  Future<String?> uploadImage(
    String filePath, {
    String bucketName = 'customers',
    String? folder,
  }) async {
    try {
      debugPrint('📤 Starting upload without auth check (anon access enabled)');

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ uploadImage: File does not exist: $filePath');
        return null;
      }

      // Generate clean unique filename (timestamp only, no hash)
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String originalName = path.basename(filePath);
      final String extension = path.extension(originalName).toLowerCase();
      final String fileName = '$timestamp$extension';

      // Build storage path
      final String storagePath = folder != null
          ? '$folder/$fileName'
          : fileName;

      debugPrint('📤 Uploading image to Supabase: $bucketName/$storagePath');

      // Convert file to bytes
      debugPrint('📤 Reading file as bytes...');
      final bytes = await file.readAsBytes();
      debugPrint('📤 File size: ${bytes.length} bytes');

      // Upload to Supabase Storage using uploadBinary
      debugPrint(
        '📤 Starting uploadBinary to bucket: $bucketName, path: $storagePath',
      );

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(storagePath);

      debugPrint('✅ Image uploaded successfully: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('❌ Supabase Storage Error:');
      debugPrint('   Message: ${e.message}');
      debugPrint('   StatusCode: ${e.statusCode}');
      debugPrint('   Error: ${e.error}');
      print('Detailed Storage Error: $e');
      print('Status Code: ${e.statusCode}');
      print('Error Message: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ uploadImage Error: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      print('Detailed Storage Error: $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }

  /// رفع عدة صور دفعة واحدة
  /// [filePaths]: قائمة مسارات الملفات المحلية
  /// تعيد: قائمة بروابط URLs الناجحة فقط
  Future<List<String>> uploadImages(
    List<String> filePaths, {
    String bucketName = 'customers',
    String? folder,
  }) async {
    final List<String> urls = [];

    for (final filePath in filePaths) {
      final url = await uploadImage(
        filePath,
        bucketName: bucketName,
        folder: folder,
      );
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// إنشاء عميل جديد - مع دعم روابط الصور المرفوعة مسبقاً
  Future<Map<String, dynamic>> createCustomer({
    required String fullName,
    required String phone,
    String? nationalId,
    String? address,
    String? customerImagePath,
    String? docFrontPath,
    String? docBackPath,
    String? residenceCardPath,
    String? avatarUrl, // ← رابط صورة مرفوع مسبقاً
    List<String>? documentsUrls, // ← روابط مستمسكات مرفوعة مسبقاً
  }) async {
    try {
      // إذا تم تمرير روابط مسبقاً، استخدمها مباشرة
      // وإلا ارفع الصور الآن (للتوافق مع الاستدعاءات القديمة)
      String? finalAvatarUrl = avatarUrl;
      List<String> finalDocumentsUrls = documentsUrls ?? [];

      // رفع الصور فقط إذا لم يتم تمرير روابط مسبقاً
      if (finalAvatarUrl == null &&
          customerImagePath != null &&
          customerImagePath.isNotEmpty) {
        finalAvatarUrl = await uploadImage(
          customerImagePath,
          folder: 'avatars',
        );
      }

      if (finalDocumentsUrls.isEmpty) {
        final List<String> docPaths = [
          if (docFrontPath != null && docFrontPath.isNotEmpty) docFrontPath,
          if (docBackPath != null && docBackPath.isNotEmpty) docBackPath,
          if (residenceCardPath != null && residenceCardPath.isNotEmpty)
            residenceCardPath,
        ];

        if (docPaths.isNotEmpty) {
          finalDocumentsUrls = await uploadImages(
            docPaths,
            folder: 'documents',
          );
        }
      }

      // بناء البيانات مع روابط URLs
      final requestData = {
        'full_name': fullName,
        'phone': phone,
        if (nationalId != null && nationalId.isNotEmpty)
          'national_id': nationalId,
        if (address != null && address.isNotEmpty) 'address': address,
        // إرسال المسارات المحلية للأرشيف
        if (customerImagePath != null) 'customer_image_path': customerImagePath,
        if (docFrontPath != null) 'doc_front_path': docFrontPath,
        if (docBackPath != null) 'doc_back_path': docBackPath,
        if (residenceCardPath != null) 'residence_card_path': residenceCardPath,
        // إرسال روابط Supabase URLs للسيرفر
        if (finalAvatarUrl != null) 'avatar_url': finalAvatarUrl,
        if (finalDocumentsUrls.isNotEmpty) 'documents_urls': finalDocumentsUrls,
      };

      debugPrint(
        '📤 Creating customer with images: avatar=$finalAvatarUrl, docs=${finalDocumentsUrls.length}',
      );

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
        'message':
            e.response?.data?['error'] ?? 'فشل الاتصال بالخادم: ${e.message}',
      };
    } catch (e) {
      debugPrint('❌ CustomerService Exception: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  /// تحديث بيانات العميل - مع رفع الصور أولاً إذا تغيرت
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
    String? existingAvatarUrl,
    List<String>? existingDocumentsUrls,
  }) async {
    try {
      // 1. رفع الصور الجديدة إلى Supabase Storage أولاً
      String? avatarUrl = existingAvatarUrl;
      List<String> documentsUrls = existingDocumentsUrls ?? [];

      // رفع صورة العميل الشخصية إذا تم تغييرها (مسار جديد)
      if (customerImagePath != null &&
          customerImagePath.isNotEmpty &&
          !customerImagePath.startsWith('http')) {
        avatarUrl = await uploadImage(customerImagePath, folder: 'avatars');
      }

      // رفع المستمسكات الجديدة (المسارات التي لا تبدأ بـ http)
      final List<String> newDocPaths = [
        if (docFrontPath != null &&
            docFrontPath.isNotEmpty &&
            !docFrontPath.startsWith('http'))
          docFrontPath,
        if (docBackPath != null &&
            docBackPath.isNotEmpty &&
            !docBackPath.startsWith('http'))
          docBackPath,
        if (residenceCardPath != null &&
            residenceCardPath.isNotEmpty &&
            !residenceCardPath.startsWith('http'))
          residenceCardPath,
      ];

      if (newDocPaths.isNotEmpty) {
        final newUrls = await uploadImages(newDocPaths, folder: 'documents');
        documentsUrls.addAll(newUrls);
      }

      // 2. بناء البيانات مع روابط URLs
      final requestData = {
        'full_name': fullName,
        'phone': phone,
        if (nationalId != null) 'national_id': nationalId,
        if (address != null) 'address': address,
        // إرسال المسارات المحلية للأرشيف
        if (customerImagePath != null) 'customer_image_path': customerImagePath,
        if (docFrontPath != null) 'doc_front_path': docFrontPath,
        if (docBackPath != null) 'doc_back_path': docBackPath,
        if (residenceCardPath != null) 'residence_card_path': residenceCardPath,
        // إرسال روابط Supabase URLs للسيرفر
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (documentsUrls.isNotEmpty) 'documents_urls': documentsUrls,
      };

      debugPrint(
        '📤 Updating customer $customerId with images: avatar=$avatarUrl, docs=${documentsUrls.length}',
      );

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
      return {'success': false, 'message': 'حدث خطأ: $e'};
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

  /// حذف صورة من Supabase Storage
  /// [imageUrl]: رابط الصورة الكامل
  /// تعيد: true إذا تم الحذف بنجاح
  Future<bool> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return true;

    try {
      // استخراج مسار الملف من الرابط
      // الرابط يكون: https://.../storage/v1/object/public/customers/avatars/filename.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // البحث عن bucket name في المسار
      final bucketIndex = pathSegments.indexOf('customers');
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        debugPrint('⚠️ Could not extract storage path from URL: $imageUrl');
        return false;
      }

      // بناء مسار الملف داخل البكت (بدون اسم البكت)
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _supabase.storage.from('customers').remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      return false;
    }
  }

  /// حذف عدة صور من Supabase Storage
  /// [imageUrls]: قائمة روابط الصور
  /// تعيد: عدد الصور التي تم حذفها بنجاح
  Future<int> deleteImages(List<String> imageUrls) async {
    int deletedCount = 0;

    for (final url in imageUrls) {
      final success = await deleteImage(url);
      if (success) {
        deletedCount++;
      }
    }

    return deletedCount;
  }

  /// حذف عميل مع صوره من Storage
  Future<Map<String, dynamic>> deleteCustomerWithImages(
    String customerId, {
    String? avatarUrl,
    List<String>? documentsUrls,
  }) async {
    try {
      // 1. حذف الصور من Storage أولاً
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await deleteImage(avatarUrl);
      }

      if (documentsUrls != null && documentsUrls.isNotEmpty) {
        await deleteImages(documentsUrls);
      }

      // 2. حذف العميل من API
      return await deleteCustomer(customerId);
    } catch (e) {
      debugPrint('❌ Error in deleteCustomerWithImages: $e');
      // محاولة حذف العميل حتى لو فشل حذف الصور
      return await deleteCustomer(customerId);
    }
  }

  /// حذف عميل (الطريقة الأساسية)
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
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }
}
