import '../entities/otp_result.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  const SendOtpUseCase(this.repository);

  Future<OtpResult> call({required String phone}) {
    return repository.sendOtp(phone: phone);
  }
}
