import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marsa_app/presentation/blocs/dashboard_bloc/dashboard_bloc.dart';
import 'package:marsa_app/data/repositories/dashboard_repository.dart';
import 'package:marsa_app/data/models/dashboard_stats.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late DashboardRepository mockRepo;
  late DashboardBloc bloc;

  setUp(() {
    mockRepo = MockDashboardRepository();
    bloc = DashboardBloc(repo: mockRepo);
  });

  tearDown(() => bloc.close());

  group('LoadDashboard', () {
    test('emits [Loading, Loaded] on success', () async {
      final stats = DashboardStats(
        totalCustomers: 10,
        activeInstallments: 5,
        dueToday: {'IQD': 500},
        overdue: {'IQD': 200},
        todayCollection: {'IQD': 300},
      );
      when(() => mockRepo.getStats()).thenAnswer((_) async => stats);
      when(() => mockRepo.getRecentInstallments()).thenAnswer((_) async => []);

      final expected = [DashboardLoading(), DashboardLoaded(stats: stats, recentInstallments: [])];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadDashboard());
    });

    test('emits [Loading, Loaded] with null stats', () async {
      when(() => mockRepo.getStats()).thenAnswer((_) async => null);
      when(() => mockRepo.getRecentInstallments()).thenAnswer((_) async => []);

      final expected = [DashboardLoading(), DashboardLoaded(stats: null, recentInstallments: [])];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadDashboard());
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.getStats()).thenThrow(Exception('فشل'));

      final expected = [DashboardLoading(), DashboardError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoadDashboard());
    });
  });
}
