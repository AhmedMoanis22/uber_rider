import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../data_source/user_remote_data_source.dart';
import '../model/active_ride_model.dart';
import '../model/nearby_driver_model.dart';
import '../model/request_ride_model.dart';

class UserRepository {
  final UserRemoteDataSource userRemoteDataSource;

  UserRepository({required this.userRemoteDataSource});

  Future<Either<Failure, RideRequestResponse>> login({
    required Map<String, dynamic> data,
  }) async {
    try {
      final remoteData = await userRemoteDataSource.requestRide(
        data: data,
      );

      return Right(remoteData);
    } catch (e) {
      final apiError = ErrorHandler.handle(e);
      return Left(ServerFailure(apiError.getAllErrorMessages()));
    }
  }

  Future<Either<Failure, List<DriverData>>> getNearbyDrivers({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final remoteData = await userRemoteDataSource.getNearbyDrivers(
        latitude: latitude,
        longitude: longitude,
      );

      return Right(remoteData);
    } catch (e) {
      final apiError = ErrorHandler.handle(e);
      return Left(ServerFailure(apiError.getAllErrorMessages()));
    }
  }

  Future<Either<Failure, ActiveRideModel>> getActiveRide() async {
    try {
      final response = await userRemoteDataSource.getActiveRide();
      return Right(response);
    } catch (e) {
      print('Error fetching active ride: $e');
      return const Left(ServerFailure('Error fetching active ride'));
    }
  }

  Future<Either<Failure, String>> rateRide({
    required String rideId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await userRemoteDataSource.rateRide(
        rideId: rideId,
        data: data,
      );
      return Right(response);
    } catch (e) {
      final apiError = ErrorHandler.handle(e);
      return Left(ServerFailure(apiError.getAllErrorMessages()));
    }
  }
}
