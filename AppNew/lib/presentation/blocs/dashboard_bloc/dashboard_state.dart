part of 'dashboard_bloc.dart';

sealed class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardStats? stats;
  final List<InstallmentModel> recentInstallments;
  DashboardLoaded({this.stats, this.recentInstallments = const []});
  @override
  List<Object?> get props => [stats, recentInstallments];
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
