import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc({AuthRepository? repo}) : _repo = repo ?? AuthRepository(), super(AuthInitial()) {
    on<CheckAuth>((event, emit) async {
      emit(AuthLoading());
      final loggedIn = await _repo.tryAutoLogin();
      if (loggedIn) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final res = await _repo.login(event.username, event.password);
        if (res.store.isActive) {
          emit(AuthAuthenticated());
        } else {
          emit(AuthError('هذا المحل غير نشط. يرجى التواصل مع الدعم.'));
        }
      } catch (e) {
        emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<ActivateRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _repo.activate(event.code);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<RegisterTrialRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _repo.registerTrial(event.data);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await _repo.logout();
      emit(AuthUnauthenticated());
    });
  }
}
