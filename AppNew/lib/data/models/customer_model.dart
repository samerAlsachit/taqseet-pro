class CustomerModel {
  final String id;
  final String storeId;
  final String fullName;
  final String? phone;
  final String? phoneAlt;
  final String? nationalId;
  final String? address;
  final String? notes;
  final String? idDocUrl;
  final List<String> extraDocs;
  final String? imageUrl;

  CustomerModel({
    required this.id,
    required this.storeId,
    required this.fullName,
    this.phone,
    this.phoneAlt,
    this.nationalId,
    this.address,
    this.notes,
    this.idDocUrl,
    this.extraDocs = const [],
    this.imageUrl,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    id: json['id']?.toString() ?? '',
    storeId: json['store_id']?.toString() ?? '',
    fullName: json['full_name'] ?? '',
    phone: json['phone'],
    phoneAlt: json['phone_alt'],
    nationalId: json['national_id'],
    address: json['address'],
    notes: json['notes'],
    idDocUrl: json['id_doc_url'],
    extraDocs: (json['extra_docs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    imageUrl: json['image_url'],
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'phone_alt': phoneAlt,
    'national_id': nationalId,
    'address': address,
    'notes': notes,
    'id_doc_url': idDocUrl,
    'extra_docs': extraDocs,
    'image_url': imageUrl,
  };
}
