import 'package:dio/dio.dart';

import '../../app/app_config.dart';
import '../security/secure_storage_service.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create({required SecureStorageService secureStorage}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(secureStorage: secureStorage));

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: false,
      ),
    );

    return dio;
  }
}
