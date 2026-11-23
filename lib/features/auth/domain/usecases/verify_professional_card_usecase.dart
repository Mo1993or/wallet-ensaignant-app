import '../entities/professional_card_verification_result.dart';
import '../repositories/auth_repository.dart';

class VerifyProfessionalCardUseCase {
  final AuthRepository repository;

  const VerifyProfessionalCardUseCase(this.repository);

  Future<ProfessionalCardVerificationResult> call({
    required String accessToken,
  }) {
    return repository.verifyProfessionalCard(accessToken: accessToken);
  }
}
