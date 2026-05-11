part of 'customer_bloc.dart';

sealed class CustomerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final String? search;
  LoadCustomers({this.search});
  @override
  List<Object?> get props => [search];
}
class CreateCustomer extends CustomerEvent {
  final Map<String, dynamic> data;
  CreateCustomer(this.data);
}
class UpdateCustomer extends CustomerEvent {
  final String id;
  final Map<String, dynamic> data;
  UpdateCustomer(this.id, this.data);
}
class DeleteCustomer extends CustomerEvent {
  final String id;
  DeleteCustomer(this.id);
}
