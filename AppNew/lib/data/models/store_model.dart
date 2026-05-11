class StoreModel {
  final String id;
  final String name;
  final String? ownerName;
  final String? phone;
  final String? address;
  final String? city;
  final String? logoUrl;
  final bool isActive;
  final int? trialDaysLeft;

  StoreModel({
    required this.id,
    required this.name,
    this.ownerName,
    this.phone,
    this.address,
    this.city,
    this.logoUrl,
    required this.isActive,
    this.trialDaysLeft,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
    id: json['id']?.toString() ?? '',
    name: json['name'] ?? '',
    ownerName: json['owner_name'],
    phone: json['phone'],
    address: json['address'],
    city: json['city'],
    logoUrl: json['logo_url'],
    isActive: json['is_active'] ?? true,
    trialDaysLeft: json['trial_days_remaining'],
  );
}
