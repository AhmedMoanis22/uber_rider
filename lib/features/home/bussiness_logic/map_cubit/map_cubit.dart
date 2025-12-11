import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/model/nearby_driver_model.dart';
import '../../data/repository/user_repository.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final UserRepository userRepository;

  MapCubit({required this.userRepository}) : super(MapInitialState());

  List<DriverData> nearbyDrivers = [];
  BitmapDescriptor? carIcon;

  GoogleMapController? mapController;
  Position? currentPosition;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  LatLng? fromLocation;
  LatLng? toLocation;
  String? fromAddress;
  String? toAddress;

  // Initialize map and get current location
  Future<void> initializeMap() async {
    emit(MapLoadingState());
    try {
      // Load custom car icon
      carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/car.png',
      );

      final position = await _getCurrentLocation();
      currentPosition = position;

      // Add marker for current location

      // Fetch and display nearby drivers
      await _fetchNearbyDrivers(position.latitude, position.longitude);

      emit(MapLoadedState(position));
    } catch (e) {
      emit(MapErrorState(e.toString()));
    }
  }

  // Get current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Update current location
  Future<void> updateCurrentLocation() async {
    emit(const UpdateDriverLocationStateLoading());
    try {
      final position = await _getCurrentLocation();
      currentPosition = position;

      // Update current location marker
      markers
          .removeWhere((marker) => marker.markerId.value == 'currentLocation');
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }

      emit(MapLoadedState(position));
    } catch (e) {
      emit(MapErrorState(e.toString()));
    }
  }

  // Set from location with red marker
  Future<void> setFromLocation(LatLng location) async {
    fromLocation = location;

    // Get address from coordinates
    fromAddress = await _getAddressFromLatLng(location);

    // Remove existing from marker
    markers.removeWhere((marker) => marker.markerId.value == 'fromLocation');

    // Add red marker for from location
    markers.add(
      Marker(
        markerId: const MarkerId('fromLocation'),
        position: location,
        infoWindow: InfoWindow(title: fromAddress ?? 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Draw route if both locations are set
    if (toLocation != null) {
      _drawRoute();
    }

    if (currentPosition != null) {
      emit(MapLoadedState(currentPosition!));
    }
  }

  // Set to location with green marker
  Future<void> setToLocation(LatLng location) async {
    toLocation = location;

    // Get address from coordinates
    toAddress = await _getAddressFromLatLng(location);

    // Remove existing to marker
    markers.removeWhere((marker) => marker.markerId.value == 'toLocation');

    // Add green marker for to location
    markers.add(
      Marker(
        markerId: const MarkerId('toLocation'),
        position: location,
        infoWindow: InfoWindow(title: toAddress ?? 'Drop-off Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Draw route if both locations are set
    if (fromLocation != null) {
      _drawRoute();
    }

    if (currentPosition != null) {
      emit(MapLoadedState(currentPosition!));
    }
  }

  // Draw route between from and to locations
  void _drawRoute() {
    if (fromLocation == null || toLocation == null) return;

    // Remove existing route
    polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');

    // Add polyline connecting from and to
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [fromLocation!, toLocation!],
        color: const Color(0xFF2196F3),
        width: 5,
      ),
    );

    // Adjust camera to show both markers
    _fitBounds();
  }

  // Fit camera bounds to show both markers
  Future<void> _fitBounds() async {
    if (mapController == null || fromLocation == null || toLocation == null)
      return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        fromLocation!.latitude < toLocation!.latitude
            ? fromLocation!.latitude
            : toLocation!.latitude,
        fromLocation!.longitude < toLocation!.longitude
            ? fromLocation!.longitude
            : toLocation!.longitude,
      ),
      northeast: LatLng(
        fromLocation!.latitude > toLocation!.latitude
            ? fromLocation!.latitude
            : toLocation!.latitude,
        fromLocation!.longitude > toLocation!.longitude
            ? fromLocation!.longitude
            : toLocation!.longitude,
      ),
    );

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  // Fetch nearby drivers and add markers
  Future<void> _fetchNearbyDrivers(double latitude, double longitude) async {
    try {
      final result = await userRepository.getNearbyDrivers(
        latitude: latitude,
        longitude: longitude,
      );

      result.fold(
        (failure) {
          print('Error fetching nearby drivers: ${failure.message}');
        },
        (drivers) {
          nearbyDrivers = drivers;
          _addDriverMarkers();
        },
      );
    } catch (e) {
      print('Error fetching nearby drivers: $e');
    }
  }

  // Add driver markers to the map
  void _addDriverMarkers() {
    // Remove existing driver markers
    markers
        .removeWhere((marker) => marker.markerId.value.startsWith('driver_'));

    // Add markers for each nearby driver
    for (var driver in nearbyDrivers) {
      final driverLocation = LatLng(
        driver.currentLocation.coordinates[1], // latitude
        driver.currentLocation.coordinates[0], // longitude
      );

      markers.add(
        Marker(
          markerId: MarkerId('driver_${driver.id}'),
          position: driverLocation,
          infoWindow: InfoWindow(
            title: driver.fullName,
            snippet: '${driver.vehicleInfo} - Rating: ${driver.rating}⭐',
          ),
          icon: carIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );
    }
  }

  // Get address from coordinates
  Future<String> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Build a readable address
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.subLocality!;
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }

        if (address.isEmpty) {
          return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        }

        return address;
      }
    } catch (e) {
      print('Error getting address: $e');
    }

    return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
  }

  void clearRoute() {
    fromLocation = null;
    toLocation = null;
    fromAddress = null;
    toAddress = null;

    markers.removeWhere((marker) =>
        marker.markerId.value == 'fromLocation' ||
        marker.markerId.value == 'toLocation');

    polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');

    if (currentPosition != null) {
      emit(MapLoadedState(currentPosition!));
    }
  }

  // Force map to rebuild (useful when markers are updated externally)
  void notifyMapUpdate() {
    if (currentPosition != null) {
      emit(MapLoadedState(currentPosition!));
    }
  }

  @override
  Future<void> close() {
    mapController?.dispose();
    return super.close();
  }
}
