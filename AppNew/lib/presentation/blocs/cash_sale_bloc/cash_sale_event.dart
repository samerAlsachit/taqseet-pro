part of 'cash_sale_bloc.dart';

sealed class CashSaleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateCashSale extends CashSaleEvent {
  final Map<String, dynamic> data;
  CreateCashSale(this.data);
}
