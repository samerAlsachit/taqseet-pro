part of 'payment_bloc.dart';

sealed class PaymentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}
class PaymentLoading extends PaymentState {}
class PaymentSuccess extends PaymentState {}
class PaymentError extends PaymentState {
  final String message;
  PaymentError(this.message);
}
class ReceiptReady extends PaymentState {
  final String html;
  ReceiptReady({required this.html});
}
