part of 'product_bloc.dart';

sealed class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  ProductLoaded({this.products = const []});
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}
