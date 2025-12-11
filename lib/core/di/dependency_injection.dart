// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:uber_rider/features/home/bussiness_logic/map_cubit/user_cubit/user_cubit.dart';
import 'package:uber_rider/features/home/data/data_source/user_remote_data_source.dart';

import '../../features/auth/bussiness_logic/auth_cubit.dart';
import '../../features/auth/data/data_source/auth_remote_data_source.dart';
import '../../features/auth/data/repository/auth_repository.dart';
import '../../features/home/bussiness_logic/map_cubit/map_cubit.dart';
import '../../features/home/bussiness_logic/ride_tracking_cubit/ride_tracking_cubit.dart';
import '../../features/home/data/repository/user_repository.dart';
import '../network/api_factory.dart';
import '../network/api_services.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

final getIt = GetIt.instance;

Future<void> setupGetit() async {
  // Initialize notification service
  await NotificationService().initialize();

  // Register services
  getIt.registerLazySingleton<SocketService>(() => SocketService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  Dio dio = DioFactory.getDio();
  getIt.registerLazySingleton<ApiServices>(() => ApiServices(dio: dio));
  /* Auth Feature */

  getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(apiServices: getIt()));

  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
        authRemoteDataSource: getIt(),
      ));
  getIt.registerFactory<AuthCubit>(() => AuthCubit(authRepository: getIt()));

  getIt.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSource(apiServices: getIt()));

  getIt.registerLazySingleton<UserRepository>(() => UserRepository(
        userRemoteDataSource: getIt(),
      ));
  getIt.registerFactory<UserCubit>(() => UserCubit(userRepository: getIt()));

  // Map Cubit
  getIt.registerFactory<MapCubit>(() => MapCubit(userRepository: getIt()));

  // Ride Tracking Cubit
  getIt.registerFactory<RideTrackingCubit>(() => RideTrackingCubit(
        userRepository: getIt(),
        socketService: getIt(),
        notificationService: getIt(),
      ));
}
