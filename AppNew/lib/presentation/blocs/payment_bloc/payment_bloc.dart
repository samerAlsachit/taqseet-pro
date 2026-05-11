import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/payment_repository.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repo;

  PaymentBloc({PaymentRepository? repo}) : _repo = repo ?? PaymentRepository(), super(PaymentInitial()) {
    on<CreatePayment>((event, emit) async {
      emit(PaymentLoading());
      try {
        await _repo.create(event.data);
        emit(PaymentSuccess());
      } catch (e) {
        emit(PaymentError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<CreateFullSettlement>((event, emit) async {
      emit(PaymentLoading());
      try {
        await _repo.fullSettlement(event.data);
        emit(PaymentSuccess());
      } catch (e) {
        emit(PaymentError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<PrintReceipt>((event, emit) async {
      try {
        final html = await _repo.getReceiptHtml(event.receiptNumber);
        emit(ReceiptReady(html: html));
      } catch (e) {
        emit(PaymentError(e.toString().replaceFirst('Exception: ', '')));
      }
    });
  }
}
