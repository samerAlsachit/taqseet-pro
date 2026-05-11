import '../datasources/remote/api_service.dart';
import '../datasources/local/hive_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  final _api = ApiService();
  final _hive = HiveService();

  Future<List<ProductModel>> getAll({String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get('/products', params: params);
      if (res['success'] == true) {
        final products = ((res['data'] is List ? res['data'] : res['data']['products']) as List).map((e) => ProductModel.fromJson(e)).toList();
        await _hive.putList('products', products.map((e) => e.toJson()).toList());
        return products;
      }
    } catch (_) {}
    final cached = _hive.getList('products');
    return cached?.map((e) => ProductModel.fromJson(e)).toList() ?? [];
  }

  Future<ProductModel> create(Map<String, dynamic> data) async {
    final res = await _api.post('/products', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل إضافة المنتج');
    final productData = res['data']['product'] ?? res['data'];
    return ProductModel.fromJson(productData);
  }

  Future<ProductModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/products/$id', data: data);
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل تحديث المنتج');
    final productData = res['data']['product'] ?? res['data'];
    return ProductModel.fromJson(productData);
  }

  Future<void> delete(String id) async {
    final res = await _api.delete('/products/$id');
    if (res['success'] != true) throw Exception(res['error'] ?? 'فشل حذف المنتج');
  }
}
