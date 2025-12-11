import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../storage/secure_storage_helper.dart';
import 'api_constant.dart';

class DioFactory {
  /// private constructor as I don't want to allow creating an instance of this class
  DioFactory._();

  static Dio? dio;

  static Dio getDio() {
    Duration timeOut = const Duration(seconds: 300);

    if (dio == null) {
      dio = Dio();
      init();
      dio!
        ..options.connectTimeout = timeOut
        ..options.receiveTimeout = timeOut;
      addDioInterceptor();
      addAuthInterceptor();
      return dio!;
    } else {
      return dio!;
    }
  }

  static void addDioInterceptor() {
    dio?.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );
  }

  static void addAuthInterceptor() {
    dio?.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token from secure storage
          final token = await SecureStorageHelper.getToken();

          if (token != null && token.isNotEmpty) {
            // Add Bearer token to headers
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - token expired
          if (error.response?.statusCode == 401) {
            // Optionally: Try to refresh token here
            // For now, just pass the error
          }

          return handler.next(error);
        },
      ),
    );
  }

  static void init() {
    dio = Dio(
      BaseOptions(
          baseUrl: ApiConstance.baseUrl,
          receiveDataWhenStatusError: true,
          connectTimeout: const Duration(seconds: 300),
          receiveTimeout: const Duration(seconds: 300),
          headers: {
            'Content-Type': 'application/json',
          }),
    );
  }
}
