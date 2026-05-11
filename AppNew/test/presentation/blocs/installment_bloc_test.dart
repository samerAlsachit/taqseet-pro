import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marsa_app/presentation/blocs/installment_bloc/installment_bloc.dart';
import 'package:marsa_app/data/repositories/installment_repository.dart';
import 'package:marsa_app/data/models/installment_model.dart';
import 'package:marsa_app/data/models/payment_model.dart';

class MockInstallmentRepository extends Mock implements InstallmentRepository {}

void main() {
  late InstallmentRepository mockRepo;
  late InstallmentBloc bloc;

  setUp(() {
    mockRepo = MockInstallmentRepository();
    bloc = InstallmentBloc(repo: mockRepo);
  });

  tearDown(() => bloc.close());

  group('LoadInstallments', () {
    test('emits [Loading, Loaded] on success', () async {
      final list = [
        InstallmentModel(
          id: '1', storeId: 's1', customerId: 'c1',
          totalPrice: 1000, downPayment: 100, financedAmount: 900,
          remainingAmount: 900, totalPaid: 0, currency: 'IQD',
          frequency: 'monthly', status: 'active',
          startDate: DateTime(2026), installmentAmount: 100,
          installmentsCount: 9, createdAt: DateTime(2026),
        ),
      ];
      when(() => mockRepo.getAll(search: any(named: 'search'), status: any(named: 'status')))
          .thenAnswer((_) async => list);

      final expected = [InstallmentLoading(), InstallmentLoaded(installments: list)];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadInstallments());
    });

    test('emits [Loading, Loaded] with filters', () async {
      when(() => mockRepo.getAll(search: 'test', status: 'active'))
          .thenAnswer((_) async => []);

      final expected = [isA<InstallmentLoading>(), isA<InstallmentLoaded>()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadInstallments(search: 'test', status: 'active'));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.getAll(search: any(named: 'search'), status: any(named: 'status')))
          .thenThrow(Exception('فشل'));

      final expected = [InstallmentLoading(), InstallmentError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadInstallments());
    });
  });

  group('LoadInstallmentDetail', () {
    test('emits [Loading, DetailLoaded] on success', () async {
      final inst = InstallmentModel(
        id: '1', storeId: 's1', customerId: 'c1',
        totalPrice: 1000, downPayment: 100, financedAmount: 900,
        remainingAmount: 900, totalPaid: 0, currency: 'IQD',
        frequency: 'monthly', status: 'active',
        startDate: DateTime(2026), installmentAmount: 100,
        installmentsCount: 9, createdAt: DateTime(2026),
      );
      final schedules = [ScheduleModel(id: 's1', planId: '1', installmentNo: 1, dueDate: DateTime(2026), amount: 100, status: 'pending')];
      final payments = [PaymentModel(id: 'p1', planId: '1', storeId: 's1', amountPaid: 100, paymentDate: DateTime(2026), isEarly: false, currency: 'IQD')];

      when(() => mockRepo.getById('1')).thenAnswer((_) async => inst);
      when(() => mockRepo.getSchedules('1')).thenAnswer((_) async => schedules);
      when(() => mockRepo.getPayments('1')).thenAnswer((_) async => payments);

      final expected = [InstallmentLoading(), InstallmentDetailLoaded(installment: inst, schedules: schedules, payments: payments)];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadInstallmentDetail('1'));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.getById('1')).thenThrow(Exception('فشل'));

      final expected = [InstallmentLoading(), InstallmentError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadInstallmentDetail('1'));
    });
  });

  group('CreateInstallment', () {
    test('triggers reload on success', () async {
      when(() => mockRepo.create(any())).thenAnswer((_) async => InstallmentModel(
        id: '1', storeId: 's1', customerId: 'c1',
        totalPrice: 1000, downPayment: 100, financedAmount: 900,
        remainingAmount: 900, totalPaid: 0, currency: 'IQD',
        frequency: 'monthly', status: 'active',
        startDate: DateTime(2026), installmentAmount: 100,
        installmentsCount: 9, createdAt: DateTime(2026),
      ));
      when(() => mockRepo.getAll(search: any(named: 'search'), status: any(named: 'status')))
          .thenAnswer((_) async => []);

      expect(bloc.stream, emitsInOrder([isA<InstallmentLoading>(), isA<InstallmentLoaded>()]));
      bloc.add(CreateInstallment({'customer_id': 'c1'}));
    });

    test('emits Error on failure', () async {
      when(() => mockRepo.create(any())).thenThrow(Exception('فشل'));

      expect(bloc.stream, emits(InstallmentError('فشل')));
      bloc.add(CreateInstallment({'customer_id': 'c1'}));
    });
  });
}
