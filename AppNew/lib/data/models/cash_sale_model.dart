class CashSaleModel {
  final String id;
  final String storeId;
  final String? customerName;
  final List<CashSaleItem> items;
  final double totalAmount;
  final String currency;
  final DateTime createdAt;

  CashSaleModel({
    required this.id,
    required this.storeId,
    this.customerName,
    required this.items,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
  });

  factory CashSaleModel.fromJson(Map<String, dynamic> json) => CashSaleModel(
    id: json['id']?.toString() ?? '',
    storeId: json['store_id']?.toString() ?? '',
    customerName: json['customer_name'],
    items: (json['items'] as List<dynamic>?)?.map((e) => CashSaleItem.fromJson(e)).toList() ?? [],
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] ?? 'IQD',
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

class CashSaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;

  CashSaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory CashSaleItem.fromJson(Map<String, dynamic> json) => CashSaleItem(
    productId: json['product_id']?.toString() ?? '',
    productName: json['product_name'] ?? '',
    quantity: json['quantity'] ?? 1,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
  );
}
