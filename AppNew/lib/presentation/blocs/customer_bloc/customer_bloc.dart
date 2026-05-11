import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/models/customer_model.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _repo;

  CustomerBloc({CustomerRepository? repo}) : _repo = repo ?? CustomerRepository(), super(CustomerInitial()) {
    on<LoadCustomers>((event, emit) async {
      emit(CustomerLoading());
      try {
        final customers = await _repo.getAll(search: event.search);
        emit(CustomerLoaded(customers: customers));
      } catch (e) {
        emit(CustomerError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<CreateCustomer>((event, emit) async {
      try {
        await _repo.create(event.data);
        add(LoadCustomers());
      } catch (e) {
        emit(CustomerError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<UpdateCustomer>((event, emit) async {
      try {
        await _repo.update(event.id, event.data);
        add(LoadCustomers());
      } catch (e) {
        emit(CustomerError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<DeleteCustomer>((event, emit) async {
      try {
        await _repo.delete(event.id);
        add(LoadCustomers());
      } catch (e) {
        emit(CustomerError(e.toString().replaceFirst('Exception: ', '')));
      }
    });
  }
}
