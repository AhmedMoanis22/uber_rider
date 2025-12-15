import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_rider/core/routes/app_routes.dart';
import 'package:uber_rider/features/home/bussiness_logic/map_cubit/user_cubit/user_cubit.dart';
import 'package:uber_rider/features/home/bussiness_logic/map_cubit/user_cubit/user_state.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bussiness_logic/map_cubit/map_cubit.dart';
import '../../bussiness_logic/map_cubit/map_state.dart';
import '../../bussiness_logic/ride_tracking_cubit/ride_tracking_cubit.dart';
import '../../bussiness_logic/ride_tracking_cubit/ride_tracking_state.dart';
import '../widgets/rating_dialog_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapCubit>(
          create: (context) {
            final cubit = getIt<MapCubit>()..initializeMap();

            // Check if we have trip arguments and set locations
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final args = Get.arguments;
              if (args != null && args is Map) {
                final fromLocation = args['from'] as LatLng?;
                final toLocation = args['to'] as LatLng?;

                if (fromLocation != null && toLocation != null) {
                  cubit.setFromLocation(fromLocation);
                  cubit.setToLocation(toLocation);
                }
              }
            });

            return cubit;
          },
        ),
        BlocProvider<UserCubit>(create: (context) => getIt<UserCubit>()),
        BlocProvider<RideTrackingCubit>(
          create: (context) {
            final cubit = getIt<RideTrackingCubit>();
            // Check for existing active ride when screen loads
            cubit.checkForExistingRide();
            return cubit;
          },
        ),
      ],
      child: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            if (state is MapLoadingState) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            if (state is MapLoadedState ||
                state is UpdateDriverLocationStateLoading) {
              final cubit = context.read<MapCubit>();
              final position = cubit.currentPosition;

              if (position == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return BlocConsumer<UserCubit, UserState>(
                listener: (contzyext, userState) {
                  if (userState is RequestRideSuccessState) {
                    // Set waiting state in ride tracking cubit and start tracking
                    context.read<RideTrackingCubit>().setWaitingForDriver(
                          rideId: userState.rideRequestResponse.data.id,
                        );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Ride requested successfully! Waiting for driver...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (userState is RequestRideErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userState.errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, userState) {
                  return BlocBuilder<RideTrackingCubit, RideTrackingState>(
                    builder: (context, trackingState) {
                      print(
                          'RideTrackingCubit state: ${trackingState.runtimeType}');

                      // Update map markers based on tracking state
                      final mapCubit = context.read<MapCubit>();
                      final trackingCubit = context.read<RideTrackingCubit>();

                      if (trackingState is DriverLocationUpdated) {
                        print(
                            'Updating driver marker at: ${trackingState.driverLocation.latitude}, ${trackingState.driverLocation.longitude}');

                        // Update driver marker with rotation
                        trackingCubit.updateDriverMarkerOnMap(
                          mapCubit,
                          trackingState.driverLocation,
                          rotation: trackingState.rotation,
                        );

                        // Draw driver path
                        trackingCubit.drawDriverPathOnMap(
                          mapCubit,
                          trackingState.driverPath,
                          trackingState.driverLocation,
                        );

                        // Animate camera to follow driver
                        mapCubit.mapController?.animateCamera(
                          CameraUpdate.newLatLng(trackingState.driverLocation),
                        );
                      } else if (trackingState is DriverAccepted) {
                        print(
                            'Driver accepted, initial location: ${trackingState.driverLocation.latitude}, ${trackingState.driverLocation.longitude}');

                        // Don't add marker here - DriverLocationUpdated will handle it
                      } else if (trackingState is RideCompleted) {
                        print('Ride completed, removing driver marker');

                        // Remove driver marker
                        trackingCubit.removeDriverMarkerFromMap(mapCubit);

                        // Show rating dialog after a short delay
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showRatingDialog(context, trackingState.rideId);
                        });
                      } else if (trackingState is ShowRatingDialog) {
                        print(
                            '🎉 Ride completed! Final fare: ${trackingState.finalFare}');

                        // Remove driver marker
                        trackingCubit.removeDriverMarkerFromMap(mapCubit);

                        // Show rating dialog with ride completion data
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showRatingDialog(context, trackingState.rideId);
                        });
                      }
                      return Stack(
                        children: [
                          // Google Map
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target:
                                  LatLng(position.latitude, position.longitude),
                              zoom: 15,
                            ),
                            onMapCreated: cubit.onMapCreated,
                            markers: cubit.markers,
                            polylines: cubit.polylines,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapType: MapType.normal,
                            compassEnabled: true,
                          ),

                          // Top bar with menu and profile
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.menu),
                                      onPressed: () {
                                        Get.toNamed(AppRoutes.drawer);
                                      },
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.person),
                                      onPressed: () {
                                        // Get.toNamed(AppRoutes.profile);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Location button
                          Positioned(
                            bottom: 100,
                            right: 16,
                            child: FloatingActionButton(
                              onPressed:
                                  state is UpdateDriverLocationStateLoading
                                      ? null
                                      : () {
                                          context
                                              .read<MapCubit>()
                                              .updateCurrentLocation();
                                        },
                              backgroundColor: Colors.white,
                              child: state is UpdateDriverLocationStateLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ),

                          // Status card at top when ride is active
                          if (trackingState is RideWaitingForDriver ||
                              trackingState is RideStatusUpdated)
                            Positioned(
                              top: 80,
                              left: 16,
                              right: 16,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.info_outline,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          trackingState is RideWaitingForDriver
                                              ? trackingState.message
                                              : (trackingState
                                                      as RideStatusUpdated)
                                                  .status,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Driver details card at bottom when tracking starts
                          if (trackingState is DriverLocationUpdated)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24)),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Driver name and rating
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: AppColors.primary,
                                            child: Text(
                                              (trackingState is DriverAccepted
                                                      ? trackingState.driverName
                                                      : (trackingState)
                                                          .driverName)[0]
                                                  .toUpperCase(),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  trackingState
                                                          is DriverAccepted
                                                      ? trackingState.driverName
                                                      : (trackingState)
                                                          .driverName,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      (trackingState
                                                                  is DriverAccepted
                                                              ? trackingState
                                                                  .driverRating
                                                              : (trackingState)
                                                                  .driverRating)
                                                          .toStringAsFixed(1),
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
                                          IconButton(
                                            onPressed: () {
                                              // TODO: Call driver
                                            },
                                            icon: const Icon(Icons.phone),
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 16),

                                      // Vehicle info
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_car,
                                              color: AppColors.primary),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Vehicle',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                trackingState is DriverAccepted
                                                    ? trackingState.vehicleInfo
                                                    : (trackingState)
                                                        .vehicleInfo,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              trackingState is DriverAccepted
                                                  ? trackingState.plateNumber
                                                  : (trackingState).plateNumber,
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

                          // Trip info card at bottom (only show when no driver assigned or just accepted)
                          if ((trackingState is RideTrackingInitial ||
                                  trackingState is RideWaitingForDriver ||
                                  trackingState is DriverAccepted) &&
                              cubit.fromLocation != null &&
                              cubit.toLocation != null)
                            Positioned(
                              bottom: 20,
                              left: 16,
                              right: 16,
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.trip_origin,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'From: ${cubit.fromAddress ?? '${cubit.fromLocation!.latitude.toStringAsFixed(4)}, ${cubit.fromLocation!.longitude.toStringAsFixed(4)}'}',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'To: ${cubit.toAddress ?? '${cubit.toLocation!.latitude.toStringAsFixed(4)}, ${cubit.toLocation!.longitude.toStringAsFixed(4)}'}',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                // Clear route and reset all ride state
                                                cubit.clearRoute();
                                                context
                                                    .read<RideTrackingCubit>()
                                                    .reset();
                                              },
                                              icon: const Icon(Icons.clear,
                                                  size: 18),
                                              label: const Text('Cancel'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: userState
                                                      is RequestRideLoadingState
                                                  ? null
                                                  : () {
                                                      context.read<UserCubit>().requestRide(
                                                          pickupAddress: cubit
                                                              .fromAddress!,
                                                          pickupLatitude: cubit
                                                              .fromLocation!
                                                              .latitude,
                                                          pickupLongitude: cubit
                                                              .fromLocation!
                                                              .longitude,
                                                          dropoffAddress:
                                                              cubit.toAddress!,
                                                          dropoffLatitude: cubit
                                                              .toLocation!
                                                              .latitude,
                                                          dropoffLongitude:
                                                              cubit.toLocation!
                                                                  .longitude);
                                                    },
                                              icon: userState
                                                      is RequestRideLoadingState
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Icon(Icons.car_rental,
                                                      size: 18),
                                              label: Text(userState
                                                      is RequestRideLoadingState
                                                  ? 'Requesting...'
                                                  : 'Request Ride'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.white,
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
                      );
                    },
                  );
                },
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
