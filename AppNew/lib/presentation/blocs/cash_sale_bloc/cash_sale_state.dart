part of 'cash_sale_bloc.dart';

sealed class CashSaleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CashSaleInitial extends CashSaleState {}
class CashSaleLoading extends CashSaleState {}
class CashSaleSuccess extends CashSaleState {}
class CashSaleError extends CashSaleState {
  final String message;
  CashSaleError(this.message);
}
