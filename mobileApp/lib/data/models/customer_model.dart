class CustomerModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? address;
  final String? idNumber;
  final String? avatarUrl;
  final String? idCardFrontUrl;
  final String? idCardBackUrl;
  final String? residenceFrontUrl;
  final String? residenceBackUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  CustomerModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.address,
    this.idNumber,
    this.avatarUrl,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.residenceFrontUrl,
    this.residenceBackUrl,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? 'غير معروف',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      idNumber: json['id_number']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      idCardFrontUrl: json['id_card_front_url']?.toString(),
      idCardBackUrl: json['id_card_back_url']?.toString(),
      residenceFrontUrl: json['residence_front_url']?.toString(),
      residenceBackUrl: json['residence_back_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isSynced: json['is_synced'] == true || json['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'id_number': idNumber,
      'avatar_url': avatarUrl,
      'id_card_front_url': idCardFrontUrl,
      'id_card_back_url': idCardBackUrl,
      'residence_front_url': residenceFrontUrl,
      'residence_back_url': residenceBackUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? address,
    String? idNumber,
    String? avatarUrl,
    String? idCardFrontUrl,
    String? idCardBackUrl,
    String? residenceFrontUrl,
    String? residenceBackUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      idCardFrontUrl: idCardFrontUrl ?? this.idCardFrontUrl,
      idCardBackUrl: idCardBackUrl ?? this.idCardBackUrl,
      residenceFrontUrl: residenceFrontUrl ?? this.residenceFrontUrl,
      residenceBackUrl: residenceBackUrl ?? this.residenceBackUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
