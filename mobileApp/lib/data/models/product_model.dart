class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final int quantity;
  final double cashPrice;
  final double installmentPrice;
  final double costPrice;
  final String? imageUrl;
  final String? barcode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final bool isDeleted;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.quantity = 0,
    this.cashPrice = 0,
    this.installmentPrice = 0,
    this.costPrice = 0,
    this.imageUrl,
    this.barcode,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['product_name']?.toString() ??
          'غير معروف',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      quantity: json['quantity'] ?? json['stock'] ?? 0,
      cashPrice: _parseDouble(json['cash_price']) ??
          _parseDouble(json['cashPrice']) ??
          _parseDouble(json['price']) ??
          0,
      installmentPrice: _parseDouble(json['installment_price']) ??
          _parseDouble(json['installmentPrice']) ??
          0,
      costPrice: _parseDouble(json['cost_price']) ??
          _parseDouble(json['costPrice']) ??
          _parseDouble(json['purchase_price']) ??
          0,
      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          json['photo_url']?.toString(),
      barcode: json['barcode']?.toString(),
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['isActive'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isSynced: json['is_synced'] == true || json['is_synced'] == 1,
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'cash_price': cashPrice,
      'installment_price': installmentPrice,
      'cost_price': costPrice,
      'image_url': imageUrl,
      'barcode': barcode,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_synced': isSynced,
      'is_deleted': isDeleted,
    };
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'cash_price': cashPrice,
      'installment_price': installmentPrice,
      'cost_price': costPrice,
      'image_url': imageUrl,
      'barcode': barcode,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? quantity,
    double? cashPrice,
    double? installmentPrice,
    double? costPrice,
    String? imageUrl,
    String? barcode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      cashPrice: cashPrice ?? this.cashPrice,
      installmentPrice: installmentPrice ?? this.installmentPrice,
      costPrice: costPrice ?? this.costPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
