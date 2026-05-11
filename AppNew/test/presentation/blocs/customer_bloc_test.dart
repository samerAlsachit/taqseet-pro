import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marsa_app/presentation/blocs/customer_bloc/customer_bloc.dart';
import 'package:marsa_app/data/repositories/customer_repository.dart';
import 'package:marsa_app/data/models/customer_model.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late CustomerRepository mockRepo;
  late CustomerBloc bloc;

  setUp(() {
    mockRepo = MockCustomerRepository();
    bloc = CustomerBloc(repo: mockRepo);
  });

  tearDown(() => bloc.close());

  group('LoadCustomers', () {
    test('emits [Loading, Loaded] on success', () async {
      final customers = [
        CustomerModel(id: '1', storeId: 's1', fullName: 'أحمد'),
        CustomerModel(id: '2', storeId: 's1', fullName: 'محمد'),
      ];
      when(() => mockRepo.getAll(search: any(named: 'search')))
          .thenAnswer((_) async => customers);

      final expected = [CustomerLoading(), CustomerLoaded(customers: customers)];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadCustomers());
    });

    test('emits [Loading, Loaded] with search param', () async {
      when(() => mockRepo.getAll(search: 'أحمد'))
          .thenAnswer((_) async => [CustomerModel(id: '1', storeId: 's1', fullName: 'أحمد')]);

      final expected = [isA<CustomerLoading>(), isA<CustomerLoaded>()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadCustomers(search: 'أحمد'));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.getAll(search: any(named: 'search')))
          .thenThrow(Exception('فشل'));

      final expected = [CustomerLoading(), CustomerError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadCustomers());
    });
  });

  group('CreateCustomer', () {
    test('triggers reload on success', () async {
      when(() => mockRepo.create(any())).thenAnswer((_) async => CustomerModel(id: '1', storeId: 's1', fullName: 'جديد'));
      when(() => mockRepo.getAll(search: any(named: 'search'))).thenAnswer((_) async => []);

      expect(bloc.stream, emitsInOrder([isA<CustomerLoading>(), isA<CustomerLoaded>()]));
      bloc.add(CreateCustomer({'full_name': 'جديد'}));
    });

    test('emits Error on failure', () async {
      when(() => mockRepo.create(any())).thenThrow(Exception('فشل الإضافة'));

      expect(bloc.stream, emits(CustomerError('فشل الإضافة')));
      bloc.add(CreateCustomer({'full_name': 'جديد'}));
    });
  });

  group('UpdateCustomer', () {
    test('triggers reload on success', () async {
      when(() => mockRepo.update(any(), any())).thenAnswer((_) async => CustomerModel(id: '1', storeId: 's1', fullName: 'محدث'));
      when(() => mockRepo.getAll(search: any(named: 'search'))).thenAnswer((_) async => []);

      expect(bloc.stream, emitsInOrder([isA<CustomerLoading>(), isA<CustomerLoaded>()]));
      bloc.add(UpdateCustomer('1', {'full_name': 'محدث'}));
    });

    test('emits Error on failure', () async {
      when(() => mockRepo.update(any(), any())).thenThrow(Exception('فشل التحديث'));

      expect(bloc.stream, emits(CustomerError('فشل التحديث')));
      bloc.add(UpdateCustomer('1', {'full_name': 'محدث'}));
    });
  });

  group('DeleteCustomer', () {
    test('triggers reload on success', () async {
      when(() => mockRepo.delete(any())).thenAnswer((_) async {});
      when(() => mockRepo.getAll(search: any(named: 'search'))).thenAnswer((_) async => []);

      expect(bloc.stream, emitsInOrder([isA<CustomerLoading>(), isA<CustomerLoaded>()]));
      bloc.add(DeleteCustomer('1'));
    });

    test('emits Error on failure', () async {
      when(() => mockRepo.delete(any())).thenThrow(Exception('فشل الحذف'));

      expect(bloc.stream, emits(CustomerError('فشل الحذف')));
      bloc.add(DeleteCustomer('1'));
    });
  });
}
