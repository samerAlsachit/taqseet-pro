import 'package:dio/dio.dart';
import 'api_client.dart';
import 'thabit_local_db_service.dart';
import '../models/product_model.dart';

/// ProductService - خدمة إدارة المنتجات
/// تتعامل مع جلب المنتجات من API وتخزينها في Hive
class ProductService {
  final ApiClient _apiClient = ApiClient();
  final ThabitLocalDBService _localDB = ThabitLocalDBService();
  Dio? _dio;

  ProductService() {
    _dio = _apiClient.dio;
  }

  /// Sync products from API and store locally
  /// تقوم بجلب المنتجات من API وتخزينها في Hive
  Future<SyncResult> syncProducts() async {
    try {
      print('🔄 ProductService: Syncing products from API...');

      final response = await _dio!.get('/products');

      if (response.statusCode != 200) {
        return SyncResult.error('HTTP ${response.statusCode}');
      }

      final responseData = response.data;
      List<dynamic> productsList = [];

      print('📦 Raw response: $responseData');

      // Handle different response formats
      if (responseData is Map<String, dynamic>) {
        // Check for nested formats: {data: {products: [...]}} or {data: [...]} or {products: [...]}
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          // Format: {success: true, data: {products: [...]}}
          productsList = data['products'] ?? data['data'] ?? [];
        } else if (data is List) {
          // Format: {success: true, data: [...]}
          productsList = data;
        } else {
          // Format: {products: [...]} or direct map
          productsList = responseData['products'] ?? [];
        }
      } else if (responseData is List) {
        // Direct list format: [...]
        productsList = responseData;
      }

      print(
        '📦 ProductService: Received ${productsList.length} products from API',
      );

      // Convert to ProductModel list
      final products = productsList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Clear existing and save new products (atomic operation)
      await _localDB.init();
      final productsData = products.map((p) => p.toJson()).toList();
      final savedCount = await _localDB.clearAndSaveProducts(productsData);

      print('✅ ProductService: Saved $savedCount products to local DB');

      return SyncResult.success(
        count: savedCount,
        message: 'تم تحديث $savedCount منتج',
      );
    } on DioException catch (e) {
      print('❌ ProductService DioException: ${e.message}');
      return SyncResult.error('فشل الاتصال بالخادم: ${e.message}');
    } catch (e) {
      print('❌ ProductService Error: $e');
      return SyncResult.error('حدث خطأ: $e');
    }
  }

  /// Get all products from local storage
  /// جلب جميع المنتجات من التخزين المحلي
  List<ProductModel> getAllProducts() {
    final productsData = _localDB.getAllProducts();
    return productsData.map((data) => ProductModel.fromJson(data)).toList();
  }

  /// Get product by ID
  ProductModel? getProductById(String id) {
    final data = _localDB.getProductById(id);
    if (data != null) {
      return ProductModel.fromJson(data);
    }
    return null;
  }

  /// Get low stock products
  List<ProductModel> getLowStockProducts() {
    final productsData = _localDB.getLowStockProducts();
    return productsData.map((data) => ProductModel.fromJson(data)).toList();
  }

  /// Force full re-sync (wipe and fetch)
  /// إعادة المزامنة الكاملة (مسح وجلب جديد)
  Future<SyncResult> forceFullResync() async {
    print('🗑️ ProductService: Force full re-sync - wiping products...');
    await _localDB.init();
    await _localDB.clearTableCache('products');
    return await syncProducts();
  }

  /// Create new product via API and save locally
  /// إنشاء منتج جديد عبر API وحفظه محلياً
  Future<SyncResult> createProduct(ProductModel product) async {
    try {
      print('🆕 ProductService: Creating product via API...');

      final response = await _dio!.post('/products', data: product.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Extract created product from response
        final responseData = response.data;
        final createdProductData = responseData is Map<String, dynamic>
            ? (responseData['data'] ?? responseData)
            : responseData;

        final createdProduct = ProductModel.fromJson(createdProductData);

        // Save to local DB
        await _localDB.init();
        await _localDB.saveProduct(createdProduct.toJson());

        print('✅ ProductService: Created product ${createdProduct.id}');
        return SyncResult.success(count: 1, message: 'تم إضافة المنتج بنجاح');
      }

      return SyncResult.error('فشل إضافة المنتج: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ ProductService DioException: ${e.message}');
      return SyncResult.error('فشل الاتصال بالخادم: ${e.message}');
    } catch (e) {
      print('❌ ProductService Error: $e');
      return SyncResult.error('حدث خطأ: $e');
    }
  }

  /// Update product via API and locally
  /// تحديث المنتج عبر API ومحلياً
  Future<SyncResult> updateProduct(ProductModel product) async {
    try {
      print('✏️ ProductService: Updating product ${product.id} via API...');

      final response = await _dio!.put(
        '/products/${product.id}',
        data: product.toJson(),
      );

      if (response.statusCode == 200) {
        // Extract updated product from response
        final responseData = response.data;
        final updatedProductData = responseData is Map<String, dynamic>
            ? (responseData['data'] ?? responseData)
            : responseData;

        final updatedProduct = ProductModel.fromJson(updatedProductData);

        // Save to local DB
        await _localDB.init();
        await _localDB.saveProduct(updatedProduct.toJson());

        print('✅ ProductService: Updated product ${updatedProduct.id}');
        return SyncResult.success(count: 1, message: 'تم تحديث المنتج بنجاح');
      }

      return SyncResult.error('فشل تحديث المنتج: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ ProductService DioException: ${e.message}');
      return SyncResult.error('فشل الاتصال بالخادم: ${e.message}');
    } catch (e) {
      print('❌ ProductService Error: $e');
      return SyncResult.error('حدث خطأ: $e');
    }
  }

  /// Save product to local DB only (for offline mode)
  /// حفظ المنتج في قاعدة البيانات المحلية فقط
  Future<void> saveProductLocally(ProductModel product) async {
    await _localDB.init();
    await _localDB.saveProduct(product.toJson());
  }

  /// Delete product via API and locally
  /// حذف المنتج من API ومحلياً
  Future<SyncResult> deleteProduct(String productId) async {
    try {
      print('🗑️ ProductService: Deleting product $productId...');

      final response = await _dio!.delete('/products/$productId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Delete from local DB
        await _localDB.init();
        await _localDB.deleteProduct(productId);

        print('✅ ProductService: Deleted product $productId');
        return SyncResult.success(count: 1, message: 'تم حذف المنتج بنجاح');
      }

      return SyncResult.error('فشل حذف المنتج: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ ProductService DioException: ${e.message}');
      return SyncResult.error('فشل الاتصال بالخادم: ${e.message}');
    } catch (e) {
      print('❌ ProductService Error: $e');
      return SyncResult.error('حدث خطأ: $e');
    }
  }
}

/// Sync Result class
class SyncResult {
  final bool success;
  final int count;
  final String message;

  SyncResult({
    required this.success,
    required this.count,
    required this.message,
  });

  factory SyncResult.success({required int count, required String message}) {
    return SyncResult(success: true, count: count, message: message);
  }

  factory SyncResult.error(String message) {
    return SyncResult(success: false, count: 0, message: message);
  }
}
