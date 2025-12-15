import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/location_button.dart';
import '../../bussiness_logic/map_cubit/map_cubit.dart';
import '../../bussiness_logic/map_cubit/map_state.dart';
import '../../bussiness_logic/map_cubit/user_cubit/user_cubit.dart';
import '../../bussiness_logic/map_cubit/user_cubit/user_state.dart';
import '../../bussiness_logic/ride_tracking_cubit/ride_tracking_cubit.dart';
import '../../bussiness_logic/ride_tracking_cubit/ride_tracking_state.dart';
import '../widgets/driver_info_card.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/rating_dialog_widget.dart';
import '../widgets/ride_status_card.dart';
import '../widgets/trip_info_card.dart';

class HomeScreenView extends StatelessWidget {
  const HomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            if (state is MapLoadingState) {
              return const Center(
                child: LoadingIndicator(useCupertino: true),
              );
            }

            if (state is MapLoadedState ||
                state is UpdateDriverLocationStateLoading) {
              final cubit = context.read<MapCubit>();
              final position = cubit.currentPosition;

              if (position == null) {
                return const Center(child: LoadingIndicator());
              }

              return BlocConsumer<UserCubit, UserState>(
                listener: (context, userState) {
                  _handleUserStateChanges(context, userState);
                },
                builder: (context, userState) {
                  return BlocBuilder<RideTrackingCubit, RideTrackingState>(
                    builder: (context, trackingState) {
                      _handleRideTracking(context, trackingState);

                      return Stack(
                        children: [
                          _buildGoogleMap(context, position, cubit),
                          _buildTopBar(),
                          _buildLocationButton(context, state),
                          _buildStatusCard(trackingState),
                          _buildDriverInfoCard(trackingState),
                          _buildTripInfoCard(
                              context, cubit, trackingState, userState),
                        ],
                      );
                    },
                  );
                },
              );
            }

            return const Center(child: LoadingIndicator());
          },
        ),
      ),
    );
  }

  void _handleUserStateChanges(BuildContext context, UserState userState) {
    if (userState is RequestRideSuccessState) {
      // Set waiting state in ride tracking cubit and start tracking
      context.read<RideTrackingCubit>().setWaitingForDriver(
            rideId: userState.rideRequestResponse.data.id,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride requested successfully! Waiting for driver...'),
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
  }

  void _handleRideTracking(
      BuildContext context, RideTrackingState trackingState) {
    print('RideTrackingCubit state: ${trackingState.runtimeType}');

    final mapCubit = context.read<MapCubit>();
    final trackingCubit = context.read<RideTrackingCubit>();

    if (trackingState is DriverLocationUpdated) {
      _handleDriverLocationUpdate(
        mapCubit,
        trackingCubit,
        trackingState,
      );
    } else if (trackingState is RideCompleted ||
        trackingState is ShowRatingDialog) {
      _handleRideCompletion(context, trackingCubit, mapCubit, trackingState);
    }
  }

  void _handleDriverLocationUpdate(
    MapCubit mapCubit,
    RideTrackingCubit trackingCubit,
    DriverLocationUpdated state,
  ) {
    print(
        'Updating driver marker at: ${state.driverLocation.latitude}, ${state.driverLocation.longitude}');

    // Update driver marker with rotation
    trackingCubit.updateDriverMarkerOnMap(
      mapCubit,
      state.driverLocation,
      rotation: state.rotation,
    );

    // Draw driver path
    trackingCubit.drawDriverPathOnMap(
      mapCubit,
      state.driverPath,
      state.driverLocation,
    );

    // Animate camera to follow driver
    mapCubit.mapController?.animateCamera(
      CameraUpdate.newLatLng(state.driverLocation),
    );
  }

  void _handleRideCompletion(
    BuildContext context,
    RideTrackingCubit trackingCubit,
    MapCubit mapCubit,
    RideTrackingState state,
  ) {
    // Remove driver marker
    trackingCubit.removeDriverMarkerFromMap(mapCubit);

    // Show rating dialog
    final rideId = state is RideCompleted
        ? state.rideId
        : (state as ShowRatingDialog).rideId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showRatingDialog(context, rideId);
    });
  }

  Widget _buildGoogleMap(
      BuildContext context, dynamic position, MapCubit cubit) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(position.latitude, position.longitude),
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
    );
  }

  Widget _buildTopBar() {
    return HomeTopBar(
      onMenuPressed: () => Get.toNamed(AppRoutes.drawer),
      onProfilePressed: () {
        // Get.toNamed(AppRoutes.profile);
      },
    );
  }

  Widget _buildLocationButton(BuildContext context, MapState state) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: LocationButton(
        isLoading: state is UpdateDriverLocationStateLoading,
        onPressed: () => context.read<MapCubit>().updateCurrentLocation(),
      ),
    );
  }

  Widget _buildStatusCard(RideTrackingState trackingState) {
    if (trackingState is RideWaitingForDriver ||
        trackingState is RideStatusUpdated) {
      final message = trackingState is RideWaitingForDriver
          ? trackingState.message
          : (trackingState as RideStatusUpdated).status;

      return Positioned(
        top: 80,
        left: 16,
        right: 16,
        child: RideStatusCard(message: message),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDriverInfoCard(RideTrackingState trackingState) {
    if (trackingState is DriverLocationUpdated) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: DriverInfoCard(
          driverName: trackingState.driverName,
          driverRating: trackingState.driverRating,
          vehicleInfo: trackingState.vehicleInfo,
          plateNumber: trackingState.plateNumber,
          onCallPressed: () {
            // TODO: Implement call driver functionality
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTripInfoCard(
    BuildContext context,
    MapCubit cubit,
    RideTrackingState trackingState,
    UserState userState,
  ) {
    // Only show when no driver assigned or just accepted
    if ((trackingState is RideTrackingInitial ||
            trackingState is RideWaitingForDriver ||
            trackingState is DriverAccepted) &&
        cubit.fromLocation != null &&
        cubit.toLocation != null) {
      return Positioned(
        bottom: 20,
        left: 16,
        right: 16,
        child: TripInfoCard(
          fromLocation: cubit.fromLocation!,
          toLocation: cubit.toLocation!,
          fromAddress: cubit.fromAddress,
          toAddress: cubit.toAddress,
          isRequesting: userState is RequestRideLoadingState,
          onCancel: () {
            cubit.clearRoute();
            context.read<RideTrackingCubit>().reset();
          },
          onRequestRide: () {
            context.read<UserCubit>().requestRide(
                  pickupAddress: cubit.fromAddress!,
                  pickupLatitude: cubit.fromLocation!.latitude,
                  pickupLongitude: cubit.fromLocation!.longitude,
                  dropoffAddress: cubit.toAddress!,
                  dropoffLatitude: cubit.toLocation!.latitude,
                  dropoffLongitude: cubit.toLocation!.longitude,
                );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
