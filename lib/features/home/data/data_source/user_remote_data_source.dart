import '../../../../core/network/api_constant.dart';
import '../../../../core/network/api_services.dart';
import '../model/active_ride_model.dart';
import '../model/nearby_driver_model.dart';
import '../model/request_ride_model.dart';

class UserRemoteDataSource {
  final ApiServices apiServices;
  UserRemoteDataSource({required this.apiServices});

  Future<RideRequestResponse> requestRide({
    required Map<String, dynamic> data,
  }) async {
    final response = await apiServices.postData(
      urll: ApiConstance.requestRide,
      data: data,
    );
    return RideRequestResponse.fromJson(response.data);
  }

  Future<List<DriverData>> getNearbyDrivers({
    required double latitude,
    required double longitude,
  }) async {
    final response = await apiServices.getData(
      urll:
          '${ApiConstance.getNearbyDrivers}latitude=$latitude&longitude=$longitude&radius=100',
    );
    return NearbyDriverModel.fromJson(response.data).data;
  }

  Future<ActiveRideModel> getActiveRide() async {
    final response = await apiServices.getData(
      urll: ApiConstance.getActiveRide,
    );
    return ActiveRideModel.fromJson(response.data);
  }

  Future<String> rateRide({
    required String rideId,
    required Map<String, dynamic> data,
  }) async {
    final response = await apiServices.postData(
      urll: '${ApiConstance.userRide}$rideId/rate',
      data: data,
    );
    return response.data['message'];
  }
}
