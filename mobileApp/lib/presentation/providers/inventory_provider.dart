import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../services/api/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  final _apiService = ApiService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<ProductModel> get products => _products;
  List<ProductModel> get filteredProducts => _filteredProducts;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  InventoryProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📦 Loading products from API...');
      final result = await _apiService.getProducts();

      if (result.success) {
        debugPrint('📦 Products API result: success=${result.success}');

        // Handle different response formats
        List<dynamic> productsList = [];
        final responseData = result.data;

        if (responseData is Map && responseData['data'] != null) {
          productsList =
              responseData['data']['products'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          productsList = responseData;
        } else if (responseData is Map) {
          productsList = [responseData];
        }

        _products = productsList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _applySearch();
        debugPrint('✅ Loaded ${_products.length} products');
      } else {
        _error = result.message;
        debugPrint('❌ API error: ${result.message}');
      }
    } catch (e, stackTrace) {
      _error = 'فشل في تحميل المنتجات: $e';
      debugPrint('❌ Load products error: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
            (product.barcode?.toLowerCase().contains(lowerQuery) ?? false) ||
            (product.category?.toLowerCase().contains(lowerQuery) ?? false) ||
            (product.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createProduct(product.toJson());

      if (result.success && result.data != null) {
        // Handle different response formats
        final responseData = result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : <String, dynamic>{};

        final newProduct = ProductModel.fromJson(responseData);
        _products.insert(0, newProduct);
        _applySearch();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'فشل في إضافة المنتج';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'فشل في إضافة المنتج: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result =
          await _apiService.updateProduct(product.id, product.toJson());

      if (result.success && result.data != null) {
        // Handle different response formats
        final responseData = result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : <String, dynamic>{};

        final updatedProduct = ProductModel.fromJson(responseData);
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
        final filteredIndex =
            _filteredProducts.indexWhere((p) => p.id == product.id);
        if (filteredIndex != -1) {
          _filteredProducts[filteredIndex] = updatedProduct;
        }
        if (_selectedProduct?.id == product.id) {
          _selectedProduct = updatedProduct;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'فشل في تحديث المنتج';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'فشل في تحديث المنتج: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.deleteProduct(id);

      if (result.success) {
        _products.removeWhere((p) => p.id == id);
        _filteredProducts.removeWhere((p) => p.id == id);
        if (_selectedProduct?.id == id) {
          _selectedProduct = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'فشل في حذف المنتج';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'فشل في حذف المنتج: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void selectProduct(ProductModel? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
