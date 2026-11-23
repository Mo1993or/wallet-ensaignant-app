class DeviceLoginModel {
  final bool success;
  final bool requiresOtp;
  final String message;
  final int? expiresIn;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final DateTime? refreshExpiresAt;
  final DeviceAuthUserModel? user;
  final DeviceInfoModel? device;

  const DeviceLoginModel({
    required this.success,
    required this.requiresOtp,
    required this.message,
    this.expiresIn,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.refreshExpiresAt,
    this.user,
    this.device,
  });

  factory DeviceLoginModel.fromJson(Map<String, dynamic> json) {
    return DeviceLoginModel(
      success: json['success'] == true,
      requiresOtp: json['requiresOtp'] == true,
      message: json['message'] ?? '',
      expiresIn: json['expiresIn'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      refreshExpiresAt: json['refreshExpiresAt'] == null
          ? null
          : DateTime.parse(json['refreshExpiresAt']),
      user: json['user'] == null
          ? null
          : DeviceAuthUserModel.fromJson(
              Map<String, dynamic>.from(json['user']),
            ),
      device: json['device'] == null
          ? null
          : DeviceInfoModel.fromJson(Map<String, dynamic>.from(json['device'])),
    );
  }
}

class DeviceOtpVerificationModel {
  final bool success;
  final String message;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String deviceSecret;
  final DateTime refreshExpiresAt;
  final DeviceAuthUserModel user;
  final DeviceInfoModel device;

  const DeviceOtpVerificationModel({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.deviceSecret,
    required this.refreshExpiresAt,
    required this.user,
    required this.device,
  });

  factory DeviceOtpVerificationModel.fromJson(Map<String, dynamic> json) {
    return DeviceOtpVerificationModel(
      success: json['success'] == true,
      message: json['message'] ?? '',
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'] ?? 'Bearer',
      deviceSecret: json['deviceSecret'],
      refreshExpiresAt: DateTime.parse(json['refreshExpiresAt']),
      user: DeviceAuthUserModel.fromJson(
        Map<String, dynamic>.from(json['user']),
      ),
      device: DeviceInfoModel.fromJson(
        Map<String, dynamic>.from(json['device']),
      ),
    );
  }
}

class DeviceSessionModel {
  final bool success;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime refreshExpiresAt;

  const DeviceSessionModel({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.refreshExpiresAt,
  });

  factory DeviceSessionModel.fromJson(Map<String, dynamic> json) {
    return DeviceSessionModel(
      success: json['success'] == true,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'] ?? 'Bearer',
      refreshExpiresAt: DateTime.parse(json['refreshExpiresAt']),
    );
  }
}

class DeviceAuthUserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String status;

  const DeviceAuthUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.status,
  });

  factory DeviceAuthUserModel.fromJson(Map<String, dynamic> json) {
    return DeviceAuthUserModel(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      email: json['email'],
      status: json['status'],
    );
  }
}

class DeviceInfoModel {
  final String id;
  final String installationId;
  final String? deviceName;
  final String platform;

  const DeviceInfoModel({
    required this.id,
    required this.installationId,
    this.deviceName,
    required this.platform,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      id: json['id'],
      installationId: json['installationId'],
      deviceName: json['deviceName'],
      platform: json['platform'],
    );
  }
}
