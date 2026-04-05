import '../models/product.dart';
import '../../core/database/database_helper.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper;

  ProductRepository(this._databaseHelper);

  // Get all products
  Future<List<Product>> getAll() async {
    try {
      final products = await _databaseHelper.getAllProducts();
      return products.map((product) => Product.fromMap(product)).toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // Get product by ID
  Future<Product?> getById(String id) async {
    try {
      final product = await _databaseHelper.getProductById(id);
      return product != null ? Product.fromMap(product) : null;
    } catch (e) {
      throw Exception('Failed to get product by ID: $e');
    }
  }

  // Insert new product
  Future<String> insert(Product product) async {
    try {
      final productMap = product.toMap();

      // تحويل جميع القيم العشرية إلى أعداد صحيحة
      int priceCash = (productMap['sell_price_cash_iqd'] ?? 0).toInt();
      int priceInstall = (productMap['sell_price_install_iqd'] ?? 0).toInt();
      int quantity = (productMap['quantity'] ?? 0).toInt();
      int lowStock = (productMap['low_stock_alert'] ?? 5).toInt();

      // تحديث القيم في الخريطة
      productMap['sell_price_cash_iqd'] = priceCash;
      productMap['sell_price_install_iqd'] = priceInstall;
      productMap['quantity'] = quantity;
      productMap['low_stock_alert'] = lowStock;

      return await _databaseHelper.insertProduct(productMap);
    } catch (e) {
      throw Exception('Failed to insert product: $e');
    }
  }

  // Update existing product
  Future<int> update(Product product) async {
    try {
      if (product.id == null) {
        throw Exception('Product ID is required for update');
      }

      final productMap = product.toMap();

      // تحويل جميع القيم العشرية إلى أعداد صحيحة
      int priceCash = (productMap['sell_price_cash_iqd'] ?? 0).toInt();
      int priceInstall = (productMap['sell_price_install_iqd'] ?? 0).toInt();
      int quantity = (productMap['quantity'] ?? 0).toInt();
      int lowStock = (productMap['low_stock_alert'] ?? 5).toInt();

      // تحديث القيم في الخريطة
      productMap['sell_price_cash_iqd'] = priceCash;
      productMap['sell_price_install_iqd'] = priceInstall;
      productMap['quantity'] = quantity;
      productMap['low_stock_alert'] = lowStock;

      return await _databaseHelper.updateProduct(product.id!, productMap);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<int> delete(String id) async {
    try {
      return await _databaseHelper.deleteProduct(id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Search products by name
  Future<List<Product>> search(String query, String storeId) async {
    try {
      final products = await _databaseHelper.getAllProducts();
      final filteredProducts = products.where((product) {
        final productName = product['name']?.toString().toLowerCase() ?? '';
        final productStoreId = product['store_id']?.toString() ?? '';
        return productStoreId == storeId &&
            productName.contains(query.toLowerCase());
      }).toList();
      return filteredProducts
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get products with low stock
  Future<List<Product>> getLowStock(String storeId) async {
    try {
      final products = await _databaseHelper.getLowStockProducts(storeId);
      return products.map((product) => Product.fromMap(product)).toList();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getByCategory(String category, String storeId) async {
    try {
      final products = await _databaseHelper.getAllProducts();
      final filteredProducts = products.where((product) {
        final productCategory = product['category']?.toString();
        final productStoreId = product['store_id']?.toString() ?? '';
        return productStoreId == storeId && productCategory == category;
      }).toList();
      return filteredProducts
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  // Get products by store
  Future<List<Product>> getProductsByStore(String storeId) async {
    try {
      final products = await _databaseHelper.getAllProducts();
      return products
          .where((product) => product['store_id'] == storeId)
          .map((product) => Product.fromMap(product))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by store: $e');
    }
  }

  // Update product quantity
  Future<int> updateQuantity(String id, int quantity) async {
    try {
      return await _databaseHelper.updateProductQuantity(id, quantity);
    } catch (e) {
      throw Exception('Failed to update product quantity: $e');
    }
  }

  // Get product statistics
  Future<Map<String, dynamic>> getStatistics(String storeId) async {
    try {
      final products = await getProductsByStore(storeId);
      final totalProducts = products.length;
      final lowStockProducts = products.where((p) => p.isLowStock).length;
      final totalValue = products.fold<int>(
        0,
        (sum, product) => sum + (product.quantity * product.sellPriceCashIqd),
      );

      return {
        'total_products': totalProducts,
        'low_stock_products': lowStockProducts,
        'total_value': totalValue,
        'categories': products
            .map((p) => p.category)
            .where((c) => c != null)
            .toSet()
            .toList(),
      };
    } catch (e) {
      throw Exception('Failed to get product statistics: $e');
    }
  }
}
