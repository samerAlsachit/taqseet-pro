import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String _storeId = 'default_store';
  bool _showLowStockOnly = false;

  ProductProvider(this._productRepository);

  List<Product> get products => _showLowStockOnly
      ? _products.where((product) => product.isLowStock).toList()
      : _products;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showLowStockOnly => _showLowStockOnly;

  // Set store ID for filtering
  void setStoreId(String storeId) {
    _storeId = storeId;
    notifyListeners();
  }

  // Toggle low stock filter
  void toggleLowStockFilter() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }

  // Fetch all products
  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      _products = await _productRepository.getProductsByStore(_storeId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Add new product
  Future<void> addProduct(Product product) async {
    _setLoading(true);
    try {
      await _productRepository.insert(product);
      await fetchProducts(); // Refresh list
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Update existing product
  Future<void> updateProduct(Product product) async {
    _setLoading(true);
    try {
      await _productRepository.update(product);
      await fetchProducts(); // Refresh list
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    _setLoading(true);
    try {
      await _productRepository.delete(id);
      await fetchProducts(); // Refresh list
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _setLoading(true);
    try {
      if (query.isEmpty) {
        _products = await _productRepository.getProductsByStore(_storeId);
      } else {
        _products = await _productRepository.search(query, _storeId);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get low stock products
  Future<void> fetchLowStockProducts() async {
    _setLoading(true);
    try {
      _products = await _productRepository.getLowStock(_storeId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get product from repository
  Future<Product?> getProductFromRepo(String id) async {
    try {
      return await _productRepository.getById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      return await _productRepository.getByCategory(category, _storeId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get product statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _productRepository.getStatistics(_storeId);
    } catch (e) {
      _error = e.toString();
      return {};
    }
  }

  // Update product quantity
  Future<void> updateProductQuantity(String id, int quantity) async {
    try {
      await _productRepository.updateQuantity(id, quantity);
      await fetchProducts(); // Refresh list
    } catch (e) {
      _error = e.toString();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh products list
  Future<void> refresh() async {
    await fetchProducts();
  }
}
