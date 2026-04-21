import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
  /// [customFileName]: اسم ملف مخصص (اختياري - يستخدم ID العميل مثلاً)
  /// تعيد: رابط URL العام للصورة أو null في حال الفشل
  Future<String?> uploadImage(
    String filePath, {
    String bucketName = 'customers',
    String? folder,
    String? customFileName,
  }) async {
    try {
      debugPrint('📤 Starting upload without auth check (anon access enabled)');

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ uploadImage: File does not exist: $filePath');
        return null;
      }

      // ✅ استخدام اسم ملف مخصص إذا تم تمريره (مثل ID العميل)
      final String originalName = path.basename(filePath);
      final String extension = path.extension(originalName).toLowerCase();
      final String fileName = customFileName != null
          ? '$customFileName$extension'
          : '${DateTime.now().millisecondsSinceEpoch}$extension';

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

      // ✅ إرجاع المسار النسبي (folder/filename.jpg) بدلاً من الرابط الكامل
      // ليتم تخزينه في قاعدة البيانات بشكل نظيف
      debugPrint('✅ Image uploaded successfully: $storagePath');
      return storagePath;
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
    print('📤 Uploading ${filePaths.length} images to $bucketName/$folder');

    for (final filePath in filePaths) {
      final url = await uploadImage(
        filePath,
        bucketName: bucketName,
        folder: folder,
      );
      if (url != null) {
        urls.add(url);
        print('   ✅ Uploaded: $url');
      } else {
        print('   ❌ Failed: $filePath');
      }
    }

    print('📤 Total uploaded: ${urls.length}/${filePaths.length}');
    return urls;
  }

  /// إنشاء عميل جديد - مع دعم روابط الصور المرفوعة مسبقاً
  /// [customerId]: معرف العميل (مولد مسبقاً في الموبايل)
  Future<Map<String, dynamic>> createCustomer({
    String? customerId, // ← معرف العميل المولد مسبقاً (اختياري)
    required String fullName,
    required String phone,
    String? nationalId,
    String? address,
    String? customerImagePath,
    String? docFrontPath,
    String? docBackPath,
    String? residenceCardPath,
    String? idDocUrl, // ← رابط صورة الهوية/العميل (id_doc_url)
    List<String>? documentsUrls, // ← روابط مستمسكات مرفوعة مسبقاً
  }) async {
    try {
      // ✅ استخدام ID ممرر أو توليد جديد
      final String finalCustomerId = customerId ?? const Uuid().v4();
      debugPrint('🆕 Using customer ID: $finalCustomerId');

      // إذا تم تمرير روابط مسبقاً، استخدمها مباشرة
      // وإلا ارفع الصور الآن (للتوافق مع الاستدعاءات القديمة)
      String? finalIdDocUrl = idDocUrl;
      List<String> finalDocumentsUrls = documentsUrls ?? [];

      // ✅ رفع الصورة باستخدام customerId كاسم ملف (توحيد الاسم)
      if (finalIdDocUrl == null &&
          customerImagePath != null &&
          customerImagePath.isNotEmpty) {
        finalIdDocUrl = await uploadImage(
          customerImagePath,
          folder: 'avatars',
          customFileName: finalCustomerId, // ✅ استخدام ID كاسم ملف
        );
        debugPrint(
          '📤 Uploaded image with customerId filename: $finalIdDocUrl',
        );
      }

      // ✅ إذا تم الرفع بنجاح، نستخدم نفس المسار في id_doc_url
      if (finalIdDocUrl != null && !finalIdDocUrl.contains('/')) {
        finalIdDocUrl = 'avatars/$finalIdDocUrl';
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
        'id': finalCustomerId, // ✅ إرسال ID العميل للسيرفر
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
        if (finalIdDocUrl != null) 'id_doc_url': finalIdDocUrl,
        if (finalDocumentsUrls.isNotEmpty) 'documents_urls': finalDocumentsUrls,
      };

      // ✅ التحقق من البيانات المرسلة
      final docsUrls = requestData['documents_urls'] as List<String>?;
      print('📤 [Mobile→Server] Request Data:');
      print('   ID: ${requestData['id']}');
      print('   id_doc_url: ${requestData['id_doc_url']}');
      print('   documents_urls: $docsUrls');
      print('   documents_urls count: ${docsUrls?.length ?? 0}');
      print('   full_name: ${requestData['full_name']}');

      // ✅ التحقق من إرسال روابط كاملة (تبدأ بـ https://)
      if (finalIdDocUrl != null) {
        debugPrint('📤 ID Doc URL: $finalIdDocUrl');
        if (!finalIdDocUrl.startsWith('http')) {
          debugPrint('⚠️ Warning: ID Doc URL does not start with http');
        }
      }
      if (finalDocumentsUrls.isNotEmpty) {
        debugPrint('📤 Documents URLs: ${finalDocumentsUrls.length} images');
        for (final url in finalDocumentsUrls) {
          debugPrint('   - $url');
        }
      }

      // ✅ Log before sending to server
      print('🔥 Sending to Server: id = $finalCustomerId');
      print('🔥 Sending to Server: id_doc_url = $finalIdDocUrl');

      debugPrint(
        '📤 Creating customer with images: id_doc=$finalIdDocUrl, docs=${finalDocumentsUrls.length}',
      );

      debugPrint('📤 Creating customer via API: ${requestData['full_name']}');

      final response = await _apiClient.dio.post(
        '/customers',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data?['data'];
        print('📥 [Server→Mobile] Response Data:');
        print('   ID: ${responseData?['id']}');
        print('   id_doc_url: ${responseData?['id_doc_url']}');
        print('   extra_docs: ${responseData?['extra_docs']}');
        print(
          '   extra_docs count: ${(responseData?['extra_docs'] as List?)?.length ?? 0}',
        );

        // ✅ التحقق من تطابق الـ ID
        if (responseData?['id'] != finalCustomerId) {
          print('⚠️ WARNING: Server returned different ID!');
          print('   Sent: $finalCustomerId');
          print('   Received: ${responseData?['id']}');
        }

        return {
          'success': true,
          'data': responseData,
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
    String? existingIdDocUrl,
    List<String>? existingDocumentsUrls,
  }) async {
    try {
      // 1. رفع الصور الجديدة إلى Supabase Storage أولاً
      String? idDocUrl = existingIdDocUrl;
      List<String> documentsUrls = existingDocumentsUrls ?? [];

      // ✅ رفع صورة العميل باستخدام customerId كاسم ملف (توحيد الاسم)
      if (customerImagePath != null &&
          customerImagePath.isNotEmpty &&
          !customerImagePath.startsWith('http')) {
        idDocUrl = await uploadImage(
          customerImagePath,
          folder: 'avatars',
          customFileName: customerId, // ✅ استخدام ID كاسم ملف
        );
        debugPrint(
          '📤 Update: Uploaded image with customerId filename: $idDocUrl',
        );
      }

      // ✅ تأكد من أن id_doc_url يحتوي على المسار الكامل
      if (idDocUrl != null && !idDocUrl.contains('/')) {
        idDocUrl = 'avatars/$idDocUrl';
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
        if (idDocUrl != null) 'id_doc_url': idDocUrl,
        if (documentsUrls.isNotEmpty) 'documents_urls': documentsUrls,
      };

      print('🔥 Update - Sending to Server: id_doc_url = $idDocUrl');

      debugPrint(
        '📤 Updating customer $customerId with images: id_doc=$idDocUrl, docs=${documentsUrls.length}',
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
    String? idDocUrl,
    List<String>? documentsUrls,
  }) async {
    try {
      // 1. حذف الصور من Storage أولاً
      if (idDocUrl != null && idDocUrl.isNotEmpty) {
        await deleteImage(idDocUrl);
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
