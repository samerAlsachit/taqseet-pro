import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

/// ProductsController - متحكم المنتجات
/// يدير حالة المنتجات والمزامنة مع API
class ProductsController extends ChangeNotifier {
  final ProductService _productService = ProductService();

  // State
  List<ProductModel> products = [];
  bool isLoading = false;
  String errorMessage = '';

  /// Load products from API and local storage
  Future<void> loadProducts() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // Sync from API first
      final result = await _productService.syncProducts();

      if (result.success) {
        // Get fresh data from local storage
        products = _productService.getAllProducts();
        print('✅ ProductsController: Loaded ${products.length} products');
      } else {
        // Try to get local data even if API failed
        products = _productService.getAllProducts();
        if (products.isEmpty) {
          errorMessage = result.message;
        }
      }
    } catch (e) {
      print('❌ ProductsController Error: $e');
      errorMessage = 'فشل تحميل المنتجات: $e';
      // Try to get cached data
      products = _productService.getAllProducts();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh from API
  Future<void> refreshProducts() async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _productService.forceFullResync();

      if (result.success) {
        products = _productService.getAllProducts();
      } else {
        errorMessage = result.message;
      }
    } catch (e) {
      print('❌ ProductsController Refresh Error: $e');
      errorMessage = 'فشل التحديث: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Filter products by search query
  List<ProductModel> filterProducts(String query) {
    if (query.isEmpty) {
      return products;
    }
    return products.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.category.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Get low stock products count
  int get lowStockCount => products.where((p) => p.isLowStock).length;

  /// Get all products (for direct access)
  List<ProductModel> getAllProducts() {
    return _productService.getAllProducts();
  }

  /// Delete product by ID
  Future<bool> deleteProduct(String productId) async {
    try {
      final result = await _productService.deleteProduct(productId);

      if (result.success) {
        // Remove from local list
        products.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ ProductsController Delete Error: $e');
      return false;
    }
  }
}
