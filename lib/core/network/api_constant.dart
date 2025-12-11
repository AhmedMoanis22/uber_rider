class ApiConstance {
  static const String baseUrl = 'http://192.168.1.13:5000/api/';
  /* Auth Endpoints */
  static const String loginEndpoint = 'auth/login';

  /* User Endpoints */
  static const String requestRide = 'user/ride/request';
  static const String getNearbyDrivers = 'user/drivers/nearby?';
  static const String getActiveRide = 'user/ride/active';
  static const String userRide = 'user/ride/';
}
