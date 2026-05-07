import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/customer_model.dart';
import '../../services/api/api_service.dart';

class CustomerProvider extends ChangeNotifier {
  final _apiService = ApiService();

  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<CustomerModel> get customers =>
      _searchQuery.isEmpty ? _customers : _filteredCustomers;
  List<CustomerModel> get allCustomers => _customers;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getCustomers();
      debugPrint('📥 Customers API result: success=${result.success}');
      debugPrint('📦 Response data type: ${result.data?.runtimeType}');
      debugPrint('📦 Response data: ${result.data}');

      if (result.success) {
        // Handle API response: {success: true, data: {customers: [...]}}
        final responseData = result.data;
        List<dynamic> customersList = [];

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final data = responseData['data'];

          // Check if data contains 'customers' key
          if (data is Map<String, dynamic> && data.containsKey('customers')) {
            final customers = data['customers'];
            if (customers is List) {
              customersList = customers;
            }
          } else if (data is List) {
            // Direct list in data
            customersList = data;
          } else if (data is Map) {
            // Single customer object
            customersList = [data];
          }
        } else if (responseData is List) {
          customersList = responseData;
        } else if (responseData is Map) {
          customersList = [responseData];
        }

        debugPrint('📋 Parsed customers count: ${customersList.length}');

        _customers = customersList
            .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _applySearch();
        debugPrint('✅ Loaded ${_customers.length} customers');
      } else {
        _error = result.message;
        debugPrint('❌ API error: ${result.message}');
      }
    } catch (e, stackTrace) {
      _error = 'فشل في تحميل العملاء: $e';
      debugPrint('❌ Load customers error: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createCustomer(customer.toJson());
      if (result.success) {
        final newCustomer = CustomerModel.fromJson(result.data);
        _customers.insert(0, newCustomer);
        _applySearch();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'فشل في إضافة العميل: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result =
          await _apiService.updateCustomer(customer.id, customer.toJson());
      if (result.success) {
        final index = _customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _customers[index] = customer;
          _applySearch();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'فشل في تحديث العميل: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete customer images from storage first
      await _deleteCustomerImages(id);

      final result = await _apiService.deleteCustomer(id);
      if (result.success) {
        _customers.removeWhere((c) => c.id == id);
        _filteredCustomers.removeWhere((c) => c.id == id);
        if (_selectedCustomer?.id == id) {
          _selectedCustomer = null;
        }
        _applySearch();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'فشل في حذف العميل: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = _customers;
    } else {
      _filteredCustomers = _customers.where((c) {
        final fullName = c.fullName.toLowerCase();
        final phone = c.phone?.toLowerCase() ?? '';
        final idNumber = c.idNumber?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return fullName.contains(query) ||
            phone.contains(query) ||
            idNumber.contains(query);
      }).toList();
    }
  }

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredCustomers = _customers;
    notifyListeners();
  }

  /// Compress and upload file to Supabase Storage
  /// Unified naming pattern: ${customerId}_profile.jpg
  Future<String?> _uploadFile(
    File file,
    String bucket,
    String path, {
    int quality = 70,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Ensure path has .jpg extension
      String finalPath = path;
      if (!finalPath.toLowerCase().endsWith('.jpg') &&
          !finalPath.toLowerCase().endsWith('.jpeg')) {
        finalPath = '$finalPath.jpg';
        debugPrint('📝 Added .jpg extension: $finalPath');
      }

      // Sanitize path: remove spaces and special characters
      finalPath = finalPath.replaceAll(RegExp(r'[^a-zA-Z0-9_/.-]'), '_');
      debugPrint('🧹 Sanitized path: $finalPath');

      debugPrint('📤 Starting upload to bucket: $bucket, path: $finalPath');

      // Compress image before upload
      List<int> compressedBytes;
      try {
        final result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: maxWidth,
          minHeight: maxHeight,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        compressedBytes = result ?? await file.readAsBytes();
        debugPrint(
            '🗜️ Compressed image from ${(await file.length() / 1024).toStringAsFixed(1)}KB to ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB');
      } catch (e) {
        debugPrint('⚠️ Compression failed, using original: $e');
        compressedBytes = await file.readAsBytes();
      }

      // Upload compressed image
      await supabase.storage.from(bucket).uploadBinary(
            finalPath,
            Uint8List.fromList(compressedBytes),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = supabase.storage.from(bucket).getPublicUrl(finalPath);
      debugPrint('✅ Uploaded successfully: $url');
      debugPrint('🔗 Storage Path: $finalPath');
      return url;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      debugPrint('   Bucket: $bucket, Path: $path');
      return null;
    }
  }

  /// Delete file from Supabase Storage
  Future<void> _deleteFile(String bucket, String path) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.storage.from(bucket).remove([path]);
      debugPrint('🗑️ Deleted: $path');
    } catch (e) {
      debugPrint('⚠️ Error deleting file (may not exist): $e');
    }
  }

  /// Delete all customer images
  Future<void> _deleteCustomerImages(String customerId) async {
    try {
      final supabase = Supabase.instance.client;
      final bucket = supabase.storage.from('customers');

      debugPrint('🗑️ Starting deletion of images for customer: $customerId');

      // Sanitize ID for path
      final sanitizedId = customerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      // Delete avatar - try new naming pattern first, then old pattern
      final newAvatarPath = 'avatars/${sanitizedId}_profile.jpg';
      final oldAvatarPath = 'avatars/$customerId.jpg';

      try {
        await bucket.remove([newAvatarPath]);
        debugPrint('✅ Deleted avatar (new pattern): $newAvatarPath');
      } catch (e) {
        debugPrint('⚠️ Failed to delete avatar (new pattern): $e');
      }

      // Also try old pattern for backward compatibility
      try {
        await bucket.remove([oldAvatarPath]);
        debugPrint('✅ Deleted avatar (old pattern): $oldAvatarPath');
      } catch (e) {
        debugPrint('⚠️ No old avatar found: $e');
      }

      // Delete documents
      final documentPaths = [
        'documents/${customerId}_id_front.jpg',
        'documents/${customerId}_id_back.jpg',
        'documents/${customerId}_residence_front.jpg',
        'documents/${customerId}_residence_back.jpg',
      ];

      for (final path in documentPaths) {
        try {
          await bucket.remove([path]);
          debugPrint('✅ Deleted document: $path');
        } catch (e) {
          debugPrint('⚠️ Failed to delete document $path: $e');
        }
      }

      debugPrint('🗑️ Completed image deletion for customer: $customerId');
    } catch (e) {
      debugPrint('❌ Error deleting customer images: $e');
    }
  }

  Future<bool> createCustomerWithFiles(
    Map<String, dynamic> data, {
    File? avatarFile,
    File? idCardFrontFile,
    File? idCardBackFile,
    File? residenceFrontFile,
    File? residenceBackFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Create customer in API first (without images)
      final result = await _apiService.createCustomer(data);

      if (!result.success || result.data == null) {
        _error = result.message ?? 'فشل في إضافة العميل';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get the real customer ID from API response
      // API may return nested data: { "data": { "id": "..." } }
      final responseData = result.data is Map && result.data['data'] != null
          ? result.data['data']
          : result.data;

      final newCustomer = CustomerModel.fromJson(responseData);
      final customerId = newCustomer.id;

      debugPrint('✅ Customer created with ID: $customerId');
      debugPrint('📦 API Response: ${result.data}');
      debugPrint('📦 Parsed data: $responseData');

      // Guard: Don't upload if customerId is empty
      if (customerId.isEmpty) {
        debugPrint('❌ Customer ID is empty! Cannot upload images.');
        _customers.insert(0, newCustomer);
        _applySearch();
        _isLoading = false;
        notifyListeners();
        return true; // Customer created but without images
      }

      // Step 2: Upload images using the real customer ID
      final List<String> documentsUrls = [];

      // Upload avatar - use unified naming: ${customerId}_profile.jpg
      if (avatarFile != null) {
        final sanitizedId =
            customerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final avatarPath = 'avatars/${sanitizedId}_profile.jpg';

        debugPrint('📸 Uploading avatar for customer $customerId');
        debugPrint('   Sanitized ID: $sanitizedId');
        debugPrint('   Storage path: $avatarPath');

        final url = await _uploadFile(
          avatarFile,
          'customers',
          avatarPath,
        );
        if (url != null) {
          data['avatar_url'] = url;
          debugPrint('✅ Avatar uploaded successfully');
          debugPrint('🔗 URL: $url');
        }
      }

      // Upload ID card front
      if (idCardFrontFile != null) {
        final url = await _uploadFile(
          idCardFrontFile,
          'customers',
          'documents/${customerId}_id_front.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Upload ID card back
      if (idCardBackFile != null) {
        final url = await _uploadFile(
          idCardBackFile,
          'customers',
          'documents/${customerId}_id_back.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Upload residence front
      if (residenceFrontFile != null) {
        final url = await _uploadFile(
          residenceFrontFile,
          'customers',
          'documents/${customerId}_residence_front.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Upload residence back
      if (residenceBackFile != null) {
        final url = await _uploadFile(
          residenceBackFile,
          'customers',
          'documents/${customerId}_residence_back.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Step 3: Update customer with image URLs if any were uploaded
      if (documentsUrls.isNotEmpty || data['avatar_url'] != null) {
        final updateData = <String, dynamic>{};
        if (data['avatar_url'] != null) {
          updateData['avatar_url'] = data['avatar_url'];
        }
        if (documentsUrls.isNotEmpty) {
          updateData['documents_urls'] = documentsUrls;
        }

        final updateResult =
            await _apiService.updateCustomer(customerId, updateData);
        if (updateResult.success) {
          final updatedCustomer = CustomerModel.fromJson(updateResult.data);
          _customers.insert(0, updatedCustomer);
          debugPrint(
              '✅ Customer updated with images: ${updatedCustomer.fullName}');
        } else {
          // If update fails, still use the customer without images
          _customers.insert(0, newCustomer);
          debugPrint('⚠️ Customer created but image update failed');
        }
      } else {
        _customers.insert(0, newCustomer);
        debugPrint(
            '✅ Customer created without images: ${newCustomer.fullName}');
      }

      _applySearch();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في إضافة العميل: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomerWithFiles(
    String id,
    Map<String, dynamic> data, {
    File? avatarFile,
    File? idCardFrontFile,
    File? idCardBackFile,
    File? residenceFrontFile,
    File? residenceBackFile,
    CustomerModel? oldCustomer,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<String> documentsUrls = [];

      // Upload avatar (delete old first if exists)
      // Unified naming: ${id}_profile.jpg
      if (avatarFile != null) {
        final sanitizedId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final avatarPath = 'avatars/${sanitizedId}_profile.jpg';

        // Delete old avatar if exists
        if (oldCustomer?.avatarUrl != null) {
          await _deleteFile('customers', avatarPath);
        }

        debugPrint('📸 Updating avatar for customer $id');
        debugPrint('   Sanitized ID: $sanitizedId');
        debugPrint('   Storage path: $avatarPath');

        final url = await _uploadFile(
          avatarFile,
          'customers',
          avatarPath,
        );
        if (url != null) {
          data['avatar_url'] = url;
          debugPrint('✅ Avatar updated successfully');
          debugPrint('🔗 URL: $url');
        }
      }

      // Upload ID card front (delete old first)
      if (idCardFrontFile != null) {
        await _deleteFile('customers', 'documents/${id}_id_front.jpg');
        final url = await _uploadFile(
          idCardFrontFile,
          'customers',
          'documents/${id}_id_front.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Upload ID card back (delete old first)
      if (idCardBackFile != null) {
        await _deleteFile('customers', 'documents/${id}_id_back.jpg');
        final url = await _uploadFile(
          idCardBackFile,
          'customers',
          'documents/${id}_id_back.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Upload residence front (delete old first)
      if (residenceFrontFile != null) {
        await _deleteFile('customers', 'documents/${id}_residence_front.jpg');
        final url = await _uploadFile(
          residenceFrontFile,
          'customers',
          'documents/${id}_residence_front.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Upload residence back (delete old first)
      if (residenceBackFile != null) {
        await _deleteFile('customers', 'documents/${id}_residence_back.jpg');
        final url = await _uploadFile(
          residenceBackFile,
          'customers',
          'documents/${id}_residence_back.jpg',
        );
        if (url != null) documentsUrls.add(url);
      }

      // Add documents URLs
      if (documentsUrls.isNotEmpty) {
        data['documents_urls'] = documentsUrls;
      }

      // Send to API
      final result = await _apiService.updateCustomer(id, data);

      if (result.success) {
        final updatedCustomer = CustomerModel.fromJson(result.data);

        // Update in main list
        final index = _customers.indexWhere((c) => c.id == id);
        if (index != -1) {
          _customers[index] = updatedCustomer;
        }

        // Update filtered list if needed
        final filteredIndex = _filteredCustomers.indexWhere((c) => c.id == id);
        if (filteredIndex != -1) {
          _filteredCustomers[filteredIndex] = updatedCustomer;
        }

        // Update selected customer if it's the same one
        if (_selectedCustomer?.id == id) {
          _selectedCustomer = updatedCustomer;
        }

        _applySearch();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'فشل في تحديث العميل: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Customer Details with Installments
  Map<String, dynamic>? _customerDetails;
  List<dynamic> _installmentPlans = [];
  Map<String, dynamic>? _installmentSummary;

  Map<String, dynamic>? get customerDetails => _customerDetails;
  List<dynamic> get installmentPlans => _installmentPlans;
  Map<String, dynamic>? get installmentSummary => _installmentSummary;

  Future<bool> fetchCustomerDetails(String customerId) async {
    _isLoading = true;
    _error = null;
    _installmentPlans = [];
    _installmentSummary = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching customer details for ID: $customerId');

      // Step 1: جلب بيانات العميل (مثل الويب)
      final customerResult = await _apiService.getCustomerById(customerId);
      debugPrint('� Customer API - Success: ${customerResult.success}');

      if (!customerResult.success || customerResult.data == null) {
        _error = customerResult.message ?? 'العميل غير موجود';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Parse customer data - matching web app structure
      final responseData = customerResult.data as Map<String, dynamic>?;
      final data = responseData?['data'] as Map<String, dynamic>?;

      if (data != null && data.containsKey('customer')) {
        _customerDetails = data['customer'] as Map<String, dynamic>?;
        debugPrint('✅ Customer loaded: ${_customerDetails?['full_name']}');
      }

      // Step 2: جلب الأقساط بشكل منفصل من endpoint الأقساط (مثل الويب تماماً)
      try {
        debugPrint('🔄 Fetching installments from /installments endpoint...');

        // محاولة 1: جلب بفلتر customer_id
        final installmentsResult = await _apiService.get(
          '/installments',
          params: {
            'customer_id': customerId,
            'limit': 100,
          },
        );

        debugPrint(
            '� Installments API - Success: ${installmentsResult.success}');

        if (installmentsResult.success && installmentsResult.data != null) {
          final instData = installmentsResult.data as Map<String, dynamic>?;
          final installments =
              instData?['data']?['installments'] as List<dynamic>?;

          if (installments != null && installments.isNotEmpty) {
            _installmentPlans = installments;
            debugPrint(
                '✅ Installments loaded from /installments: ${_installmentPlans.length} plans');
          } else {
            // محاولة 2: جلب جميع الأقساط وفلترة client-side (مثل الويب)
            debugPrint(
                '⚠️ No installments with filter, trying client-side filtering...');

            final allInstallmentsResult = await _apiService.get(
              '/installments',
              params: {'limit': 1000},
            );

            if (allInstallmentsResult.success &&
                allInstallmentsResult.data != null) {
              final allData =
                  allInstallmentsResult.data as Map<String, dynamic>?;
              final allInstallments =
                  allData?['data']?['installments'] as List<dynamic>? ?? [];

              // فلترة حسب customer_id (مثل الويب)
              _installmentPlans = allInstallments.where((inst) {
                final instCustomerId = inst['customer_id']?.toString() ??
                    inst['customerId']?.toString();
                return instCustomerId == customerId;
              }).toList();

              debugPrint(
                  '✅ Found ${_installmentPlans.length} installments by client-side filtering');
            }
          }
        }

        // إذا لم نجد أقساط، نستخدم fallback من API العميل
        if (_installmentPlans.isEmpty && data != null) {
          final fallbackPlans =
              data['installment_plans'] as List<dynamic>? ?? [];
          if (fallbackPlans.isNotEmpty) {
            _installmentPlans = fallbackPlans;
            debugPrint(
                '✅ Using fallback installments from customer API: ${_installmentPlans.length}');
          }
        }

        // Parse summary
        if (data != null && data.containsKey('summary')) {
          _installmentSummary = data['summary'] as Map<String, dynamic>?;
          debugPrint('✅ Summary loaded: $_installmentSummary');
        }
      } catch (instError) {
        debugPrint('❌ Error fetching installments: $instError');
        // Fallback: استخدام الأقساط من API العميل
        if (data != null) {
          final fallbackPlans =
              data['installment_plans'] as List<dynamic>? ?? [];
          _installmentPlans = fallbackPlans;
          debugPrint(
              '✅ Fallback: ${_installmentPlans.length} plans from customer API');
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      _error = 'فشل في جلب تفاصيل العميل: $e';
      debugPrint('❌ Error fetching customer details: $e');
      debugPrint('📍 Stack trace: $stack');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearCustomerDetails() {
    _customerDetails = null;
    _installmentPlans = [];
    _installmentSummary = null;
    notifyListeners();
  }
}
