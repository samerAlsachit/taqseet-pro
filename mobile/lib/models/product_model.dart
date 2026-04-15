/// ProductModel - نموذج المنتج
/// يتوافق مع استجابة Node.js API
class ProductModel {
  final String id;
  final String name;
  final String category;
  int quantity; // المخزون الحالي
  final int lowStockAlert; // حد التنبيه للمخزون المنخفض
  final String currency; // العملة الأساسية (IQD أو USD)

  // أسعار التكلفة
  final double costPriceIqd;
  final double costPriceUsd;

  // أسعار البيع نقداً
  final double sellPriceCashIqd;
  final double sellPriceCashUsd;

  // أسعار البيع بالقسط
  final double sellPriceInstallIqd;
  final double sellPriceInstallUsd;

  final String? description;
  final String storeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.category = '',
    required this.quantity,
    this.lowStockAlert = 5,
    this.currency = 'IQD',
    this.costPriceIqd = 0,
    this.costPriceUsd = 0,
    this.sellPriceCashIqd = 0,
    this.sellPriceCashUsd = 0,
    this.sellPriceInstallIqd = 0,
    this.sellPriceInstallUsd = 0,
    this.description,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// للتوافق مع الكود القديم - المخزون
  int get stockQuantity => quantity;
  set stockQuantity(int value) => quantity = value;

  /// للتوافق مع الكود القديم - سعر الدينار
  double get priceIQD => sellPriceCashIqd;

  /// للتوافق مع الكود القديم - سعر الدولار
  double get priceUSD => sellPriceCashUsd;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lowStockAlert: (json['low_stock_alert'] as num?)?.toInt() ?? 5,
      currency: json['currency'] as String? ?? 'IQD',
      costPriceIqd: (json['cost_price_iqd'] as num?)?.toDouble() ?? 0,
      costPriceUsd: (json['cost_price_usd'] as num?)?.toDouble() ?? 0,
      sellPriceCashIqd: (json['sell_price_cash_iqd'] as num?)?.toDouble() ?? 0,
      sellPriceCashUsd: (json['sell_price_cash_usd'] as num?)?.toDouble() ?? 0,
      sellPriceInstallIqd:
          (json['sell_price_install_iqd'] as num?)?.toDouble() ?? 0,
      sellPriceInstallUsd:
          (json['sell_price_install_usd'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      storeId: json['store_id'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'low_stock_alert': lowStockAlert,
      'currency': currency,
      'cost_price_iqd': costPriceIqd,
      'cost_price_usd': costPriceUsd,
      'sell_price_cash_iqd': sellPriceCashIqd,
      'sell_price_cash_usd': sellPriceCashUsd,
      'sell_price_install_iqd': sellPriceInstallIqd,
      'sell_price_install_usd': sellPriceInstallUsd,
      'description': description,
      'store_id': storeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    int? lowStockAlert,
    String? currency,
    double? costPriceIqd,
    double? costPriceUsd,
    double? sellPriceCashIqd,
    double? sellPriceCashUsd,
    double? sellPriceInstallIqd,
    double? sellPriceInstallUsd,
    String? description,
    String? storeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      currency: currency ?? this.currency,
      costPriceIqd: costPriceIqd ?? this.costPriceIqd,
      costPriceUsd: costPriceUsd ?? this.costPriceUsd,
      sellPriceCashIqd: sellPriceCashIqd ?? this.sellPriceCashIqd,
      sellPriceCashUsd: sellPriceCashUsd ?? this.sellPriceCashUsd,
      sellPriceInstallIqd: sellPriceInstallIqd ?? this.sellPriceInstallIqd,
      sellPriceInstallUsd: sellPriceInstallUsd ?? this.sellPriceInstallUsd,
      description: description ?? this.description,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// التحقق من المخزون المنخفض
  bool get isLowStock => quantity <= lowStockAlert;

  /// الحصول على السعر المناسب حسب العملة
  double getDisplayPrice({bool isInstallment = false}) {
    if (currency == 'USD') {
      return isInstallment ? sellPriceInstallUsd : sellPriceCashUsd;
    }
    return isInstallment ? sellPriceInstallIqd : sellPriceCashIqd;
  }
}
