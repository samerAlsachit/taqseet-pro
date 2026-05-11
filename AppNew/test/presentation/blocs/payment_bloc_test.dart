import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marsa_app/presentation/blocs/payment_bloc/payment_bloc.dart';
import 'package:marsa_app/data/repositories/payment_repository.dart';
import 'package:marsa_app/data/models/payment_model.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late PaymentRepository mockRepo;
  late PaymentBloc bloc;

  setUp(() {
    mockRepo = MockPaymentRepository();
    bloc = PaymentBloc(repo: mockRepo);
  });

  tearDown(() => bloc.close());

  group('CreatePayment', () {
    test('emits [Loading, Success] on success', () async {
      when(() => mockRepo.create(any())).thenAnswer((_) async => PaymentModel(
        id: '1', planId: 'p1', storeId: 's1', amountPaid: 500,
        paymentDate: DateTime(2026), isEarly: false, currency: 'IQD',
      ));

      final expected = [PaymentLoading(), PaymentSuccess()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(CreatePayment({'plan_id': 'p1', 'amount_paid': 500}));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.create(any())).thenThrow(Exception('فشل'));

      final expected = [PaymentLoading(), PaymentError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(CreatePayment({'plan_id': 'p1'}));
    });
  });

  group('PrintReceipt', () {
    test('emits ReceiptReady on success', () async {
      when(() => mockRepo.getReceiptHtml('RCP-001'))
          .thenAnswer((_) async => '<html>receipt</html>');

      expect(bloc.stream, emits(ReceiptReady(html: '<html>receipt</html>')));
      bloc.add(PrintReceipt('RCP-001'));
    });

    test('emits PaymentError on failure', () async {
      when(() => mockRepo.getReceiptHtml('RCP-001'))
          .thenThrow(Exception('فشل'));

      expect(bloc.stream, emits(PaymentError('فشل')));
      bloc.add(PrintReceipt('RCP-001'));
    });
  });
}
