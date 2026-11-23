import 'package:dio/dio.dart';

import '../models/teacher_card_model.dart';

class TeacherCardException implements Exception {
  final String message;
  final int? statusCode;

  const TeacherCardException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class TeacherCardRemoteDataSource {
  final Dio dio;

  TeacherCardRemoteDataSource({required this.dio});

  /// Récupère la carte professionnelle de l'utilisateur connecté.
  ///
  /// Le JWT est transmis automatiquement par l'intercepteur Dio.
  Future<TeacherCardModel> getMyCard() async {
    try {
      final response = await dio.get('teachers/carte-pro');
      print("response status code ${response.statusCode}");
      print("response ${response.data}");
      final responseData = Map<String, dynamic>.from(response.data as Map);
      print("responseData $responseData");
      return TeacherCardModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _handleError(e);
    } on TypeError catch (_) {
      throw const TeacherCardException(
        message: 'Les données de la carte professionnelle sont invalides.',
      );
    } on FormatException catch (_) {
      throw const TeacherCardException(
        message: 'Le format des données de la carte est invalide.',
      );
    }
  }

  TeacherCardException _handleError(DioException error) {
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

    return TeacherCardException(
      message: message,
      statusCode: error.response?.statusCode,
    );
  }
}
