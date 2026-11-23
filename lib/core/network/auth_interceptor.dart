import 'package:dio/dio.dart';

import '../security/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;

  AuthInterceptor({required this.secureStorage});

  static const Set<String> _publicPaths = {
    'auth/register',
    'auth/send-otp',
    'auth/verify-otp',
    'auth/otp/send',
    'auth/otp/verify',
    'auth/device/login',
    'auth/device/verify-otp',
    'auth/device/refresh',
    'auth/device/logout',

    // Réinitialisation du PIN
    'auth/pin-reset/send-otp',
    'auth/pin-reset/verify-otp',
    'auth/pin-reset',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final path = options.path
          .replaceFirst(RegExp(r'^/+'), '')
          .split('?')
          .first;

      // Ces endpoints ne nécessitent pas de token d'accès.
      if (_publicPaths.contains(path)) {
        options.headers.remove('Authorization');
        handler.next(options);
        return;
      }

      final token = await secureStorage.getAccessToken();
      print("token $token");
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          message: 'Impossible de récupérer le jeton de session.',
        ),
      );
    }
  }
}
