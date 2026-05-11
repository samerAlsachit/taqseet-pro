class UserModel {
  final String id;
  final String storeId;
  final String username;
  final String fullName;
  final String? phone;
  final String? email;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.storeId,
    required this.username,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    storeId: json['store_id']?.toString() ?? '',
    username: json['username'] ?? '',
    fullName: json['full_name'] ?? '',
    phone: json['phone'],
    email: json['email'],
    role: json['role'] ?? 'store_owner',
    isActive: json['is_active'] ?? true,
  );
}
