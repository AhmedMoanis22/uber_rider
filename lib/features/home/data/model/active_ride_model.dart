class ActiveRideModel {
  final bool success;
  final RideData data;

  ActiveRideModel({
    required this.success,
    required this.data,
  });

  factory ActiveRideModel.fromJson(Map<String, dynamic> json) {
    return ActiveRideModel(
      success: json['success'],
      data: RideData.fromJson(json['data']),
    );
  }
}

class RideData {
  final PickupDropoff pickup;
  final PickupDropoff dropoff;
  final String id;
  final String user;
  final Driver? driver;
  final String status;
  final double estimatedFare;
  final double? finalFare;
  final String paymentMethod;
  final String paymentStatus;
  final double estimatedDistance;
  final double estimatedDuration;
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
  final String requestedAt;
  final String createdAt;
  final String updatedAt;
  final int v;

  RideData({
    required this.pickup,
    required this.dropoff,
    required this.id,
    required this.user,
    required this.driver,
    required this.status,
    required this.estimatedFare,
    this.finalFare,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.estimatedDistance,
    required this.estimatedDuration,
    this.actualDistance,
    this.actualDuration,
    required this.vehicleType,
    this.userRating,
    this.driverRating,
    this.userReview,
    this.driverReview,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory RideData.fromJson(Map<String, dynamic> json) {
    return RideData(
      pickup: PickupDropoff.fromJson(json["pickup"]),
      dropoff: PickupDropoff.fromJson(json["dropoff"]),
      id: json["_id"],
      user: json["user"],
      driver: json["driver"] != null ? Driver.fromJson(json["driver"]) : null,
      status: json["status"],
      estimatedFare: (json["estimatedFare"] as num).toDouble(),
      finalFare: json["finalFare"] == null
          ? null
          : (json["finalFare"] as num).toDouble(),
      paymentMethod: json["paymentMethod"],
      paymentStatus: json["paymentStatus"],
      estimatedDistance: (json["estimatedDistance"] as num).toDouble(),
      estimatedDuration: (json["estimatedDuration"] as num).toDouble(),
      actualDistance: json["actualDistance"] == null
          ? null
          : (json["actualDistance"] as num).toDouble(),
      actualDuration: json["actualDuration"] == null
          ? null
          : (json["actualDuration"] as num).toDouble(),
      vehicleType: json["vehicleType"],
      userRating: json["userRating"] == null
          ? null
          : (json["userRating"] as num).toDouble(),
      driverRating: json["driverRating"] == null
          ? null
          : (json["driverRating"] as num).toDouble(),
      userReview: json["userReview"],
      driverReview: json["driverReview"],
      acceptedAt: json["acceptedAt"],
      arrivedAt: json["arrivedAt"],
      startedAt: json["startedAt"],
      completedAt: json["completedAt"],
      cancelledAt: json["cancelledAt"],
      cancelledBy: json["cancelledBy"],
      cancellationReason: json["cancellationReason"],
      requestedAt: json["requestedAt"],
      createdAt: json["createdAt"],
      updatedAt: json["updatedAt"],
      v: json["__v"],
    );
  }
}

class PickupDropoff {
  final Location location;
  final String address;

  PickupDropoff({
    required this.location,
    required this.address,
  });

  factory PickupDropoff.fromJson(Map<String, dynamic> json) {
    return PickupDropoff(
      location: Location.fromJson(json["location"]),
      address: json["address"],
    );
  }
}

class Location {
  final String type;
  final List<double> coordinates;
  final String? address;
  final String? lastUpdated;

  Location({
    required this.type,
    required this.coordinates,
    this.address,
    this.lastUpdated,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json["type"],
      coordinates: List<double>.from(
          json["coordinates"].map((x) => (x as num).toDouble())),
      address: json["address"],
      lastUpdated: json["lastUpdated"],
    );
  }
}

class Driver {
  final Location currentLocation;
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlateNumber;
  final int rating;
  final String fullName;
  final String vehicleInfo;

  Driver({
    required this.currentLocation,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlateNumber,
    required this.rating,
    required this.fullName,
    required this.vehicleInfo,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      currentLocation: Location.fromJson(json["currentLocation"]),
      id: json["id"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      phone: json["phone"],
      vehicleType: json["vehicleType"],
      vehicleMake: json["vehicleMake"],
      vehicleModel: json["vehicleModel"],
      vehicleColor: json["vehicleColor"],
      vehiclePlateNumber: json["vehiclePlateNumber"],
      rating: json["rating"],
      fullName: json["fullName"],
      vehicleInfo: json["vehicleInfo"],
    );
  }
}
