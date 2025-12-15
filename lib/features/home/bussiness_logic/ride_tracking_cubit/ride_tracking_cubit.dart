import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/repository/user_repository.dart';
import '../map_cubit/map_cubit.dart';
import 'ride_tracking_state.dart';

/// Constants for ride tracking configuration
class RideTrackingConstants {
  static const Duration locationUpdateInterval = Duration(seconds: 2);
  static const double minMovementThreshold = 1.0; // meters
  static const double destinationReachThreshold = 50.0; // meters
  static const double earthRadiusMeters = 6371000.0;

  // Ride status constants
  static const String statusRequested = 'requested';
  static const String statusAccepted = 'accepted';
  static const String statusArrived = 'arrived';
  static const String statusInProgress = 'in-progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Socket events
  static const String eventRideAccepted = 'ride:accepted';
  static const String eventDriverLocation = 'driver:location';
  static const String eventRideStatusUpdated = 'ride:status-updated';
  static const String eventRideCompleted = 'ride:completed';
}

/// Cubit for managing ride tracking functionality
class RideTrackingCubit extends Cubit<RideTrackingState> {
  final UserRepository userRepository;
  final SocketService socketService;
  final NotificationService notificationService;

  Timer? _locationTimer;
  String? _activeRideId;
  LatLng? _previousDriverLocation;
  final List<LatLng> _driverPath = [];

  // Driver details
  String? _driverName;
  String? _driverPhone;
  String? _vehicleInfo;
  String? _plateNumber;
  double? _driverRating;

  // Ride locations and status
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String? _currentRideStatus;

  RideTrackingCubit({
    required this.userRepository,
    required this.socketService,
    required this.notificationService,
  }) : super(RideTrackingInitial()) {
    _setupSocketListeners();
  }

  // ========================================================================
  // Public Methods
  // ========================================================================

  /// Get active ride from API
  Future<void> getActiveRide() async {
    try {
      final result = await userRepository.getActiveRide();
      result.fold(
        (failure) {
          print('Failed to get active ride: ${failure.message}');
        },
        (activeRide) {
          emit(ActiveRideLoaded(activeRide));
        },
      );
    } catch (e) {
      print('Error in getActiveRide: $e');
      emit(const ActiveRideError('Error fetching active ride'));
    }
  }

  /// Set waiting state after ride request and start tracking
  void setWaitingForDriver({String? rideId}) {
    print('🚀 Waiting for driver to accept the ride...');

    if (rideId != null) {
      _activeRideId = rideId;
      print('📝 Stored ride ID: $_activeRideId');
      print('🔄 Starting tracking immediately to detect driver acceptance...');

      // Start tracking immediately to poll for driver assignment
      _startTrackingDriver();
    }

    emit(const RideWaitingForDriver('Waiting for driver...'));
  }

  /// Check for existing active ride on app start/restart
  Future<void> checkForExistingRide() async {
    print('🔍 Checking for existing active ride...');
    try {
      final result = await userRepository.getActiveRide();
      result.fold(
        (failure) {
          print('No existing active ride found');
        },
        (activeRide) {
          print('✅ Found existing active ride!');
          print('   - Ride ID: ${activeRide.data.id}');
          print('   - Status: ${activeRide.data.status}');
          print(
              '   - Driver: ${activeRide.data.driver != null ? "ASSIGNED" : "NULL"}');

          // Store ride ID
          _activeRideId = activeRide.data.id;

          // If driver is assigned and ride is in progress
          if (activeRide.data.driver != null &&
              (activeRide.data.status == RideTrackingConstants.statusAccepted ||
                  activeRide.data.status ==
                      RideTrackingConstants.statusArrived ||
                  activeRide.data.status == 'started')) {
            _handleExistingRideWithDriver(activeRide);
          } else if (activeRide.data.status ==
              RideTrackingConstants.statusRequested) {
            // Ride is still waiting for driver
            print('⏳ Ride in requested status, waiting for driver...');
            emit(const RideWaitingForDriver('Waiting for driver...'));
          }
        },
      );
    } catch (e) {
      print('❌ Error checking for existing ride: $e');
    }
  }

  /// Reset to initial state
  void reset() {
    _stopTrackingDriver();
    _clearRideData();
    emit(RideTrackingInitial());
  }

  /// Update driver marker on map
  void updateDriverMarkerOnMap(
    MapCubit mapCubit,
    LatLng location, {
    double rotation = 0.0,
  }) {
    // Remove old driver marker and all nearby driver markers
    mapCubit.markers.removeWhere((m) =>
        m.markerId.value == 'driver' || m.markerId.value.startsWith('driver_'));

    // Use custom car icon if available
    BitmapDescriptor icon;
    if (mapCubit.carIcon != null) {
      icon = mapCubit.carIcon!;
    } else {
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }

    // Determine info window snippet based on ride status
    String snippet = _getDriverMarkerSnippet();

    // Add updated driver marker with rotation
    mapCubit.markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: location,
        icon: icon,
        rotation: rotation,
        infoWindow: InfoWindow(
          title: _driverName ?? 'Driver',
          snippet: snippet,
        ),
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ),
    );

    // Notify map to rebuild
    mapCubit.notifyMapUpdate();
  }

  /// Draw the path the driver has taken
  void drawDriverPathOnMap(
    MapCubit mapCubit,
    List<LatLng> path,
    LatLng? currentLocation,
  ) {
    if (path.length < 2 && currentLocation == null) return;

    // Remove existing driver path polyline
    mapCubit.polylines.removeWhere((p) => p.polylineId.value == 'driverPath');

    // Add polyline showing driver's movement path
    mapCubit.polylines.add(
      Polyline(
        polylineId: const PolylineId('driverPath'),
        points: [...path, if (currentLocation != null) currentLocation],
        color: const Color(0xFF2196F3),
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );

    // Notify map to rebuild
    mapCubit.notifyMapUpdate();
  }

  /// Remove driver marker from map
  void removeDriverMarkerFromMap(MapCubit mapCubit) {
    mapCubit.markers.removeWhere((m) => m.markerId.value == 'driver');
    mapCubit.polylines.removeWhere((p) => p.polylineId.value == 'driverPath');

    // Notify map to rebuild
    mapCubit.notifyMapUpdate();
  }

  // ========================================================================
  // Private Methods
  // ========================================================================

  /// Setup socket listeners for ride events
  void _setupSocketListeners() {
    // Listen for ride accepted event
    socketService.on(RideTrackingConstants.eventRideAccepted, (data) {
      _handleRideAccepted(data);
    });

    // Listen for driver location updates (from socket - backup)
    socketService.on(RideTrackingConstants.eventDriverLocation, (data) {
      _handleDriverLocationFromSocket(data);
    });

    // Listen for ride status updates
    socketService.on(RideTrackingConstants.eventRideStatusUpdated, (data) {
      _handleRideStatusUpdate(data);
    });

    // Listen for ride completed
    socketService.on(RideTrackingConstants.eventRideCompleted, (data) {
      _handleRideCompleted(data);
    });

    print('✅ Socket listeners setup complete');
  }

  /// Handle ride accepted event from socket
  void _handleRideAccepted(dynamic data) {
    notificationService.showNotification(
      title: "Driver Accepted!",
      body: "${data['driver']['firstName']} is on the way",
    );

    // Extract driver details
    _driverName = data['driver']['firstName'] ?? '';
    _driverPhone = data['driver']['phone'] ?? '';
    _vehicleInfo =
        "${data['driver']['vehicleMake'] ?? ''} ${data['driver']['vehicleModel'] ?? ''}";
    _plateNumber = data['driver']['vehiclePlateNumber'] ?? '';
    _driverRating = (data['driver']['rating'] ?? 0.0).toDouble();

    // Store ride ID for polling
    if (data['ride'] != null && data['ride']['_id'] != null) {
      _activeRideId = data['ride']['_id'];
    }

    // Update driver location if available
    if (data['driver']['currentLocation'] != null &&
        data['driver']['currentLocation']['coordinates'] != null) {
      final coords = data['driver']['currentLocation']['coordinates'];
      final driverLocation = LatLng(coords[1], coords[0]);

      emit(DriverAccepted(
        driverName: _driverName!,
        driverPhone: _driverPhone!,
        vehicleInfo: _vehicleInfo!,
        plateNumber: _plateNumber!,
        driverRating: _driverRating!,
        driverLocation: driverLocation,
      ));

      // Store initial driver location for tracking
      _previousDriverLocation = driverLocation;

      // Start polling for driver location updates
      print('✅ Starting location tracking timer...');
      _startTrackingDriver();
    }
  }

  /// Handle driver location update from socket
  void _handleDriverLocationFromSocket(dynamic data) {
    print('📍 Driver location update via socket: $data');

    if (data['location'] != null && data['location']['coordinates'] != null) {
      final coords = data['location']['coordinates'];
      final newLocation = LatLng(coords[1], coords[0]);
      _updateDriverLocation(newLocation);
    }
  }

  /// Handle ride status update from socket
  void _handleRideStatusUpdate(dynamic data) {
    final status = data['status'] ?? '';
    print('Status extracted: $status');

    // If driver arrived, stop tracking (but don't emit immediately - let polling handle it)
    if (status == RideTrackingConstants.statusArrived) {
      _stopTrackingDriver();
      emit(RideStatusUpdated(status));
    } else {
      emit(RideStatusUpdated(status));
    }
  }

  /// Handle ride completed event from socket
  void _handleRideCompleted(dynamic data) {
    print('✅ Ride completed: $data');

    // Stop tracking
    _stopTrackingDriver();

    notificationService.showNotification(
      title: "Ride Completed",
      body: "Thank you for riding with us!",
    );

    // Emit state to show rating dialog with ride completion data
    emit(ShowRatingDialog(
      rideId: data['rideId'] ?? _activeRideId ?? '',
      finalFare: (data['finalFare'] ?? 0.0).toDouble(),
      actualDistance: (data['actualDistance'] ?? 0.0).toDouble(),
      actualDuration: (data['actualDuration'] ?? 0).toInt(),
    ));

    _clearRideData();
  }

  /// Handle existing ride with assigned driver
  void _handleExistingRideWithDriver(dynamic activeRide) {
    // Extract driver details
    _driverName = activeRide.data.driver!.firstName;
    _driverPhone = activeRide.data.driver!.phone;
    _vehicleInfo = activeRide.data.driver!.vehicleInfo;
    _plateNumber = activeRide.data.driver!.vehiclePlateNumber;
    _driverRating = activeRide.data.driver!.rating.toDouble();

    // Get driver location
    if (activeRide.data.driver!.currentLocation.coordinates.length == 2) {
      final coords = activeRide.data.driver!.currentLocation.coordinates;
      final driverLocation = LatLng(coords[1], coords[0]);

      print(
          '📍 Driver location: ${driverLocation.latitude}, ${driverLocation.longitude}');

      // Store initial location
      _previousDriverLocation = driverLocation;

      // Emit driver accepted state
      emit(DriverAccepted(
        driverName: _driverName!,
        driverPhone: _driverPhone!,
        vehicleInfo: _vehicleInfo!,
        plateNumber: _plateNumber!,
        driverRating: _driverRating!,
        driverLocation: driverLocation,
      ));

      // Start tracking if ride is active
      if (activeRide.data.status == RideTrackingConstants.statusAccepted ||
          activeRide.data.status == RideTrackingConstants.statusArrived ||
          activeRide.data.status == RideTrackingConstants.statusInProgress) {
        print(
            '🚗 Starting tracking for existing ride (status: ${activeRide.data.status})...');
        _startTrackingDriver();
      } else {
        print(
            '✅ Ride status: ${activeRide.data.status}, not starting tracking');
      }
    }
  }

  /// Start polling for driver location every few seconds
  void _startTrackingDriver() {
    // Cancel existing timer if any
    _stopTrackingDriver();

    _locationTimer = Timer.periodic(
      RideTrackingConstants.locationUpdateInterval,
      (timer) async {
        try {
          if (_activeRideId == null) {
            _stopTrackingDriver();
            return;
          }

          // Get active ride from API
          final result = await userRepository.getActiveRide();

          result.fold(
            (failure) {
              print('❌ Failed to get active ride: ${failure.message}');
            },
            (activeRide) => _processActiveRideUpdate(activeRide),
          );
        } catch (e) {
          print('❌ Error fetching driver location: $e');
        }
      },
    );
  }

  /// Stop polling for driver location
  void _stopTrackingDriver() {
    print('🛑 Stopping driver location tracking...');
    _locationTimer?.cancel();
    _locationTimer = null;
    print('✅ Timer cancelled');
  }

  /// Process active ride update from API
  void _processActiveRideUpdate(dynamic activeRide) {
    // Update current ride status
    _currentRideStatus = activeRide.data.status;

    // Store pickup and dropoff locations if not already set
    _storeRideLocations(activeRide);

    // Check if driver arrived - but KEEP tracking
    if (activeRide.data.status == RideTrackingConstants.statusArrived) {
      emit(const RideStatusUpdated(RideTrackingConstants.statusArrived));
      // Continue to update driver location below
    }

    // Stop tracking if ride status is completed or cancelled
    if (activeRide.data.status == RideTrackingConstants.statusCompleted ||
        activeRide.data.status == RideTrackingConstants.statusCancelled) {
      print('🛑 Ride status: ${activeRide.data.status}, stopping tracking');
      _stopTrackingDriver();
      return;
    }

    // Check if driver is assigned
    if (activeRide.data.driver != null) {
      _processDriverUpdate(activeRide);
    } else {
      print('⏳ Still waiting for driver to accept...');
    }
  }

  /// Store pickup and dropoff locations from active ride
  void _storeRideLocations(dynamic activeRide) {
    if (_pickupLocation == null &&
        activeRide.data.pickup.location.coordinates.length == 2) {
      final pickupCoords = activeRide.data.pickup.location.coordinates;
      _pickupLocation = LatLng(pickupCoords[1], pickupCoords[0]);
      print('📍 Pickup location stored: $_pickupLocation');
    }
    if (_dropoffLocation == null &&
        activeRide.data.dropoff.location.coordinates.length == 2) {
      final dropoffCoords = activeRide.data.dropoff.location.coordinates;
      _dropoffLocation = LatLng(dropoffCoords[1], dropoffCoords[0]);
      print('📍 Dropoff location stored: $_dropoffLocation');
    }
  }

  /// Process driver update from active ride
  void _processDriverUpdate(dynamic activeRide) {
    // Extract driver details if not already set
    if (_driverName == null) {
      _extractDriverDetails(activeRide);

      print('✅ Driver assigned: $_driverName');

      // Emit DriverAccepted state for first time
      if (activeRide.data.driver!.currentLocation.coordinates.length == 2) {
        final coords = activeRide.data.driver!.currentLocation.coordinates;
        final driverLocation = LatLng(coords[1], coords[0]);

        _previousDriverLocation = driverLocation;

        emit(DriverAccepted(
          driverName: _driverName!,
          driverPhone: _driverPhone!,
          vehicleInfo: _vehicleInfo!,
          plateNumber: _plateNumber!,
          driverRating: _driverRating!,
          driverLocation: driverLocation,
        ));

        print('🎉 Emitted DriverAccepted state');
        return;
      }
    }

    // Update driver location if available
    if (activeRide.data.driver!.currentLocation.coordinates.length == 2) {
      final coords = activeRide.data.driver!.currentLocation.coordinates;
      final newLocation = LatLng(coords[1], coords[0]);
      print(
          '📍 Driver coords: [${coords[0]}, ${coords[1]}] -> LatLng(${newLocation.latitude}, ${newLocation.longitude})');
      _updateDriverLocation(newLocation);
    }
  }

  /// Extract driver details from active ride
  void _extractDriverDetails(dynamic activeRide) {
    _driverName = activeRide.data.driver!.firstName;
    _driverPhone = activeRide.data.driver!.phone;
    _vehicleInfo = activeRide.data.driver!.vehicleInfo;
    _plateNumber = activeRide.data.driver!.vehiclePlateNumber;
    _driverRating = activeRide.data.driver!.rating.toDouble();
  }

  /// Update driver location with rotation and path
  void _updateDriverLocation(LatLng newLocation) {
    print(
        'Updating driver location to: ${newLocation.latitude}, ${newLocation.longitude}');

    // Determine current destination based on ride status
    final destination = _getCurrentDestination();
    final destinationType = _getDestinationType();

    // Check if reached dropoff location
    if (_shouldCompleteRide(newLocation)) {
      return;
    }

    // Check if location actually changed
    if (_previousDriverLocation != null) {
      final distance =
          _calculateDistance(_previousDriverLocation!, newLocation);
      print('Distance from previous location: $distance meters');

      // Only update path if moved more than threshold
      if (distance > RideTrackingConstants.minMovementThreshold) {
        _driverPath.add(_previousDriverLocation!);
      }
    }

    // Calculate rotation
    double rotation = 0.0;
    if (_previousDriverLocation != null) {
      rotation = _calculateBearing(_previousDriverLocation!, newLocation);
    }

    _previousDriverLocation = newLocation;

    print('Emitting DriverLocationUpdated state');
    emit(DriverLocationUpdated(
      driverLocation: newLocation,
      rotation: rotation,
      driverPath: List.from(_driverPath),
      driverName: _driverName ?? '',
      driverPhone: _driverPhone ?? '',
      vehicleInfo: _vehicleInfo ?? '',
      plateNumber: _plateNumber ?? '',
      driverRating: _driverRating ?? 0.0,
      destination: destination,
      destinationType: destinationType,
      rideStatus: _currentRideStatus ?? RideTrackingConstants.statusAccepted,
    ));
  }

  /// Get current destination based on ride status
  LatLng? _getCurrentDestination() {
    if (_currentRideStatus == RideTrackingConstants.statusInProgress &&
        _dropoffLocation != null) {
      print('🎯 Destination: Dropoff location');
      return _dropoffLocation;
    } else if (_pickupLocation != null) {
      print('🎯 Destination: Pickup location');
      return _pickupLocation;
    }
    return null;
  }

  /// Get destination type based on ride status
  String _getDestinationType() {
    if (_currentRideStatus == RideTrackingConstants.statusInProgress &&
        _dropoffLocation != null) {
      return 'dropoff';
    }
    return 'pickup';
  }

  /// Check if ride should be completed based on driver location
  bool _shouldCompleteRide(LatLng newLocation) {
    if (_currentRideStatus == RideTrackingConstants.statusInProgress &&
        _dropoffLocation != null) {
      final distanceToDropoff =
          _calculateDistance(newLocation, _dropoffLocation!);
      print(
          '📍 Distance to dropoff: ${distanceToDropoff.toStringAsFixed(2)} meters');

      if (distanceToDropoff <=
          RideTrackingConstants.destinationReachThreshold) {
        print('========================================');
        print('🎉 DRIVER REACHED DROPOFF LOCATION!');
        print('Distance: ${distanceToDropoff.toStringAsFixed(2)}m');
        print('Automatically completing the ride...');
        print('========================================');

        // Stop tracking immediately
        _stopTrackingDriver();

        // Show notification
        notificationService.showNotification(
          title: "Destination Reached! 🎯",
          body:
              "You have arrived at your destination. Thank you for riding with us!",
        );

        // Extract ride ID before clearing
        final completedRideId = _activeRideId ?? '';

        // Clear ride data
        _clearRideData();

        // Emit ride completed
        emit(RideCompleted(completedRideId));
        return true;
      }
    }
    return false;
  }

  /// Get driver marker snippet based on ride status
  String _getDriverMarkerSnippet() {
    if (_currentRideStatus == RideTrackingConstants.statusInProgress) {
      return 'Taking you to destination';
    } else if (_currentRideStatus == RideTrackingConstants.statusArrived) {
      return 'Arrived at pickup';
    } else {
      return 'On the way to pickup';
    }
  }

  // ========================================================================
  // Utility Methods
  // ========================================================================

  /// Calculate distance between two points in meters
  double _calculateDistance(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180.0;
    final lat2 = end.latitude * math.pi / 180.0;
    final dLat = (end.latitude - start.latitude) * math.pi / 180.0;
    final dLng = (end.longitude - start.longitude) * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return RideTrackingConstants.earthRadiusMeters * c;
  }

  /// Calculate bearing (rotation angle) between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * math.pi / 180.0;
    final startLng = start.longitude * math.pi / 180.0;
    final endLat = end.latitude * math.pi / 180.0;
    final endLng = end.longitude * math.pi / 180.0;

    final dLng = endLng - startLng;

    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (bearing * 180.0 / math.pi + 360) % 360;
  }

  /// Clear ride data
  void _clearRideData() {
    _activeRideId = null;
    _previousDriverLocation = null;
    _driverPath.clear();
    _driverName = null;
    _driverPhone = null;
    _vehicleInfo = null;
    _plateNumber = null;
    _driverRating = null;
    _pickupLocation = null;
    _dropoffLocation = null;
    _currentRideStatus = null;
  }

  @override
  Future<void> close() {
    _stopTrackingDriver();
    socketService.off(RideTrackingConstants.eventRideAccepted);
    socketService.off(RideTrackingConstants.eventDriverLocation);
    socketService.off(RideTrackingConstants.eventRideStatusUpdated);
    socketService.off(RideTrackingConstants.eventRideCompleted);
    return super.close();
  }
}
