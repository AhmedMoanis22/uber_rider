import '../data/model/auth_response_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class LoginLoadingState extends AuthState {}

class LoginSuccessState extends AuthState {
  final AuthResponse loginResponse;

  LoginSuccessState(this.loginResponse);
}

class LoginErrorState extends AuthState {
  final String message;

  LoginErrorState(this.message);
}
