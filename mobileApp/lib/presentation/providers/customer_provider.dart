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
            path,
            Uint8List.fromList(compressedBytes),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = supabase.storage.from(bucket).getPublicUrl(path);
      debugPrint('✅ Uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
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

      // Delete avatar
      try {
        await bucket.remove(['avatars/$customerId.jpg']);
        debugPrint('✅ Deleted avatar: avatars/$customerId.jpg');
      } catch (e) {
        debugPrint('⚠️ Failed to delete avatar: $e');
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
      final newCustomer = CustomerModel.fromJson(result.data);
      final customerId = newCustomer.id;

      debugPrint('✅ Customer created with ID: $customerId');

      // Step 2: Upload images using the real customer ID
      final List<String> documentsUrls = [];

      // Upload avatar
      if (avatarFile != null) {
        final url = await _uploadFile(
          avatarFile,
          'customers',
          'avatars/$customerId.jpg',
        );
        if (url != null) {
          data['id_doc_url'] = url;
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
      if (documentsUrls.isNotEmpty || data['id_doc_url'] != null) {
        final updateData = <String, dynamic>{};
        if (data['id_doc_url'] != null) {
          updateData['id_doc_url'] = data['id_doc_url'];
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
      if (avatarFile != null) {
        // Delete old avatar if exists
        if (oldCustomer?.avatarUrl != null) {
          await _deleteFile('customers', 'avatars/$id.jpg');
        }
        final url = await _uploadFile(
          avatarFile,
          'customers',
          'avatars/$id.jpg',
        );
        if (url != null) {
          data['id_doc_url'] = url;
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
      final result = await _apiService.getCustomerById(customerId);

      debugPrint('🔍 Fetching customer details for ID: $customerId');
      debugPrint('📊 API Response - Success: ${result.success}');
      debugPrint('📦 API Response - Data: ${result.data}');

      if (result.success && result.data != null) {
        // API returns: {success: true, data: {customer: ..., installment_plans: ..., summary: ...}}
        final responseData = result.data as Map<String, dynamic>?;

        if (responseData != null) {
          debugPrint('📋 Response data keys: ${responseData.keys.toList()}');

          // Based on web app: customerData.data.customer and customerData.data.installment_plans
          final data = responseData['data'] as Map<String, dynamic>?;

          if (data != null) {
            debugPrint('📋 Data keys: ${data.keys.toList()}');

            // Parse customer data
            if (data.containsKey('customer')) {
              _customerDetails = data['customer'] as Map<String, dynamic>?;
              debugPrint(
                  '✅ Customer details loaded: ${_customerDetails?['full_name']}');
            }

            // Parse installment plans - matching web app structure
            if (data.containsKey('installment_plans')) {
              _installmentPlans =
                  data['installment_plans'] as List<dynamic>? ?? [];
              debugPrint(
                  '✅ Installment plans loaded: ${_installmentPlans.length} plans');

              if (_installmentPlans.isNotEmpty) {
                debugPrint(
                    '📊 First installment plan: ${_installmentPlans[0]}');
              } else {
                debugPrint('⚠️ No installment plans returned from API');
              }
            } else {
              _installmentPlans = [];
              debugPrint(
                  '⚠️ No installment_plans key found in data. Available keys: ${data.keys.toList()}');
            }

            // Parse summary
            if (data.containsKey('summary')) {
              _installmentSummary = data['summary'] as Map<String, dynamic>?;
              debugPrint('✅ Summary loaded: $_installmentSummary');
            } else {
              debugPrint('⚠️ No summary key found in data');
            }

            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            debugPrint('❌ Data field is null in response');
          }
        } else {
          debugPrint('❌ Response data is null');
        }
      } else {
        debugPrint('❌ API call failed: ${result.message}');
      }

      _error = result.message ?? 'فشل في جلب تفاصيل العميل';
      _isLoading = false;
      notifyListeners();
      return false;
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
