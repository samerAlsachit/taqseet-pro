import 'user_model.dart';
import 'store_model.dart';

class AuthResponse {
  final String token;
  final UserModel user;
  final StoreModel store;

  AuthResponse({required this.token, required this.user, required this.store});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] ?? '',
    user: UserModel.fromJson(json['user'] ?? {}),
    store: StoreModel.fromJson(json['store'] ?? {}),
  );
}
