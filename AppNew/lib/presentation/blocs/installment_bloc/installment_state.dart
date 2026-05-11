part of 'installment_bloc.dart';

sealed class InstallmentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InstallmentInitial extends InstallmentState {}
class InstallmentLoading extends InstallmentState {}
class InstallmentLoaded extends InstallmentState {
  final List<InstallmentModel> installments;
  InstallmentLoaded({this.installments = const []});
}
class InstallmentDetailLoaded extends InstallmentState {
  final InstallmentModel installment;
  final List<ScheduleModel> schedules;
  final List<PaymentModel> payments;
  InstallmentDetailLoaded({required this.installment, this.schedules = const [], this.payments = const []});
}
class InstallmentError extends InstallmentState {
  final String message;
  InstallmentError(this.message);
}
