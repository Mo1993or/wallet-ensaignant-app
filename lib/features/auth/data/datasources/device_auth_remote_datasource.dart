import 'package:dio/dio.dart';
import 'package:wallet_enseignant/features/auth/data/models/device_auth_model.dart';

import '../../domain/entities/auth_exception.dart';

class DeviceAuthRemoteDataSource {
  final Dio dio;

  DeviceAuthRemoteDataSource({required this.dio});

  /// Connexion avec téléphone + PIN.
  ///
  /// Appareil reconnu : retourne directement une session.
  /// Nouvel appareil : retourne requiresOtp = true.
  Future<DeviceLoginModel> login({
    required String phone,
    required String pin,
    required String installationId,
    required String platform,
    String? deviceName,
    String? deviceSecret,
  }) async {
    try {
      final response = await dio.post(
        'auth/device/login',
        data: {
          'phone': phone,
          'pin': pin,
          'installationId': installationId,
          'platform': platform,
          if (deviceName != null) 'deviceName': deviceName,
          if (deviceSecret != null) 'deviceSecret': deviceSecret,
        },
      );

      return DeviceLoginModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Vérification SMS et enregistrement de l'appareil.
  Future<DeviceOtpVerificationModel> verifyOtp({
    required String phone,
    required String installationId,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        'auth/device/verify-otp',
        data: {'phone': phone, 'installationId': installationId, 'code': code},
      );

      return DeviceOtpVerificationModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Renvoi du code OTP pour un appareil en attente de vérification.
  Future<Map<String, dynamic>> resendDeviceOtp({
    required String phone,
    required String installationId,
  }) async {
    try {
      final response = await dio.post(
        'auth/device/resend-otp',
        data: {'phone': phone, 'installationId': installationId},
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Renouvellement de session.
  Future<DeviceSessionModel> refresh({required String refreshToken}) async {
    try {
      final response = await dio.post(
        'auth/device/refresh',
        data: {'refreshToken': refreshToken},
      );

      return DeviceSessionModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Déconnexion et révocation du refresh token.
  Future<void> logout({required String refreshToken}) async {
    try {
      await dio.post(
        'auth/device/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // RÉINITIALISATION DU PIN
  // ============================================================

  /// Étape 1 : demander un code OTP pour réinitialiser le PIN.
  Future<Map<String, dynamic>> sendPinResetOtp({required String phone}) async {
    try {
      final response = await dio.post(
        'auth/pin-reset/send-otp',
        data: {'phone': phone},
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Étape 2 : vérifier le code OTP.
  Future<Map<String, dynamic>> verifyPinResetOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        'auth/pin-reset/verify-otp',
        data: {'phone': phone, 'code': code},
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Étape 3 : enregistrer le nouveau PIN.
  Future<Map<String, dynamic>> resetPin({
    required String phone,
    required String verificationToken,
    required String newPin,
    required String confirmPin,
  }) async {
    try {
      final response = await dio.post(
        'auth/pin-reset',
        data: {
          'phone': phone,
          'verificationToken': verificationToken,
          'newPin': newPin,
          'confirmPin': confirmPin,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GESTION DES ERREURS
  // ============================================================

  AuthException _handleError(DioException error) {
    final data = error.response?.data;

    String message = 'Une erreur est survenue. Réessayez.';

    if (data is Map) {
      final apiMessage = data['message'];

      if (apiMessage is String) {
        message = apiMessage;
      } else if (apiMessage is List) {
        message = apiMessage.join('\n');
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'Le serveur met trop de temps à répondre.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
    }

    return AuthException(
      message: message,
      statusCode: error.response?.statusCode,
    );
  }
}
