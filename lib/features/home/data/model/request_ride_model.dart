class RideRequestResponse {
  final bool success;
  final String message;
  final RideData data;

  RideRequestResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RideRequestResponse.fromJson(Map<String, dynamic> json) {
    return RideRequestResponse(
      success: json['success'],
      message: json['message'],
      data: RideData.fromJson(json['data']),
    );
  }
}

class RideData {
  final User user;
  final dynamic driver;
  final String status;
  final PickupDropoff pickup;
  final PickupDropoff dropoff;
  final double? estimatedFare;
  final double? finalFare;
  final String paymentMethod;
  final String paymentStatus;
  final double? estimatedDistance;
  final double? estimatedDuration;
  final double? actualDistance;
  final double? actualDuration;
  final String vehicleType;
  final double? userRating;
  final double? driverRating;
  final String? userReview;
  final String? driverReview;

  final String? acceptedAt;
  final String? arrivedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  final String id;
  final String requestedAt;
  final String createdAt;
  final String updatedAt;
  final int v;

  RideData({
    required this.user,
    required this.driver,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.estimatedFare,
    required this.finalFare,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.actualDistance,
    required this.actualDuration,
    required this.vehicleType,
    required this.userRating,
    required this.driverRating,
    required this.userReview,
    required this.driverReview,
    required this.acceptedAt,
    required this.arrivedAt,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.cancelledBy,
    required this.cancellationReason,
    required this.id,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory RideData.fromJson(Map<String, dynamic> json) {
    return RideData(
      user: User.fromJson(json['user']),
      driver: json['driver'],
      status: json['status'],
      pickup: PickupDropoff.fromJson(json['pickup']),
      dropoff: PickupDropoff.fromJson(json['dropoff']),
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble(),
      finalFare: (json['finalFare'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      estimatedDistance: (json['estimatedDistance'] as num?)?.toDouble(),
      estimatedDuration: (json['estimatedDuration'] as num?)?.toDouble(),
      actualDistance: (json['actualDistance'] as num?)?.toDouble(),
      actualDuration: (json['actualDuration'] as num?)?.toDouble(),
      vehicleType: json['vehicleType'],
      userRating: (json['userRating'] as num?)?.toDouble(),
      driverRating: (json['driverRating'] as num?)?.toDouble(),
      userReview: json['userReview'],
      driverReview: json['driverReview'],
      acceptedAt: json['acceptedAt'],
      arrivedAt: json['arrivedAt'],
      startedAt: json['startedAt'],
      completedAt: json['completedAt'],
      cancelledAt: json['cancelledAt'],
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      id: json['_id'],
      requestedAt: json['requestedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String fullName;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      fullName: json['fullName'],
    );
  }
}

class PickupDropoff {
  final String address;
  final Location location;

  PickupDropoff({
    required this.address,
    required this.location,
  });

  factory PickupDropoff.fromJson(Map<String, dynamic> json) {
    return PickupDropoff(
      address: json['address'],
      location: Location.fromJson(json['location']),
    );
  }
}

class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      coordinates: List<double>.from(
        json['coordinates'].map((x) => (x as num).toDouble()),
      ),
    );
  }
}
