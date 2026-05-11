part of 'customer_bloc.dart';

sealed class CustomerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}
class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  CustomerLoaded({this.customers = const []});
  @override
  List<Object?> get props => [customers];
}
class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
  @override
  List<Object?> get props => [message];
}
