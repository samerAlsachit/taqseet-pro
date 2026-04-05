class Customer {
  final String? id;
  final String storeId;
  final String fullName;
  final String? phone;
  final String? phoneAlt;
  final String? address;
  final String? nationalId;
  final String? notes;
  final String? syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.storeId,
    required this.fullName,
    this.phone,
    this.phoneAlt,
    this.address,
    this.nationalId,
    this.notes,
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'full_name': fullName,
      'phone': phone,
      'phone_alt': phoneAlt,
      'address': address,
      'national_id': nationalId,
      'notes': notes,
      'sync_status': syncStatus ?? 'pending',
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      storeId: map['store_id'] ?? '',
      fullName: map['full_name'] ?? '',
      phone: map['phone'],
      phoneAlt: map['phone_alt'],
      address: map['address'],
      nationalId: map['national_id'],
      notes: map['notes'],
      syncStatus: map['sync_status'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // JSON methods for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'full_name': fullName,
      'phone': phone,
      'phone_alt': phoneAlt,
      'address': address,
      'national_id': nationalId,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      storeId: json['store_id'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      phoneAlt: json['phone_alt'],
      address: json['address'],
      nationalId: json['national_id'],
      notes: json['notes'],
      syncStatus: json['sync_status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Customer copyWith({
    String? id,
    String? storeId,
    String? fullName,
    String? phone,
    String? phoneAlt,
    String? address,
    String? nationalId,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      phoneAlt: phoneAlt ?? this.phoneAlt,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, storeId: $storeId, fullName: $fullName, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.storeId == storeId &&
        other.fullName == fullName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ storeId.hashCode ^ fullName.hashCode;
  }
}
