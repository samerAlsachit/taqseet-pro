import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/cash_sale_repository.dart';

part 'cash_sale_event.dart';
part 'cash_sale_state.dart';

class CashSaleBloc extends Bloc<CashSaleEvent, CashSaleState> {
  final CashSaleRepository _repo;

  CashSaleBloc({CashSaleRepository? repo}) : _repo = repo ?? CashSaleRepository(), super(CashSaleInitial()) {
    on<CreateCashSale>((event, emit) async {
      emit(CashSaleLoading());
      try {
        await _repo.create(event.data);
        emit(CashSaleSuccess());
      } catch (e) {
        emit(CashSaleError(e.toString().replaceFirst('Exception: ', '')));
      }
    });
  }
}
