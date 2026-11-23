import '../entities/otp_result.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  const VerifyOtpUseCase(this.repository);

  Future<OtpVerificationResult> call({
    required String phone,
    required String code,
  }) {
    return repository.verifyOtp(phone: phone, code: code);
  }
}
