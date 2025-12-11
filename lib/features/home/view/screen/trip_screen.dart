import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LatLng? fromLocation;
  LatLng? toLocation;

  GoogleMapController? fromMapController;
  GoogleMapController? toMapController;

  bool showFromMap = false;
  bool showToMap = false;

  LatLng defaultLocation = const LatLng(30.0444, 31.2357); // Cairo, Egypt

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    fromMapController?.dispose();
    toMapController?.dispose();
    super.dispose();
  }

  Future<void> _onFromMapTap(LatLng location) async {
    setState(() {
      fromLocation = location;
      fromController.text = 'Getting address...';
    });

    // Get address from coordinates
    String address = await _getAddressFromLatLng(location);

    setState(() {
      fromController.text = address;
    });
  }

  Future<void> _onToMapTap(LatLng location) async {
    setState(() {
      toLocation = location;
      toController.text = 'Getting address...';
    });

    // Get address from coordinates
    String address = await _getAddressFromLatLng(location);

    setState(() {
      toController.text = address;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Icon(
                    Icons.route,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Where would you like to go?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your pickup and drop-off locations',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // From location
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showFromMap = !showFromMap;
                        showToMap = false; // Close to map when opening from map
                      });
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: fromController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'From (Pickup Location)',
                          hintText: 'Tap to select on map',
                          prefixIcon:
                              const Icon(Icons.trip_origin, color: Colors.red),
                          suffixIcon: Icon(
                            showFromMap ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (fromLocation == null) {
                            return 'Please select pickup location on map';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // From map
                  if (showFromMap)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: fromLocation ?? defaultLocation,
                                zoom: 15,
                              ),
                              onMapCreated: (controller) {
                                fromMapController = controller;
                              },
                              onTap: _onFromMapTap,
                              markers: fromLocation != null
                                  ? {
                                      Marker(
                                        markerId: const MarkerId('from'),
                                        position: fromLocation!,
                                        icon: BitmapDescriptor
                                            .defaultMarkerWithHue(
                                          BitmapDescriptor.hueRed,
                                        ),
                                      ),
                                    }
                                  : {},
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Tap anywhere on map to select pickup location',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // To location
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showToMap = !showToMap;
                        showFromMap =
                            false; // Close from map when opening to map
                      });
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: toController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'To (Drop-off Location)',
                          hintText: 'Tap to select on map',
                          prefixIcon: const Icon(Icons.location_on,
                              color: Colors.green),
                          suffixIcon: Icon(
                            showToMap ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (toLocation == null) {
                            return 'Please select drop-off location on map';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // To map
                  if (showToMap)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: toLocation ?? defaultLocation,
                                zoom: 15,
                              ),
                              onMapCreated: (controller) {
                                toMapController = controller;
                              },
                              onTap: _onToMapTap,
                              markers: toLocation != null
                                  ? {
                                      Marker(
                                        markerId: const MarkerId('to'),
                                        position: toLocation!,
                                        icon: BitmapDescriptor
                                            .defaultMarkerWithHue(
                                          BitmapDescriptor.hueGreen,
                                        ),
                                      ),
                                    }
                                  : {},
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Tap anywhere on map to select drop-off location',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Button
                  CustomButton(
                    text: 'Do Your Trip on Map',
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        if (fromLocation != null && toLocation != null) {
                          // Navigate to home with coordinates
                          Get.toNamed(
                            AppRoutes.home,
                            arguments: {
                              'from': fromLocation,
                              'to': toLocation,
                            },
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
