class ProductModel {
  final String id;
  final String name;
  int stockQuantity;
  final double priceIQD;
  final double priceUSD;

  ProductModel({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.priceIQD,
    required this.priceUSD,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      stockQuantity: json['stockQuantity'] as int,
      priceIQD: (json['priceIQD'] as num).toDouble(),
      priceUSD: (json['priceUSD'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stockQuantity': stockQuantity,
      'priceIQD': priceIQD,
      'priceUSD': priceUSD,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    int? stockQuantity,
    double? priceIQD,
    double? priceUSD,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      priceIQD: priceIQD ?? this.priceIQD,
      priceUSD: priceUSD ?? this.priceUSD,
    );
  }
}
