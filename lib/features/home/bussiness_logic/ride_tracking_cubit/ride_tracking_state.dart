import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/model/active_ride_model.dart';

/// Base class for all ride tracking states
abstract class RideTrackingState extends Equatable {
  const RideTrackingState();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// Initial and Waiting States
// ============================================================================

/// Initial state when no ride is active
class RideTrackingInitial extends RideTrackingState {}

/// State when waiting for a driver to accept the ride request
class RideWaitingForDriver extends RideTrackingState {
  final String message;

  const RideWaitingForDriver(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Driver States
// ============================================================================

/// State when a driver has accepted the ride
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

/// State when driver location is updated during the ride
class DriverLocationUpdated extends RideTrackingState {
  final LatLng driverLocation;
  final double rotation;
  final List<LatLng> driverPath;
  final String driverName;
  final String driverPhone;
  final String vehicleInfo;
  final String plateNumber;
  final double driverRating;
  final LatLng? destination;
  final String destinationType; // 'pickup' or 'dropoff'
  final String rideStatus;

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

  /// Helper method to get driver details as a map
  Map<String, dynamic> get driverDetails => {
        'name': driverName,
        'phone': driverPhone,
        'vehicleInfo': vehicleInfo,
        'plateNumber': plateNumber,
        'rating': driverRating,
      };
}

// ============================================================================
// Ride Status States
// ============================================================================

/// State when ride status changes (arrived, in-progress, etc.)
class RideStatusUpdated extends RideTrackingState {
  final String status;

  const RideStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];

  /// Helper methods for status checks
  bool get isArrived => status == 'arrived';
  bool get isInProgress => status == 'in-progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

/// State when ride is completed
class RideCompleted extends RideTrackingState {
  final String rideId;

  const RideCompleted(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

/// State to show rating dialog after ride completion
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
  List<Object?> get props => [
        rideId,
        finalFare,
        actualDistance,
        actualDuration,
      ];
}

// ============================================================================
// Active Ride States
// ============================================================================

/// Loading state when fetching active ride
class ActiveRideLoading extends RideTrackingState {}

/// State when active ride data is loaded
class ActiveRideLoaded extends RideTrackingState {
  final ActiveRideModel activeRideData;

  const ActiveRideLoaded(this.activeRideData);

  @override
  List<Object?> get props => [activeRideData];
}

/// Error state when active ride fetch fails
class ActiveRideError extends RideTrackingState {
  final String message;

  const ActiveRideError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Error States
// ============================================================================

/// General error state for ride tracking
class RideTrackingError extends RideTrackingState {
  final String message;

  const RideTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
