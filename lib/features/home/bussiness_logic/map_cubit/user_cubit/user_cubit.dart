import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uber_rider/features/home/bussiness_logic/map_cubit/user_cubit/user_state.dart';

import '../../../../../core/services/socket_service.dart';
import '../../../../../core/storage/secure_storage_helper.dart';
import '../../../data/repository/user_repository.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository userRepository;
  UserCubit({required this.userRepository}) : super(UserInitialState());

  Future<void> requestRide({
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropoffAddress,
    required double dropoffLatitude,
    required double dropoffLongitude,
  }) async {
    emit(RequestRideLoadingState());
    final result = await userRepository.login(data: {
      "pickupAddress": pickupAddress,
      "pickupLatitude": pickupLatitude,
      "pickupLongitude": pickupLongitude,
      "dropoffAddress": dropoffAddress,
      "dropoffLatitude": dropoffLatitude,
      "dropoffLongitude": dropoffLongitude,
      "vehicleType": "SUV",
      "paymentMethod": "cash"
    });
    result.fold(
      (failure) {
        emit(RequestRideErrorState(failure.message));
      },
      (rideRequestResponse) async {
        // Connect to socket after successful ride request
        final token = await SecureStorageHelper.getToken();
        final socketService = SocketService();
        socketService.connect(token: token);

        // Join the ride room
        socketService
            .emit('ride:join', {'rideId': rideRequestResponse.data.id});

        emit(RequestRideSuccessState(rideRequestResponse));
      },
    );
  }

  Future<void> rateRide({
    required String rideId,
    required int rating,
    required String review,
  }) async {
    emit(RateRideLoadingState());
    final result = await userRepository.rateRide(
      rideId: rideId,
      data: {
        "rating": rating,
        "review": review,
      },
    );
    result.fold(
      (failure) {
        emit(RateRideErrorState(failure.message));
      },
      (message) {
        emit(RateRideSuccessState(message));
      },
    );
  }
}
