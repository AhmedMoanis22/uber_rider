import '../../../../core/network/api_constant.dart';
import '../../../../core/network/api_services.dart';
import '../model/auth_response_model.dart';

class AuthRemoteDataSource {
  final ApiServices apiServices;
  AuthRemoteDataSource({required this.apiServices});

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await apiServices.postData(
      urll: ApiConstance.loginEndpoint,
      data: {
        'email': email,
        'password': password,
      },
    );

    return AuthResponse.fromJson(response.data);
  }
}
