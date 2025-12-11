class NearbyDriverModel {
  final bool success;
  final int count;
  final List<DriverData> data;

  NearbyDriverModel({
    required this.success,
    required this.count,
    required this.data,
  });

  factory NearbyDriverModel.fromJson(Map<String, dynamic> json) {
    return NearbyDriverModel(
      success: json['success'],
      count: json['count'],
      data: List<DriverData>.from(
        json['data'].map((x) => DriverData.fromJson(x)),
      ),
    );
  }
}

class DriverData {
  final CurrentLocation currentLocation;
  final String id;
  final String firstName;
  final String lastName;
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlateNumber;
  final double rating;
  final int totalRides;
  final String fullName;
  final String vehicleInfo;

  DriverData({
    required this.currentLocation,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlateNumber,
    required this.rating,
    required this.totalRides,
    required this.fullName,
    required this.vehicleInfo,
  });

  factory DriverData.fromJson(Map<String, dynamic> json) {
    return DriverData(
      currentLocation: CurrentLocation.fromJson(json['currentLocation']),
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      vehicleType: json['vehicleType'],
      vehicleMake: json['vehicleMake'],
      vehicleModel: json['vehicleModel'],
      vehicleColor: json['vehicleColor'],
      vehiclePlateNumber: json['vehiclePlateNumber'],
      rating: (json['rating'] as num).toDouble(),
      totalRides: json['totalRides'],
      fullName: json['fullName'],
      vehicleInfo: json['vehicleInfo'],
    );
  }
}

class CurrentLocation {
  final String type;
  final List<double> coordinates;
  final String address;
  final String lastUpdated;

  CurrentLocation({
    required this.type,
    required this.coordinates,
    required this.address,
    required this.lastUpdated,
  });

  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
      type: json['type'],
      coordinates: List<double>.from(
        json['coordinates'].map((x) => (x as num).toDouble()),
      ),
      address: json['address'],
      lastUpdated: json['lastUpdated'],
    );
  }
}
