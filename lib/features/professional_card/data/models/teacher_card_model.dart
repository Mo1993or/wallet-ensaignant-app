class TeacherCardStructureModel {
  final String? codeStr;
  final String? libelle;

  const TeacherCardStructureModel({this.codeStr, this.libelle});

  factory TeacherCardStructureModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TeacherCardStructureModel();
    }

    return TeacherCardStructureModel(
      codeStr: json['codeStr']?.toString(),
      libelle: json['libelle']?.toString(),
    );
  }
}

class TeacherCardPhotoModel {
  final String? type;
  final String? base64;

  const TeacherCardPhotoModel({this.type, this.base64});

  factory TeacherCardPhotoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TeacherCardPhotoModel();
    }

    return TeacherCardPhotoModel(
      type: json['type']?.toString(),
      base64: json['base64']?.toString(),
    );
  }
}

class TeacherCardModel {
  final String? ien;
  final String? matricule;

  final String? firstName;
  final String? lastName;
  final String? fullName;

  final String? corps;
  final String? function;

  final String? typePersonnel;

  final String? qrCode;
  final String? professionalEmail;
  final String? telephone;

  final TeacherCardStructureModel? structure;
  final TeacherCardPhotoModel? photo;

  final String? source;
  final DateTime? syncedAt;

  const TeacherCardModel({
    this.ien,
    this.matricule,
    this.firstName,
    this.lastName,
    this.fullName,
    this.corps,
    this.function,
    this.typePersonnel,
    this.qrCode,
    this.professionalEmail,
    this.telephone,
    this.structure,
    this.photo,
    this.source,
    this.syncedAt,
  });

  factory TeacherCardModel.fromJson(Map<String, dynamic> json) {
    final cardData = json['card'] is Map
        ? Map<String, dynamic>.from(json['card'] as Map)
        : json;

    final structureData = cardData['structure'] is Map
        ? Map<String, dynamic>.from(cardData['structure'] as Map)
        : null;

    final photoData = cardData['photo'] is Map
        ? Map<String, dynamic>.from(cardData['photo'] as Map)
        : null;

    return TeacherCardModel(
      ien: cardData['ien']?.toString(),
      matricule: cardData['matricule']?.toString(),

      firstName: cardData['prenom']?.toString(),
      lastName: cardData['nom']?.toString(),
      fullName: cardData['nomComplet']?.toString(),

      corps: cardData['corps']?.toString(),
      function: cardData['fonction']?.toString(),

      typePersonnel: cardData['typePersonnel']?.toString(),

      qrCode: cardData['qrCode']?.toString(),
      professionalEmail: cardData['emailPro']?.toString(),
      telephone: cardData['telephone']?.toString(),

      structure: structureData == null
          ? null
          : TeacherCardStructureModel.fromJson(structureData),

      photo: photoData == null
          ? null
          : TeacherCardPhotoModel.fromJson(photoData),

      source: json['source']?.toString(),

      syncedAt: json['syncedAt'] is String
          ? DateTime.tryParse(json['syncedAt'] as String)
          : null,
    );
  }
}
