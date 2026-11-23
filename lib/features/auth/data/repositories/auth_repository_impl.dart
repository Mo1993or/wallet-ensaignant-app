import '../../domain/entities/otp_result.dart';
import '../../domain/entities/registration_result.dart';
import '../../domain/entities/professional_card_verification_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<OtpResult> sendOtp({required String phone}) async {
    final result = await remoteDataSource.sendOtp(phone);
    return result.toEntity();
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final result = await remoteDataSource.verifyOtp(phone: phone, code: code);

    return result.toEntity();
  }

  @override
  Future<ProfessionalCardVerificationResult> verifyProfessionalCard({
    required String accessToken,
  }) async {
    final result = await remoteDataSource.verifyProfessionalCard(
      accessToken: accessToken,
    );

    return result.toEntity();
  }

  @override
  Future<RegistrationResult> register({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String pin,
    required String confirmPin,
    required String verificationToken,
    required String professionalCardVerificationToken,
  }) async {
    final result = await remoteDataSource.register({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'pin': pin,
      'confirmPin': confirmPin,
      'verificationToken': verificationToken,
      'professionalCardVerificationToken': professionalCardVerificationToken,
    });

    return result.toEntity();
  }
}
