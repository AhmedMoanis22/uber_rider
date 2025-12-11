import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../data_source/auth_remote_data_source.dart';
import '../model/auth_response_model.dart';

class AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;

  AuthRepository({required this.authRemoteDataSource});

  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final remoteData = await authRemoteDataSource.login(
        email: email,
        password: password,
      );

      return Right(remoteData);
    } catch (e) {
      final apiError = ErrorHandler.handle(e);
      return Left(ServerFailure(apiError.getAllErrorMessages()));
    }
  }
}
