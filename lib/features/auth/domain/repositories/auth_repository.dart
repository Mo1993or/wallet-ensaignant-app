import '../entities/otp_result.dart';
import '../entities/registration_result.dart';
import '../entities/professional_card_verification_result.dart';

abstract class AuthRepository {
  Future<OtpResult> sendOtp({required String phone});

  Future<OtpVerificationResult> verifyOtp({
    required String phone,
    required String code,
  });

  Future<ProfessionalCardVerificationResult> verifyProfessionalCard({
    required String accessToken,
  });

  Future<RegistrationResult> register({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String pin,
    required String confirmPin,
    required String verificationToken,
    required String professionalCardVerificationToken,
  });
}
