import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marsa_app/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:marsa_app/data/repositories/auth_repository.dart';
import 'package:marsa_app/data/models/auth_response.dart';
import 'package:marsa_app/data/models/user_model.dart';
import 'package:marsa_app/data/models/store_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository mockRepo;
  late AuthBloc bloc;

  setUp(() {
    mockRepo = MockAuthRepository();
    bloc = AuthBloc(repo: mockRepo);
  });

  tearDown(() => bloc.close());

  group('CheckAuth', () {
    test('emits [Loading, Authenticated] when auto login succeeds', () async {
      when(() => mockRepo.tryAutoLogin()).thenAnswer((_) async => true);

      final expected = [AuthLoading(), AuthAuthenticated()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(CheckAuth());
    });

    test('emits [Loading, Unauthenticated] when auto login fails', () async {
      when(() => mockRepo.tryAutoLogin()).thenAnswer((_) async => false);

      final expected = [AuthLoading(), AuthUnauthenticated()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(CheckAuth());
    });
  });

  group('LoginRequested', () {
    test('emits [Loading, Authenticated] on successful login with active store', () async {
      final authRes = AuthResponse(
        token: 'tok',
        user: UserModel(id: '1', storeId: 's1', username: 'u', fullName: 'U', role: 'owner', isActive: true),
        store: StoreModel(id: 's1', name: 'Store', isActive: true),
      );
      when(() => mockRepo.login(any(), any())).thenAnswer((_) async => authRes);

      final expected = [AuthLoading(), AuthAuthenticated()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoginRequested('user', 'pass'));
    });

    test('emits [Loading, Error] when store is inactive', () async {
      final authRes = AuthResponse(
        token: 'tok',
        user: UserModel(id: '1', storeId: 's1', username: 'u', fullName: 'U', role: 'owner', isActive: true),
        store: StoreModel(id: 's1', name: 'Store', isActive: false),
      );
      when(() => mockRepo.login(any(), any())).thenAnswer((_) async => authRes);

      final expected = [AuthLoading(), AuthError('هذا المحل غير نشط. يرجى التواصل مع الدعم.')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoginRequested('user', 'pass'));
    });

    test('emits [Loading, Error] on exception', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(Exception('خطأ في الاتصال'));

      final expected = [AuthLoading(), AuthError('خطأ في الاتصال')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(LoginRequested('user', 'pass'));
    });
  });

  group('ActivateRequested', () {
    test('emits [Loading, Authenticated] on success', () async {
      when(() => mockRepo.activate(any())).thenAnswer((_) async => AuthResponse(
        token: 'tok',
        user: UserModel(id: '1', storeId: 's1', username: 'u', fullName: 'U', role: 'owner', isActive: true),
        store: StoreModel(id: 's1', name: 'Store', isActive: true),
      ));

      final expected = [AuthLoading(), AuthAuthenticated()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(ActivateRequested('code123'));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.activate(any())).thenThrow(Exception('كود غير صالح'));

      final expected = [AuthLoading(), AuthError('كود غير صالح')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(ActivateRequested('bad_code'));
    });
  });

  group('RegisterTrialRequested', () {
    test('emits [Loading, Authenticated] on success', () async {
      when(() => mockRepo.registerTrial(any())).thenAnswer((_) async => AuthResponse(
        token: 'tok',
        user: UserModel(id: '1', storeId: 's1', username: 'u', fullName: 'U', role: 'owner', isActive: true),
        store: StoreModel(id: 's1', name: 'Store', isActive: true),
      ));

      final expected = [AuthLoading(), AuthAuthenticated()];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(RegisterTrialRequested({'name': 'Test'}));
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => mockRepo.registerTrial(any())).thenThrow(Exception('فشل'));

      final expected = [AuthLoading(), AuthError('فشل')];
      expect(bloc.stream, emitsInOrder(expected));
      bloc.add(RegisterTrialRequested({'name': 'Test'}));
    });
  });

  group('LogoutRequested', () {
    test('emits [Unauthenticated]', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      expect(bloc.stream, emits(AuthUnauthenticated()));
      bloc.add(LogoutRequested());
    });
  });
}
