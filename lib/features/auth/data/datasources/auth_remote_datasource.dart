import 'package:dio/dio.dart';
import 'package:wallet_enseignant/features/auth/data/models/auth_models.dart';

import '../../domain/entities/auth_exception.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Future<SendOtpModel> sendOtp(String phone) async {
    try {
      final response = await dio.post('auth/send-otp', data: {'phone': phone});

      return SendOtpModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<VerifyOtpModel> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        'auth/verify-otp',
        data: {'phone': phone, 'code': code},
      );

      return VerifyOtpModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Vérification automatique de la carte professionnelle via APPS.
  /// Le matricule et l'IEN sont récupérés directement depuis APPS.
  Future<ProfessionalCardVerificationModel> verifyProfessionalCard({
    required String accessToken,
  }) async {
    try {
      final response = await dio.post(
        'teachers/carte-pro/verify',
        data: {'accessToken': accessToken},
      );

      return ProfessionalCardVerificationModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Création du compte Wallet Enseignant.
  Future<RegisterModel> register(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('auth/register', data: data);

      return RegisterModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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
