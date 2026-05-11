part of 'payment_bloc.dart';

sealed class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreatePayment extends PaymentEvent {
  final Map<String, dynamic> data;
  CreatePayment(this.data);
}
class CreateFullSettlement extends PaymentEvent {
  final Map<String, dynamic> data;
  CreateFullSettlement(this.data);
}
class PrintReceipt extends PaymentEvent {
  final String receiptNumber;
  PrintReceipt(this.receiptNumber);
}
