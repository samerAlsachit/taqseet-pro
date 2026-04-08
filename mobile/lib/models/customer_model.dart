class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;

  // Image paths for documentation
  final String? customerImagePath;
  final String? docFrontPath;
  final String? docBackPath;
  final String? residenceCardPath;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.customerImagePath,
    this.docFrontPath,
    this.docBackPath,
    this.residenceCardPath,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      customerImagePath: json['customerImagePath'] as String?,
      docFrontPath: json['docFrontPath'] as String?,
      docBackPath: json['docBackPath'] as String?,
      residenceCardPath: json['residenceCardPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'customerImagePath': customerImagePath,
      'docFrontPath': docFrontPath,
      'docBackPath': docBackPath,
      'residenceCardPath': residenceCardPath,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? customerImagePath,
    String? docFrontPath,
    String? docBackPath,
    String? residenceCardPath,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      customerImagePath: customerImagePath ?? this.customerImagePath,
      docFrontPath: docFrontPath ?? this.docFrontPath,
      docBackPath: docBackPath ?? this.docBackPath,
      residenceCardPath: residenceCardPath ?? this.residenceCardPath,
    );
  }
}
