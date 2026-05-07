import 'dart:convert';
import '../../core/config/app_config.dart';

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
  final int activeInstallmentsCount; // From API summary

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
    this.activeInstallmentsCount = 0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Parse extra_docs which can be a JSON string or a list
    List<String> extraDocs = [];
    if (json['extra_docs'] != null) {
      if (json['extra_docs'] is List) {
        extraDocs =
            List<String>.from(json['extra_docs'].map((e) => e.toString()));
      } else if (json['extra_docs'] is String) {
        try {
          final decoded = jsonDecode(json['extra_docs']);
          if (decoded is List) {
            extraDocs = List<String>.from(decoded.map((e) => e.toString()));
          }
        } catch (_) {
          // If parsing fails, treat as single item if not empty
          if (json['extra_docs'].toString().isNotEmpty) {
            extraDocs = [json['extra_docs'].toString()];
          }
        }
      }
    }

    // Also check documents_urls from API
    if (extraDocs.isEmpty && json['documents_urls'] != null) {
      if (json['documents_urls'] is List) {
        extraDocs =
            List<String>.from(json['documents_urls'].map((e) => e.toString()));
      }
    }

    // Map extra_docs to document URLs (first 4 items)
    final idCardFrontUrl = extraDocs.isNotEmpty ? extraDocs[0] : null;
    final idCardBackUrl = extraDocs.length > 1 ? extraDocs[1] : null;
    final residenceFrontUrl = extraDocs.length > 2 ? extraDocs[2] : null;
    final residenceBackUrl = extraDocs.length > 3 ? extraDocs[3] : null;

    // Parse ID from multiple possible field names
    final String customerId = json['id']?.toString() ??
        json['customer_id']?.toString() ??
        json['user_id']?.toString() ??
        json['_id']?.toString() ??
        json['uuid']?.toString() ??
        '';

    return CustomerModel(
      id: customerId,
      fullName: json['full_name']?.toString() ??
          json['name']?.toString() ??
          'غير معروف',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      idNumber:
          json['id_number']?.toString() ?? json['national_id']?.toString(),
      avatarUrl:
          json['avatar_url']?.toString() ?? json['id_doc_url']?.toString(),
      idCardFrontUrl: json['id_card_front_url']?.toString() ?? idCardFrontUrl,
      idCardBackUrl: json['id_card_back_url']?.toString() ?? idCardBackUrl,
      residenceFrontUrl:
          json['residence_front_url']?.toString() ?? residenceFrontUrl,
      residenceBackUrl:
          json['residence_back_url']?.toString() ?? residenceBackUrl,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isSynced: json['is_synced'] == true || json['is_synced'] == 1,
      activeInstallmentsCount: json['active_installments_count'] ??
          json['active_installments'] ??
          json['installments_count'] ??
          0,
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
    int? activeInstallmentsCount,
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
      activeInstallmentsCount:
          activeInstallmentsCount ?? this.activeInstallmentsCount,
    );
  }

  /// Get the profile image URL with unified naming pattern
  /// Format: ${id}_profile.jpg with cache-busting
  String? get profileImageUrl {
    if (id.isEmpty) {
      print('⚠️ [CustomerModel] Empty customer ID, cannot build image URL');
      return null;
    }

    // Sanitize ID: remove spaces and special characters
    final sanitizedId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '${sanitizedId}_profile.jpg';

    // Build URL with cache-busting parameter
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = AppConfig.buildStorageUrlWithFolder('avatars', fileName);

    print('🔗 [CustomerModel] Building profile image URL:');
    print('   Customer ID: $id (sanitized: $sanitizedId)');
    print('   File name: $fileName');
    print('   Full URL: $url?v=$timestamp');

    return '$url?v=$timestamp';
  }
}
