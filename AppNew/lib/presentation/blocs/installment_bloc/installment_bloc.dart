import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/installment_repository.dart';
import '../../../data/models/installment_model.dart';
import '../../../data/models/payment_model.dart';

part 'installment_event.dart';
part 'installment_state.dart';

class InstallmentBloc extends Bloc<InstallmentEvent, InstallmentState> {
  final InstallmentRepository _repo;

  InstallmentBloc({InstallmentRepository? repo}) : _repo = repo ?? InstallmentRepository(), super(InstallmentInitial()) {
    on<LoadInstallments>((event, emit) async {
      emit(InstallmentLoading());
      try {
        final list = await _repo.getAll(search: event.search, status: event.status, customerId: event.customerId);
        emit(InstallmentLoaded(installments: list));
      } catch (e) {
        emit(InstallmentError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<LoadInstallmentDetail>((event, emit) async {
      emit(InstallmentLoading());
      try {
        final installment = await _repo.getById(event.id);
        final schedules = await _repo.getSchedules(event.id);
        final payments = await _repo.getPayments(event.id);
        emit(InstallmentDetailLoaded(installment: installment, schedules: schedules, payments: payments));
      } catch (e) {
        emit(InstallmentError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<CreateInstallment>((event, emit) async {
      try {
        await _repo.create(event.data);
        add(LoadInstallments());
      } catch (e) {
        emit(InstallmentError(e.toString().replaceFirst('Exception: ', '')));
      }
    });
  }
}
