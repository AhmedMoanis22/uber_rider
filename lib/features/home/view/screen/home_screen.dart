import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_rider/features/home/bussiness_logic/map_cubit/user_cubit/user_cubit.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../bussiness_logic/map_cubit/map_cubit.dart';
import '../../bussiness_logic/ride_tracking_cubit/ride_tracking_cubit.dart';
import 'home_screen_view.dart';

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
      child: const HomeScreenView(),
    );
  }
}
