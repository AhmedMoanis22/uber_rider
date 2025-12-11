class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'No internet connection'])
      : super(code: 'network_error');
}

class ServerException extends AppException {
  ServerException([super.message = 'Server error occurred'])
      : super(code: 'server_error');
}

class AuthException extends AppException {
  AuthException([super.message = 'Authentication failed'])
      : super(code: 'auth_error');
}

class ValidationException extends AppException {
  ValidationException([super.message = 'Validation failed'])
      : super(code: 'validation_error');
}

class NotFoundException extends AppException {
  NotFoundException([super.message = 'Resource not found'])
      : super(code: 'not_found');
}

class TimeoutException extends AppException {
  TimeoutException([super.message = 'Request timeout'])
      : super(code: 'timeout');
}
