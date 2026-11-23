import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _installationIdKey = 'installation_id';
  static const String _deviceSecretKey = 'device_secret';
  static const String _phoneKey = 'account_phone';
  static const String _accountConfiguredKey = 'account_configured';

  static const String _firstNameKey = 'account_first_name';
  static const String _lastNameKey = 'account_last_name';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String> getOrCreateInstallationId() async {
    final existingId = await getInstallationId();

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    return renewInstallationId();
  }

  Future<String?> getInstallationId() => _storage.read(key: _installationIdKey);

  Future<String> renewInstallationId() async {
    final random = Random.secure();

    final installationId = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    await _storage.write(key: _installationIdKey, value: installationId);

    return installationId;
  }

  Future<void> saveDeviceSecret(String deviceSecret) =>
      _storage.write(key: _deviceSecretKey, value: deviceSecret);

  Future<String?> getDeviceSecret() => _storage.read(key: _deviceSecretKey);

  Future<void> clearDeviceSecret() => _storage.delete(key: _deviceSecretKey);

  Future<void> saveAccountPhone(String phone) =>
      _storage.write(key: _phoneKey, value: phone);

  Future<String?> getAccountPhone() => _storage.read(key: _phoneKey);

  Future<void> saveAccountName({
    required String firstName,
    required String lastName,
  }) async {
    await _storage.write(key: _firstNameKey, value: firstName.trim());

    await _storage.write(key: _lastNameKey, value: lastName.trim());
  }

  Future<String?> getAccountFirstName() => _storage.read(key: _firstNameKey);

  Future<String?> getAccountLastName() => _storage.read(key: _lastNameKey);

  Future<void> markAccountConfigured() =>
      _storage.write(key: _accountConfiguredKey, value: 'true');

  Future<bool> hasConfiguredAccount() async {
    final value = await _storage.read(key: _accountConfiguredKey);
    return value == 'true';
  }

  Future<void> clearAccountSession() async {
    await clearTokens();
    await clearDeviceSecret();
  }

  Future<void> clearAll() => _storage.deleteAll();
}
