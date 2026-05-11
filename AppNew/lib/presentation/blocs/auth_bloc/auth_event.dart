part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuth extends AuthEvent {}
class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  LoginRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}
class ActivateRequested extends AuthEvent {
  final String code;
  ActivateRequested(this.code);
  @override
  List<Object?> get props => [code];
}
class RegisterTrialRequested extends AuthEvent {
  final Map<String, dynamic> data;
  RegisterTrialRequested(this.data);
}
class LogoutRequested extends AuthEvent {}
