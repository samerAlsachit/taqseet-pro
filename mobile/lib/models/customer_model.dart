class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
