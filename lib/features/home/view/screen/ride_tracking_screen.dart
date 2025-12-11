import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;

  const RideTrackingScreen({
    super.key,
    required this.rideId,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final SocketService _socketService = SocketService();
  final NotificationService _notificationService = NotificationService();

  GoogleMapController? _mapController;
  String rideStatus = 'Waiting for driver...';
  String? driverName;
  String? driverPhone;
  String? vehicleInfo;
  String? plateNumber;
  double? driverRating;
  LatLng? driverLocation;

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _setupSocketListeners();
  }

  void _setupMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.dropoffLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Drop-off Location'),
      ),
    };
  }

  void _setupSocketListeners() {
    // Listen for ride accepted event
    _socketService.on('ride:accepted', (data) {
      print('Ride accepted: $data');

      // Show notification
      _notificationService.showNotification(
        title: "Driver Accepted!",
        body: "${data['driver']['firstName']} is on the way",
      );

      // Update UI - show driver details
      setState(() {
        rideStatus = 'Driver accepted!';
        driverName = data['driver']['firstName'] ?? '';
        driverPhone = data['driver']['phone'] ?? '';
        vehicleInfo =
            "${data['driver']['vehicleMake'] ?? ''} ${data['driver']['vehicleModel'] ?? ''}";
        plateNumber = data['driver']['vehiclePlateNumber'] ?? '';
        driverRating = (data['driver']['rating'] ?? 0.0).toDouble();

        // Update driver location if available
        if (data['driver']['currentLocation'] != null &&
            data['driver']['currentLocation']['coordinates'] != null) {
          final coords = data['driver']['currentLocation']['coordinates'];
          driverLocation = LatLng(coords[1], coords[0]);

          // Add driver marker
          markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: driverLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow),
              infoWindow: InfoWindow(title: driverName ?? 'Driver'),
            ),
          );
        }
      });
    });

    // Listen for driver location updates
    _socketService.on('driver:location', (data) {
      print('Driver location update: $data');

      if (data['location'] != null && data['location']['coordinates'] != null) {
        final coords = data['location']['coordinates'];
        final newLocation = LatLng(coords[1], coords[0]);

        setState(() {
          driverLocation = newLocation;

          // Update driver marker
          markers.removeWhere((m) => m.markerId.value == 'driver');
          markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: newLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow),
              infoWindow: InfoWindow(title: driverName ?? 'Driver'),
            ),
          );
        });

        // Move camera to driver location
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newLocation),
        );
      }
    });

    // Listen for ride status updates
    _socketService.on('ride:status', (data) {
      print('Ride status update: $data');

      setState(() {
        rideStatus = data['status'] ?? rideStatus;
      });

      // Show notification for status changes
      _notificationService.showNotification(
        title: "Ride Update",
        body: "Status: ${data['status']}",
      );
    });

    // Listen for ride completed
    _socketService.on('ride:completed', (data) {
      print('Ride completed: $data');

      _notificationService.showNotification(
        title: "Ride Completed",
        body: "Thank you for riding with us!",
      );

      setState(() {
        rideStatus = 'Ride completed';
      });
    });
  }

  @override
  void dispose() {
    _socketService.off('ride:accepted');
    _socketService.off('driver:location');
    _socketService.off('ride:status');
    _socketService.off('ride:completed');
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Tracking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickupLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Status card at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rideStatus,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Driver details card at bottom
          if (driverName != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver name and rating
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              driverName![0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (driverRating != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        driverRating!.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (driverPhone != null)
                            IconButton(
                              onPressed: () {
                                // TODO: Call driver
                              },
                              icon: const Icon(Icons.phone),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Vehicle info
                      if (vehicleInfo != null)
                        Row(
                          children: [
                            const Icon(Icons.directions_car,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  vehicleInfo!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (plateNumber != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plateNumber!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
