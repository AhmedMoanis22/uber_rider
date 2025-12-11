class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: json['data'] != null
            ? AuthData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

/// Data contains driver object + tokens
class AuthData {
  final Driver driver;
  final String token;
  final String? refreshToken;

  AuthData({
    required this.driver,
    required this.token,
    this.refreshToken,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
        driver: Driver.fromJson(json['driver'] ?? json['user']),
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String?,
      );
}

/// Driver / User model
class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final bool isEmailVerified;
  final Vehicle? vehicle;
  final String? profileImage;
  final int? rating;

  Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.isEmailVerified,
    this.vehicle,
    this.profileImage,
    this.rating,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        role: json['role'],
        status: json['status'],
        isEmailVerified: json['isEmailVerified'],
        vehicle:
            json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
        profileImage: json['profileImage'],
        rating: json['rating'] is int
            ? json['rating']
            : int.tryParse(json['rating']?.toString() ?? ''),
      );
}

/// Vehicle model
class Vehicle {
  final String type;
  final String make;
  final String model;
  final int year;
  final String color;
  final String plateNumber;
  final String licenseNumber;

  Vehicle({
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plateNumber,
    required this.licenseNumber,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        type: json['type'],
        make: json['make'],
        model: json['model'],
        year: json['year'],
        color: json['color'],
        plateNumber: json['plateNumber'],
        licenseNumber: json['licenseNumber'],
      );
}
