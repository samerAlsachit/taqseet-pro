class Product {
  final String? id;
  final String storeId;
  final String name;
  final String? category;
  final int quantity;
  final int lowStockAlert;
  final int sellPriceCashIqd;
  final int sellPriceInstallIqd;
  final String currency;
  final String? syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.storeId,
    required this.name,
    this.category,
    required this.quantity,
    required this.lowStockAlert,
    required this.sellPriceCashIqd,
    required this.sellPriceInstallIqd,
    this.currency = 'IQD',
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'low_stock_alert': lowStockAlert,
      'sell_price_cash_iqd': sellPriceCashIqd,
      'sell_price_install_iqd': sellPriceInstallIqd,
      'currency': currency,
      'sync_status': syncStatus ?? 'pending',
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      quantity:
          (map['quantity'] is int
              ? map['quantity']
              : (map['quantity'] as num).toInt()) ??
          0,
      lowStockAlert:
          (map['low_stock_alert'] is int
              ? map['low_stock_alert']
              : (map['low_stock_alert'] as num).toInt()) ??
          5,
      sellPriceCashIqd:
          (map['sell_price_cash_iqd'] is int
              ? map['sell_price_cash_iqd']
              : (map['sell_price_cash_iqd'] as num).toInt()) ??
          0,
      sellPriceInstallIqd:
          (map['sell_price_install_iqd'] is int
              ? map['sell_price_install_iqd']
              : (map['sell_price_install_iqd'] as num).toInt()) ??
          0,
      currency: map['currency'] as String? ?? 'IQD',
      syncStatus: map['sync_status'] as String? ?? 'synced',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // JSON methods for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'low_stock_alert': lowStockAlert,
      'sell_price_cash_iqd': sellPriceCashIqd,
      'sell_price_install_iqd': sellPriceInstallIqd,
      'currency': currency,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      quantity:
          (json['quantity'] is int
              ? json['quantity']
              : (json['quantity'] as num).toInt()) ??
          0,
      lowStockAlert:
          (json['low_stock_alert'] is int
              ? json['low_stock_alert']
              : (json['low_stock_alert'] as num).toInt()) ??
          5,
      sellPriceCashIqd:
          (json['sell_price_cash_iqd'] is int
              ? json['sell_price_cash_iqd']
              : (json['sell_price_cash_iqd'] as num).toInt()) ??
          0,
      sellPriceInstallIqd:
          (json['sell_price_install_iqd'] is int
              ? json['sell_price_install_iqd']
              : (json['sell_price_install_iqd'] as num).toInt()) ??
          0,
      currency: json['currency'] as String? ?? 'IQD',
      syncStatus: json['sync_status'] as String? ?? 'synced',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Product copyWith({
    String? id,
    String? storeId,
    String? name,
    String? category,
    int? quantity,
    int? lowStockAlert,
    int? sellPriceCashIqd,
    int? sellPriceInstallIqd,
    String? currency,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      sellPriceCashIqd: sellPriceCashIqd ?? this.sellPriceCashIqd,
      sellPriceInstallIqd: sellPriceInstallIqd ?? this.sellPriceInstallIqd,
      currency: currency ?? this.currency,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if product is low stock
  bool get isLowStock => quantity <= lowStockAlert;

  // Get formatted prices
  String get formattedCashPrice => '$sellPriceCashIqd $currency';
  String get formattedInstallPrice => '$sellPriceInstallIqd $currency';

  @override
  String toString() {
    return 'Product(id: $id, storeId: $storeId, name: $name, quantity: $quantity, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.storeId == storeId &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ storeId.hashCode ^ name.hashCode;
  }
}
