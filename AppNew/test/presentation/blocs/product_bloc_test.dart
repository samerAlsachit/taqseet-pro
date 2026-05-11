import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marsa_app/presentation/blocs/product_bloc/product_bloc.dart';
import 'package:marsa_app/data/repositories/product_repository.dart';
import 'package:marsa_app/data/models/product_model.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late ProductRepository mockRepo;
  late ProductBloc bloc;

  setUp(() {
    mockRepo = MockProductRepository();
    bloc = ProductBloc(repo: mockRepo);
  });

  tearDown(() => bloc.close());

  group('LoadProducts', () {
    test('emits [Loading, Loaded] on success', () async {
      final products = [
        ProductModel(id: '1', storeId: 's1', name: 'منتج أ', quantity: 10),
        ProductModel(id: '2', storeId: 's1', name: 'منتج ب', quantity: 5),
      ];
      when(() => mockRepo.getAll(search: any(named: 'search')))
          .thenAnswer((_) async => products);

      final expected = [ProductLoading(), ProductLoaded(products: products)];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadProducts());
    });

    test('emits [Loading, Loaded] with search', () async {
      when(() => mockRepo.getAll(search: 'أ')).thenAnswer((_) async => []);
      final expected = [isA<ProductLoading>(), isA<ProductLoaded>()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadProducts(search: 'أ'));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.getAll(search: any(named: 'search')))
          .thenThrow(Exception('فشل'));

      final expected = [ProductLoading(), ProductError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadProducts());
    });
  });

  group('CreateProduct', () {
    test('triggers reload on success', () async {
      when(() => mockRepo.create(any())).thenAnswer((_) async => ProductModel(id: '1', storeId: 's1', name: 'جديد', quantity: 1));
      when(() => mockRepo.getAll(search: any(named: 'search'))).thenAnswer((_) async => []);

      expect(bloc.stream, emitsInOrder([isA<ProductLoading>(), isA<ProductLoaded>()]));
      bloc.add(CreateProduct({'name': 'جديد'}));
    });

    test('emits Error on failure', () async {
      when(() => mockRepo.create(any())).thenThrow(Exception('فشل'));

      expect(bloc.stream, emits(ProductError('فشل')));
      bloc.add(CreateProduct({'name': 'جديد'}));
    });
  });

  group('UpdateProduct', () {
    test('triggers reload on success', () async {
      when(() => mockRepo.update(any(), any())).thenAnswer((_) async => ProductModel(id: '1', storeId: 's1', name: 'محدث', quantity: 1));
      when(() => mockRepo.getAll(search: any(named: 'search'))).thenAnswer((_) async => []);

      expect(bloc.stream, emitsInOrder([isA<ProductLoading>(), isA<ProductLoaded>()]));
      bloc.add(UpdateProduct('1', {'name': 'محدث'}));
    });

    test('emits Error on failure', () async {
      when(() => mockRepo.update(any(), any())).thenThrow(Exception('فشل'));

      expect(bloc.stream, emits(ProductError('فشل')));
      bloc.add(UpdateProduct('1', {'name': 'محدث'}));
    });
  });

  group('DeleteProduct', () {
    test('triggers reload on success', () async {
      when(() => mockRepo.delete(any())).thenAnswer((_) async {});
      when(() => mockRepo.getAll(search: any(named: 'search'))).thenAnswer((_) async => []);

      expect(bloc.stream, emitsInOrder([isA<ProductLoading>(), isA<ProductLoaded>()]));
      bloc.add(DeleteProduct('1'));
    });

    test('emits Error on failure', () async {
      when(() => mockRepo.delete(any())).thenThrow(Exception('فشل'));

      expect(bloc.stream, emits(ProductError('فشل')));
      bloc.add(DeleteProduct('1'));
    });
  });
}
