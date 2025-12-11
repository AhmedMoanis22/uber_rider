import 'dart:io';

import 'exceptions.dart';

class ErrorParser {
  static AppException parse(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is SocketException) {
      return NetworkException();
    }

    if (error is TimeoutException) {
      return TimeoutException();
    }

    if (error is FormatException) {
      return ValidationException('Invalid data format');
    }

    return AppException(error.toString());
  }

  static String getErrorMessage(dynamic error) {
    final exception = parse(error);
    return exception.message;
  }
}
