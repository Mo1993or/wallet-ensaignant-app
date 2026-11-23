import '../entities/registration_result.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<RegistrationResult> call({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String pin,
    required String confirmPin,
    required String verificationToken,
    required String professionalCardVerificationToken,
  }) {
    return repository.register(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      pin: pin,
      confirmPin: confirmPin,
      verificationToken: verificationToken,
      professionalCardVerificationToken: professionalCardVerificationToken,
    );
  }
}
