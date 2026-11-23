class ProfessionalCardVerificationResult {
  final bool success;
  final String message;
  final String verificationToken;
  final int expiresIn;

  // Identité professionnelle APPS
  final String? matricule;
  final String? ien;

  // Informations personnelles APPS
  final String? prenom;
  final String? nom;
  final String? nomComplet;
  final String? displayName;

  // Coordonnées professionnelles
  final String? emailPro;
  final String? telephone;

  // Informations administratives
  final String? corps;
  final String? fonction;
  final String? typePersonnel;

  // Structure de rattachement
  final Map<String, dynamic>? structure;

  const ProfessionalCardVerificationResult({
    required this.success,
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
}
