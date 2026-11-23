
import '../../domain/entities/otp_result.dart';
import '../../domain/entities/registration_result.dart';
import '../../domain/entities/professional_card_verification_result.dart';

class SendOtpModel {
  final bool success;
  final String message;
  final int expiresIn;

  const SendOtpModel({
    required this.success,
    required this.message,
    required this.expiresIn,
  });

  factory SendOtpModel.fromJson(Map<String, dynamic> json) {
    return SendOtpModel(
      success: json['success'] == true,
      message: json['message'] ?? '',
      expiresIn: json['expiresIn'] ?? 180,
    );
  }

  OtpResult toEntity() =>
      OtpResult(success: success, message: message, expiresIn: expiresIn);
}

class VerifyOtpModel {
  final bool success;
  final bool verified;
  final String verificationToken;
  final DateTime proofExpiresAt;
  final String message;

  const VerifyOtpModel({
    required this.success,
    required this.verified,
    required this.verificationToken,
    required this.proofExpiresAt,
    required this.message,
  });

  factory VerifyOtpModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpModel(
      success: json['success'] == true,
      verified: json['verified'] == true,
      verificationToken: json['verificationToken'] ?? '',
      proofExpiresAt: DateTime.parse(json['proofExpiresAt']),
      message: json['message'] ?? '',
    );
  }

  OtpVerificationResult toEntity() => OtpVerificationResult(
    success: success,
    verified: verified,
    verificationToken: verificationToken,
    proofExpiresAt: proofExpiresAt,
    message: message,
  );
}

class ProfessionalCardVerificationModel {
  final String message;
  final String verificationToken;
  final int expiresIn;

  final String? matricule;
  final String? ien;

  final String? prenom;
  final String? nom;
  final String? nomComplet;
  final String? displayName;

  final String? emailPro;
  final String? telephone;

  final String? corps;
  final String? fonction;
  final String? typePersonnel;

  final Map<String, dynamic>? structure;

  const ProfessionalCardVerificationModel({
    required this.message,
    required this.verificationToken,
    required this.expiresIn,
    this.matricule,
    this.ien,
    this.prenom,
    this.nom,
    this.nomComplet,
    this.displayName,
    this.emailPro,
    this.telephone,
    this.corps,
    this.fonction,
    this.typePersonnel,
    this.structure,
  });

  factory ProfessionalCardVerificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfessionalCardVerificationModel(
      message: json['message'] ?? '',
      verificationToken: json['verificationToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 600,

      matricule: json['matricule']?.toString(),
      ien: json['ien']?.toString(),

      prenom: json['prenom']?.toString(),
      nom: json['nom']?.toString(),
      nomComplet: json['nomComplet']?.toString(),
      displayName: json['displayName']?.toString(),

      emailPro: json['emailPro']?.toString(),
      telephone: json['telephone']?.toString(),

      corps: json['corps']?.toString(),
      fonction: json['fonction']?.toString(),
      typePersonnel: json['typePersonnel']?.toString(),

      structure: json['structure'] == null
          ? null
          : Map<String, dynamic>.from(json['structure']),
    );
  }

  ProfessionalCardVerificationResult toEntity() {
    return ProfessionalCardVerificationResult(
      success: verificationToken.isNotEmpty,
      message: message,
      verificationToken: verificationToken,
      expiresIn: expiresIn,

      matricule: matricule,
      ien: ien,

      prenom: prenom,
      nom: nom,
      nomComplet: nomComplet,
      displayName: displayName,

      emailPro: emailPro,
      telephone: telephone,

      corps: corps,
      fonction: fonction,
      typePersonnel: typePersonnel,

      structure: structure,
    );
  }
}

class RegisteredUserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String matricule;
  final String ien;
  final String status;
  final DateTime createdAt;

  const RegisteredUserModel({
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

  factory RegisteredUserModel.fromJson(Map<String, dynamic> json) {
    return RegisteredUserModel(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      email: json['email'],
      matricule: json['matricule'],
      ien: json['ien'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  RegisteredUser toEntity() => RegisteredUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    phone: phone,
    email: email,
    matricule: matricule,
    ien: ien,
    status: status,
    createdAt: createdAt,
  );
}

class RegisterModel {
  final bool success;
  final String message;
  final RegisteredUserModel user;

  const RegisterModel({
    required this.success,
    required this.message,
    required this.user,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      success: json['success'] == true,
      message: json['message'] ?? '',
      user: RegisteredUserModel.fromJson(
        Map<String, dynamic>.from(json['user']),
      ),
    );
  }

  RegistrationResult toEntity() => RegistrationResult(
    success: success,
    message: message,
    user: user.toEntity(),
  );
}
