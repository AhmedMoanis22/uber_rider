import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/model/active_ride_model.dart';

abstract class RideTrackingState extends Equatable {
  const RideTrackingState();

  @override
  List<Object?> get props => [];
}

class RideTrackingInitial extends RideTrackingState {}

class RideWaitingForDriver extends RideTrackingState {
  final String message;

  const RideWaitingForDriver(this.message);

  @override
  List<Object?> get props => [message];
}

class DriverAccepted extends RideTrackingState {
  final String driverName;
  final String driverPhone;
  final String vehicleInfo;
  final String plateNumber;
  final double driverRating;
  final LatLng driverLocation;

  const DriverAccepted({
    required this.driverName,
    required this.driverPhone,
    required this.vehicleInfo,
    required this.plateNumber,
    required this.driverRating,
    required this.driverLocation,
  });

  @override
  List<Object?> get props => [
        driverName,
        driverPhone,
        vehicleInfo,
        plateNumber,
        driverRating,
        driverLocation,
      ];
}

class DriverLocationUpdated extends RideTrackingState {
  final LatLng driverLocation;
  final double rotation;
  final List<LatLng> driverPath;
  final String driverName;
  final String driverPhone;
  final String vehicleInfo;
  final String plateNumber;
  final double driverRating;
  final LatLng? destination; // Current destination (pickup or dropoff)
  final String destinationType; // 'pickup' or 'dropoff'
  final String rideStatus; // Current ride status

  const DriverLocationUpdated({
    required this.driverLocation,
    required this.rotation,
    required this.driverPath,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleInfo,
    required this.plateNumber,
    required this.driverRating,
    this.destination,
    required this.destinationType,
    required this.rideStatus,
  });

  @override
  List<Object?> get props => [
        driverLocation,
        rotation,
        driverPath,
        driverName,
        driverPhone,
        vehicleInfo,
        plateNumber,
        driverRating,
        destination,
        destinationType,
        rideStatus,
      ];
}

class RideStatusUpdated extends RideTrackingState {
  final String status;

  const RideStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

class RideCompleted extends RideTrackingState {
  final String rideId;

  const RideCompleted(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class ShowRatingDialog extends RideTrackingState {
  final String rideId;
  final double finalFare;
  final double actualDistance;
  final int actualDuration;

  const ShowRatingDialog({
    required this.rideId,
    required this.finalFare,
    required this.actualDistance,
    required this.actualDuration,
  });

  @override
  List<Object?> get props =>
      [rideId, finalFare, actualDistance, actualDuration];
}

class RideTrackingError extends RideTrackingState {
  final String message;

  const RideTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}

class ActiveRideLoaing extends RideTrackingState {}

class ActiveRideLoaded extends RideTrackingState {
  final ActiveRideModel activeRideData;

  const ActiveRideLoaded(this.activeRideData);

  @override
  List<Object?> get props => [activeRideData];
}

class ActiveRideError extends RideTrackingState {
  final String message;

  const ActiveRideError(this.message);

  @override
  List<Object?> get props => [message];
}
