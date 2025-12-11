import '../../../data/model/request_ride_model.dart';

abstract class UserState {}

class UserInitialState extends UserState {}

class RequestRideLoadingState extends UserState {}

class RequestRideSuccessState extends UserState {
  final RideRequestResponse rideRequestResponse;

  RequestRideSuccessState(this.rideRequestResponse);
}

class RequestRideErrorState extends UserState {
  final String errorMessage;

  RequestRideErrorState(this.errorMessage);
}

class RateRideLoadingState extends UserState {}

class RateRideSuccessState extends UserState {
  final String message;

  RateRideSuccessState(this.message);
}

class RateRideErrorState extends UserState {
  final String errorMessage;

  RateRideErrorState(this.errorMessage);
}
