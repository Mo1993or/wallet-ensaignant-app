class OtpResult {
  final bool success;
  final String message;
  final int expiresIn;

  const OtpResult({
    required this.success,
    required this.message,
    required this.expiresIn,
  });
}

class OtpVerificationResult {
  final bool success;
  final bool verified;
  final String verificationToken;
  final DateTime proofExpiresAt;
  final String message;

  const OtpVerificationResult({
    required this.success,
    required this.verified,
    required this.verificationToken,
    required this.proofExpiresAt,
    required this.message,
  });
}
