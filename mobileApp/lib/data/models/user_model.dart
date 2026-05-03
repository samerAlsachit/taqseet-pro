class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String role;
  final String? storeId;
  final bool canDelete;
  final bool canEdit;
  final bool canViewReports;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.role,
    this.storeId,
    this.canDelete = false,
    this.canEdit = false,
    this.canViewReports = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      role: json['role']?.toString() ?? 'user',
      storeId: json['store_id']?.toString(),
      canDelete: json['can_delete'] == true || json['can_delete'] == 1,
      canEdit: json['can_edit'] == true || json['can_edit'] == 1,
      canViewReports: json['can_view_reports'] == true || json['can_view_reports'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'store_id': storeId,
      'can_delete': canDelete,
      'can_edit': canEdit,
      'can_view_reports': canViewReports,
    };
  }
}
