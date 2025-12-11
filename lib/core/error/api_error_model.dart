class ApiErrorModel {
  final String? message;
  final int? code;
  final dynamic errors;

  ApiErrorModel({
    this.message,
    this.code,
    this.errors,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      message: json['message'] as String?,
      code: json['code'] as int?,
      errors: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'data': errors,
    };
  }

  String getAllErrorMessages() {
    if (errors == null || errors is List && (errors as List).isEmpty) {
      return message ?? "Unknown Error occurred";
    }

    if (errors is Map<String, dynamic>) {
      final errorMessage =
          (errors as Map<String, dynamic>).entries.map((entry) {
        final value = entry.value;
        return "${value.join(',')}";
      }).join('\n');

      return errorMessage;
    } else if (errors is List) {
      return (errors as List).join('\n');
    }

    return message ?? "Unknown Error occurred";
  }
}
