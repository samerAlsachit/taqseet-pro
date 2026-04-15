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

      // Handle different response formats
      if (responseData is Map<String, dynamic>) {
        productsList = responseData['data'] ?? responseData['products'] ?? [];
      } else if (responseData is List) {
        productsList = responseData;
      }

      print(
        '📦 ProductService: Received ${productsList.length} products from API',
      );

      // Convert to ProductModel list
      final products = productsList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Clear existing products and save new ones
      await _localDB.init();
      await _localDB.clearTableCache('products');

      // Save to local DB
      final productsData = products.map((p) => p.toJson()).toList();
      final savedCount = await _localDB.batchSaveProducts(productsData);

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
