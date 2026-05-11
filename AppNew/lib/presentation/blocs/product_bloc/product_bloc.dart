import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/product_model.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repo;

  ProductBloc({ProductRepository? repo}) : _repo = repo ?? ProductRepository(), super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await _repo.getAll(search: event.search);
        emit(ProductLoaded(products: products));
      } catch (e) {
        emit(ProductError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<CreateProduct>((event, emit) async {
      try {
        await _repo.create(event.data);
        add(LoadProducts());
      } catch (e) {
        emit(ProductError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<UpdateProduct>((event, emit) async {
      try {
        await _repo.update(event.id, event.data);
        add(LoadProducts());
      } catch (e) {
        emit(ProductError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<DeleteProduct>((event, emit) async {
      try {
        await _repo.delete(event.id);
        add(LoadProducts());
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });
  }
}
