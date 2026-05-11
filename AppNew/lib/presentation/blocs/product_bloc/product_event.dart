part of 'product_bloc.dart';

sealed class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final String? search;
  LoadProducts({this.search});
}
class CreateProduct extends ProductEvent {
  final Map<String, dynamic> data;
  CreateProduct(this.data);
}
class UpdateProduct extends ProductEvent {
  final String id;
  final Map<String, dynamic> data;
  UpdateProduct(this.id, this.data);
}
class DeleteProduct extends ProductEvent {
  final String id;
  DeleteProduct(this.id);
}
