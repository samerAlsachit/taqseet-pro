import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marsa_app/presentation/blocs/cash_sale_bloc/cash_sale_bloc.dart';
import 'package:marsa_app/data/repositories/cash_sale_repository.dart';

class MockCashSaleRepository extends Mock implements CashSaleRepository {}

void main() {
  late CashSaleRepository mockRepo;
  late CashSaleBloc bloc;

  setUp(() {
    mockRepo = MockCashSaleRepository();
    bloc = CashSaleBloc(repo: mockRepo);
  });

  tearDown(() => bloc.close());

  group('CreateCashSale', () {
    test('emits [Loading, Success] on success', () async {
      when(() => mockRepo.create(any())).thenAnswer((_) async => {'id': '1'});

      final expected = [CashSaleLoading(), CashSaleSuccess()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(CreateCashSale({'customer_name': 'عميل', 'total_amount': 500}));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.create(any())).thenThrow(Exception('فشل'));

      final expected = [CashSaleLoading(), CashSaleError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(CreateCashSale({'customer_name': 'عميل'}));
    });
  });
}
