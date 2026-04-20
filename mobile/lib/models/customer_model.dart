class CustomerModel {
  final String id;
  final String fullName; // full_name في Supabase
  final String phone;
  final String? nationalId; // national_id في Supabase (رقم الهوية)
  final String address;
  final String? email;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Local image paths for documentation
  final String? customerImagePath;
  final String? docFrontPath;
  final String? docBackPath;
  final String? residenceCardPath;

  // Supabase Storage URLs
  final String? avatarUrl; // رابط صورة العميل في Supabase
  final List<String>? documentsUrls; // روابط المستمسكات في Supabase

  // Financial summary (calculated from installments)
  final double? totalDebt;
  final double? totalPaid;

  CustomerModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.nationalId,
    required this.address,
    this.email,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.customerImagePath,
    this.docFrontPath,
    this.docBackPath,
    this.residenceCardPath,
    this.avatarUrl,
    this.documentsUrls,
    this.totalDebt,
    this.totalPaid,
  });

  /// للتوافق مع الكود القديم
  String get name => fullName;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      nationalId: json['national_id']?.toString(),
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      customerImagePath:
          json['customer_image_path']?.toString() ??
          json['customerImagePath'] as String?,
      docFrontPath:
          json['doc_front_path']?.toString() ?? json['docFrontPath'] as String?,
      docBackPath:
          json['doc_back_path']?.toString() ?? json['docBackPath'] as String?,
      residenceCardPath:
          json['residence_card_path']?.toString() ??
          json['residenceCardPath'] as String?,
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      documentsUrls: json['documents_urls'] != null
          ? List<String>.from(json['documents_urls'] as List)
          : json['documentsUrls'] != null
          ? List<String>.from(json['documentsUrls'] as List)
          : null,
      totalDebt: json['total_debt'] != null
          ? double.tryParse(json['total_debt'].toString())
          : null,
      totalPaid: json['total_paid'] != null
          ? double.tryParse(json['total_paid'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'address': address,
      'email': email,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customer_image_path': customerImagePath,
      'doc_front_path': docFrontPath,
      'doc_back_path': docBackPath,
      'residence_card_path': residenceCardPath,
      'avatar_url': avatarUrl,
      'documents_urls': documentsUrls,
      'total_debt': totalDebt,
      'total_paid': totalPaid,
    };
  }

  /// Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'address': address,
      'email': email,
      'notes': notes,
      'avatar_url': avatarUrl,
      'documents_urls': documentsUrls,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? nationalId,
    String? address,
    String? email,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerImagePath,
    String? docFrontPath,
    String? docBackPath,
    String? residenceCardPath,
    String? avatarUrl,
    List<String>? documentsUrls,
    double? totalDebt,
    double? totalPaid,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerImagePath: customerImagePath ?? this.customerImagePath,
      docFrontPath: docFrontPath ?? this.docFrontPath,
      docBackPath: docBackPath ?? this.docBackPath,
      residenceCardPath: residenceCardPath ?? this.residenceCardPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      documentsUrls: documentsUrls ?? this.documentsUrls,
      totalDebt: totalDebt ?? this.totalDebt,
      totalPaid: totalPaid ?? this.totalPaid,
    );
  }
}
