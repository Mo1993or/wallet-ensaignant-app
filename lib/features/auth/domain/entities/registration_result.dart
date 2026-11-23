class RegisteredUser {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String matricule;
  final String ien;
  final String status;
  final DateTime createdAt;

  const RegisteredUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.matricule,
    required this.ien,
    required this.status,
    required this.createdAt,
  });
}

class RegistrationResult {
  final bool success;
  final String message;
  final RegisteredUser user;

  const RegistrationResult({
    required this.success,
    required this.message,
    required this.user,
  });
}
