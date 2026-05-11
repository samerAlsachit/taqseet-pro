part of 'installment_bloc.dart';

sealed class InstallmentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadInstallments extends InstallmentEvent {
  final String? search;
  final String? status;
  final String? customerId;
  LoadInstallments({this.search, this.status, this.customerId});
}
class LoadInstallmentDetail extends InstallmentEvent {
  final String id;
  LoadInstallmentDetail(this.id);
}
class CreateInstallment extends InstallmentEvent {
  final Map<String, dynamic> data;
  CreateInstallment(this.data);
}
