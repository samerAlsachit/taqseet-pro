class ProductModel {
  final String id;
  final String storeId;
  final String name;
  final String? description;
  final int quantity;
  final double? priceIqd;
  final double? priceUsd;
  final double? costPriceIqd;
  final double? costPriceUsd;
  final double? sellPriceCashIqd;
  final double? sellPriceCashUsd;
  final double? sellPriceInstallIqd;
  final double? sellPriceInstallUsd;
  final String? category;
  final String? sku;
  final int? lowStockAlert;

  ProductModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    required this.quantity,
    this.priceIqd,
    this.priceUsd,
    this.costPriceIqd,
    this.costPriceUsd,
    this.sellPriceCashIqd,
    this.sellPriceCashUsd,
    this.sellPriceInstallIqd,
    this.sellPriceInstallUsd,
    this.category,
    this.sku,
    this.lowStockAlert,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id']?.toString() ?? '',
    storeId: json['store_id']?.toString() ?? '',
    name: json['name'] ?? '',
    description: json['description'],
    quantity: json['quantity'] ?? 0,
    priceIqd: (json['price_iqd'] as num?)?.toDouble(),
    priceUsd: (json['price_usd'] as num?)?.toDouble(),
    costPriceIqd: (json['cost_price_iqd'] as num?)?.toDouble(),
    costPriceUsd: (json['cost_price_usd'] as num?)?.toDouble(),
    sellPriceCashIqd: (json['sell_price_cash_iqd'] as num?)?.toDouble(),
    sellPriceCashUsd: (json['sell_price_cash_usd'] as num?)?.toDouble(),
    sellPriceInstallIqd: (json['sell_price_install_iqd'] as num?)?.toDouble(),
    sellPriceInstallUsd: (json['sell_price_install_usd'] as num?)?.toDouble(),
    category: json['category'],
    sku: json['sku'],
    lowStockAlert: json['low_stock_alert'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'quantity': quantity,
    'price_iqd': priceIqd,
    'price_usd': priceUsd,
    'cost_price_iqd': costPriceIqd,
    'cost_price_usd': costPriceUsd,
    'sell_price_cash_iqd': sellPriceCashIqd,
    'sell_price_cash_usd': sellPriceCashUsd,
    'sell_price_install_iqd': sellPriceInstallIqd,
    'sell_price_install_usd': sellPriceInstallUsd,
    'category': category,
    'sku': sku,
    'low_stock_alert': lowStockAlert,
  };
}
