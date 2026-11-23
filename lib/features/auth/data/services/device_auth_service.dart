import 'dart:io';

import 'package:wallet_enseignant/core/security/secure_storage_service.dart';
import 'package:wallet_enseignant/features/auth/data/models/device_auth_model.dart';

import '../datasources/device_auth_remote_datasource.dart';

class DeviceAuthService {
  final DeviceAuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  DeviceAuthService({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  // ============================================================
  // CONNEXION
  // ============================================================

  Future<DeviceLoginModel> login({
    required String phone,
    required String pin,
  }) async {
    final installationId = await secureStorage.getOrCreateInstallationId();

    final deviceSecret = await secureStorage.getDeviceSecret();

    final platform = Platform.isIOS ? 'ios' : 'android';

    final result = await remoteDataSource.login(
      phone: phone,
      pin: pin,
      installationId: installationId,
      platform: platform,
      deviceName: Platform.isIOS ? 'iPhone' : 'Android',
      deviceSecret: deviceSecret,
    );

    if (!result.success) {
      return result;
    }

    await secureStorage.saveAccountPhone(phone);
    await secureStorage.markAccountConfigured();

    if (result.user != null) {
      await secureStorage.saveAccountName(
        firstName: result.user!.firstName,
        lastName: result.user!.lastName,
      );
    }

    if (!result.requiresOtp &&
        result.accessToken != null &&
        result.refreshToken != null) {
      await secureStorage.saveTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken!,
      );
    }

    return result;
  }

  // ============================================================
  // VÉRIFICATION OTP D'UN NOUVEL APPAREIL
  // ============================================================

  Future<DeviceOtpVerificationModel> verifyDeviceOtp({
    required String phone,
    required String code,
  }) async {
    final installationId = await secureStorage.getOrCreateInstallationId();

    final result = await remoteDataSource.verifyOtp(
      phone: phone,
      installationId: installationId,
      code: code,
    );

    if (result.success) {
      await secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      await secureStorage.saveDeviceSecret(result.deviceSecret);
      await secureStorage.saveAccountPhone(phone);
      await secureStorage.markAccountConfigured();

      await secureStorage.saveAccountName(
        firstName: result.user.firstName,
        lastName: result.user.lastName,
      );
    }

    return result;
  }

  // ============================================================
  // RENVOI OTP D'UN NOUVEL APPAREIL
  // ============================================================

  Future<Map<String, dynamic>> resendDeviceOtp({required String phone}) async {
    final installationId = await secureStorage.getOrCreateInstallationId();

    return remoteDataSource.resendDeviceOtp(
      phone: phone,
      installationId: installationId,
    );
  }

  // ============================================================
  // RENOUVELLEMENT DE SESSION
  // ============================================================

  Future<DeviceSessionModel> refreshSession() async {
    final refreshToken = await secureStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Aucun refresh token disponible.');
    }

    final result = await remoteDataSource.refresh(refreshToken: refreshToken);

    if (result.success) {
      await secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
    }

    return result;
  }

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  Future<void> logout() async {
    final refreshToken = await secureStorage.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await remoteDataSource.logout(refreshToken: refreshToken);
      }
    } finally {
      // On supprime uniquement les tokens.
      // L'appareil reste reconnu pour une prochaine connexion.
      await secureStorage.clearTokens();
    }
  }

  // ============================================================
  // RÉINITIALISATION DU PIN
  // ============================================================

  /// Étape 1 : demander l'envoi du code OTP.
  Future<Map<String, dynamic>> sendPinResetOtp({required String phone}) async {
    return remoteDataSource.sendPinResetOtp(phone: phone);
  }

  /// Étape 2 : vérifier le code OTP.
  Future<Map<String, dynamic>> verifyPinResetOtp({
    required String phone,
    required String code,
  }) async {
    return remoteDataSource.verifyPinResetOtp(phone: phone, code: code);
  }

  /// Étape 3 : enregistrer le nouveau PIN.
  Future<Map<String, dynamic>> resetPin({
    required String phone,
    required String verificationToken,
    required String newPin,
    required String confirmPin,
  }) async {
    final result = await remoteDataSource.resetPin(
      phone: phone,
      verificationToken: verificationToken,
      newPin: newPin,
      confirmPin: confirmPin,
    );

    if (result['success'] == true) {
      // Efface les tokens et le deviceSecret.
      // L'installationId est conservé.
      await secureStorage.clearAccountSession();
    }

    return result;
  }
}
