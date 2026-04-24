import 'dart:convert';

class CustomerModel {
  // ✅ Supabase Storage Configuration (Hardcoded)
  static const String _supabaseBaseUrl =
      'https://sdygpgchcyxkgqmswgyb.supabase.co/storage/v1/object/public/customers';
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

  // Supabase Storage URLs (مطابقة SQL Schema)
  final String?
  idDocUrl; // رابط صورة الهوية/العميل (id_doc_url في قاعدة البيانات)
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
    this.idDocUrl,
    this.documentsUrls,
    this.totalDebt,
    this.totalPaid,
  });

  /// للتوافق مع الكود القديم
  String get name => fullName;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // ✅ Log raw extra_docs for debugging
    final extraDocsRaw = json['extra_docs'];
    final documentsUrlsRaw = json['documents_urls'];
    print('📄 [fromJson] ID: ${json['id']}');
    print(
      '📄 [fromJson] extra_docs raw: $extraDocsRaw (type: ${extraDocsRaw?.runtimeType})',
    );
    print('📄 [fromJson] documents_urls raw: $documentsUrlsRaw');

    // Priority: documents_urls > documentsUrls > extra_docs
    // ✅ Robust parsing for extra_docs (handles List or String JSON)
    List<String> parseDocuments(dynamic raw) {
      if (raw == null) return [];
      try {
        if (raw is List) {
          return raw.map((e) => e.toString()).toList();
        } else if (raw is String && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        }
      } catch (e) {
        print('⚠️ [fromJson] Error parsing documents: $e');
      }
      return [];
    }

    final List<String> documentsUrls = documentsUrlsRaw != null
        ? parseDocuments(documentsUrlsRaw)
        : json['documentsUrls'] != null
        ? parseDocuments(json['documentsUrls'])
        : parseDocuments(extraDocsRaw);

    print('📄 [fromJson] Parsed documentsUrls: $documentsUrls');

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
      idDocUrl:
          json['id_doc_url']?.toString() ??
          json['idDocUrl']?.toString() ??
          json['avatar_url']?.toString() ??
          json['avatarUrl']?.toString(),
      documentsUrls: documentsUrls,
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
      'id_doc_url': idDocUrl,
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
      'id_doc_url': idDocUrl,
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
    String? idDocUrl,
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
      idDocUrl: idDocUrl ?? this.idDocUrl,
      documentsUrls: documentsUrls ?? this.documentsUrls,
      totalDebt: totalDebt ?? this.totalDebt,
      totalPaid: totalPaid ?? this.totalPaid,
    );
  }

  // ============================================
  // ✅ Helper Methods for Supabase Storage URLs
  // ============================================

  /// ✅ الحصول على رابط صورة الهوية/العميل الكامل
  /// يستخدم حقل id_doc_url من قاعدة البيانات
  /// بناء الرابط يدوياً: https://.../customers/avatars/filename.jpg
  String? get fullIdDocUrl {
    if (idDocUrl == null || idDocUrl!.isEmpty) return null;

    final String url = idDocUrl!;

    // إذا كان الرابط كامل already (يبدأ بـ http)
    if (url.startsWith('http')) {
      return url;
    }

    // إذا كان المسار يحتوي على المجلد مسبقاً (avatars/filename.jpg)
    if (url.contains('/')) {
      return '$_supabaseBaseUrl/$url';
    }

    // اسم الملف فقط → أضف المجلد avatars
    return '$_supabaseBaseUrl/avatars/$url';
  }

  /// للتوافق مع الكود القديم - alias
  String? get fullAvatarUrl => fullIdDocUrl;

  /// ✅ رابط صورة البروفايل مباشرة (للاستخدام في UI)
  /// يستخدم id_doc_url عند توفره، وإلا يستخدم ID العميل كاحتياطي
  /// التنسيق: https://.../customers/avatars/{id_doc_url أو id}.jpg
  String get profileImageUrl {
    // ✅ إذا كان id_doc_url موجوداً ولا يبدأ بـ http، استخدمه
    if (idDocUrl != null && idDocUrl!.isNotEmpty) {
      if (idDocUrl!.startsWith('http')) {
        return idDocUrl!; // الرابط كامل
      }
      // اسم الملف فقط أو مسار نسبي - أضف الـ base URL
      if (idDocUrl!.contains('/')) {
        return '$_supabaseBaseUrl/$idDocUrl';
      }
      return '$_supabaseBaseUrl/avatars/$idDocUrl';
    }

    // ✅ احتياطي: استخدام ID العميل إذا كان id_doc_url فارغاً
    return '$_supabaseBaseUrl/avatars/$id.jpg';
  }

  /// ✅ الحصول على روابط المستمسكات الكاملة (alias للتوافق)
  List<String> get documentUrls => fullDocumentsUrls;

  /// ✅ الحصول على روابط المستمسكات الكاملة
  /// بناء الروابط يدوياً: https://.../customers/documents/filename.jpg
  List<String> get fullDocumentsUrls {
    if (documentsUrls == null || documentsUrls!.isEmpty) return [];

    return documentsUrls!.map((url) {
      // الرابط كامل
      if (url.startsWith('http')) return url;

      // المسار يحتوي على المجلد مسبقاً
      if (url.contains('/')) {
        return '$_supabaseBaseUrl/$url';
      }

      // اسم الملف فقط → أضف المجلد documents
      return '$_supabaseBaseUrl/documents/$url';
    }).toList();
  }

  /// التحقق من وجود صورة هوية/عميل (مطابق لـ id_doc_url)
  bool get hasIdDoc => idDocUrl != null && idDocUrl!.isNotEmpty;

  /// للتوافق مع الكود القديم
  bool get hasAvatar => hasIdDoc;

  /// التحقق من وجود مستمسكات
  bool get hasDocuments => documentsUrls != null && documentsUrls!.isNotEmpty;

  /// عدد المستمسكات
  int get documentsCount => documentsUrls?.length ?? 0;
}
