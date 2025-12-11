import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_rider/features/auth/bussiness_logic/auth_state.dart';

import '../data/repository/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(LoginLoadingState());
    final result = await authRepository.login(email: email, password: password);
    result.fold(
      (failure) {
        emit(LoginErrorState(failure.message));
      },
      (loginResponse) {
        emit(LoginSuccessState(loginResponse));
      },
    );
  }
}
