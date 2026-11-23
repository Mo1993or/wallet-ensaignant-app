import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

enum AppStartupDestination { register, login, reconnect }

class InstallationStateService {
  static const String _installationMarkerKey =
      'wallet_installation_initialized';

  final SecureStorageService _secureStorage;

  InstallationStateService({required SecureStorageService secureStorage})
    : _secureStorage = secureStorage;

  Future<AppStartupDestination> resolveDestination() async {
    final preferences = await SharedPreferences.getInstance();

    final markerExists = preferences.getBool(_installationMarkerKey) ?? false;

    final accountConfigured = await _secureStorage.hasConfiguredAccount();

    // Première ouverture ou réinstallation :
    // on considère qu'il s'agit d'une nouvelle installation.
    if (!markerExists) {
      await preferences.setBool(_installationMarkerKey, true);

      // Nettoyage des anciennes données conservées dans le Keychain.
      if (accountConfigured) {
        await _secureStorage.clearAccountSession();
      }

      return AppStartupDestination.register;
    }

    // Aucun compte configuré localement.
    if (!accountConfigured) {
      return AppStartupDestination.register;
    }

    final installationId = await _secureStorage.getInstallationId();
    final deviceSecret = await _secureStorage.getDeviceSecret();
    final phone = await _secureStorage.getAccountPhone();

    // Informations de confiance de l'appareil manquantes.
    if (installationId == null ||
        installationId.isEmpty ||
        deviceSecret == null ||
        deviceSecret.isEmpty ||
        phone == null ||
        phone.isEmpty) {
      await _prepareReconnection();
      return AppStartupDestination.reconnect;
    }

    // Installation connue et appareil déjà enregistré.
    return AppStartupDestination.login;
  }

  Future<void> _prepareReconnection() async {
    await _secureStorage.clearAccountSession();
    await _secureStorage.renewInstallationId();
  }
}
