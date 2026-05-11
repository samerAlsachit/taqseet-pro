import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/models/installment_model.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repo;

  DashboardBloc({DashboardRepository? repo}) : _repo = repo ?? DashboardRepository(), super(DashboardInitial()) {
    on<LoadDashboard>((event, emit) async {
      emit(DashboardLoading());
      try {
        final stats = await _repo.getStats();
        final recent = await _repo.getRecentInstallments();
        emit(DashboardLoaded(stats: stats, recentInstallments: recent));
      } catch (e) {
        emit(DashboardError(e.toString().replaceFirst('Exception: ', '')));
      }
    });
  }
}
