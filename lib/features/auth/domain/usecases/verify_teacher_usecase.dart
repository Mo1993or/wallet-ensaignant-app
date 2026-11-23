import 'package:wallet_enseignant/features/auth/data/datasources/teacher_verification_remote.datasource.dart';

class VerifyTeacherUseCase {
  final TeacherVerificationRemoteDataSource dataSource;

  VerifyTeacherUseCase(this.dataSource);

  Future<Map<String, dynamic>> call({
    required String matricule,
    required String ien,
  }) {
    return dataSource.verifyTeacher(matricule: matricule, ien: ien);
  }
}
