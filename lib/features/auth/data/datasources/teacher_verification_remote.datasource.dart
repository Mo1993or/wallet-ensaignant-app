import 'package:dio/dio.dart';

class TeacherVerificationRemoteDataSource {
  final Dio dio;

  TeacherVerificationRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> verifyTeacher({
    required String matricule,
    required String ien,
  }) async {
    try {
      final response = await dio.post(
        'teacher-verification/verify',
        data: {'matricule': matricule.trim(), 'ien': ien.trim().toUpperCase()},
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException {
      rethrow;
    }
  }
}
