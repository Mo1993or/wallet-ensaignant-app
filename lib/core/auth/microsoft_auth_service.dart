import 'dart:io';

import 'package:msal_auth_plugin/msal_auth_plugin.dart';

class MicrosoftAuthService {
  static const String clientId = '94d9b948-1bdc-4067-846d-e25fab09b15d';
  static const String tenantId = 'a2972496-9c71-4996-be35-b25c7a16a880';

  static const String iosRedirectUri =
      'msauth.com.sycapay.walletEnseignant://auth';

  static const String androidRedirectUri =
      'msauth://com.sycapay.walletEnseignant/OgdlsR8PnLTlDJutCWTP8uDIBXE%3D';

  // Scope Microsoft Graph existant.
  static const List<String> defaultScopes = ['User.Read'];

  // Scope dédié à l'API APPS - Carte professionnelle.
  static const List<String> carteProScopes = [
    'api://271ece8a-907f-4905-a4d5-f0866f0650b4/CartePro.Read',
  ];

  bool get isConfigured =>
      clientId.isNotEmpty &&
      tenantId.isNotEmpty &&
      (Platform.isIOS
          ? iosRedirectUri.isNotEmpty
          : androidRedirectUri.isNotEmpty);

  String get redirectUri =>
      Platform.isIOS ? iosRedirectUri : androidRedirectUri;

  Future<void> initialize() async {
    if (!isConfigured) {
      throw Exception('Configuration Microsoft incomplète.');
    }

    await MsalAuth.initialize(
      clientId: clientId,
      authority: 'https://login.microsoftonline.com/$tenantId',
      redirectUri: redirectUri,
      tanantId: tenantId,
    );

    print('MSAL initialized successfully.');
  }

  /// Connexion interactive Microsoft.
  Future<AuthResult> signIn({List<String>? scopes}) async {
    if (!isConfigured) {
      throw Exception('Configuration Microsoft manquante.');
    }

    final requestedScopes = scopes ?? defaultScopes;

    try {
      final authResult = await MsalAuth.signIn(scopes: requestedScopes);

      print('Microsoft authentication successful.');
      print('Granted scopes: ${authResult.scopes}');
      print('Expiration: ${authResult.expiresOn}');

      // Ne jamais afficher les Access Tokens ou ID Tokens.
      return authResult;
    } catch (e) {
      print('Microsoft sign in error: $e');
      rethrow;
    }
  }

  /// Récupération silencieuse du token.
  Future<AuthResult> acquireTokenSilent({List<String>? scopes}) async {
    final requestedScopes = scopes ?? defaultScopes;

    try {
      final authResult = await MsalAuth.acquireTokenSilent(
        scopes: requestedScopes,
      );

      print('Silent token acquisition successful.');
      print('Granted scopes: ${authResult.scopes}');
      print('Expiration: ${authResult.expiresOn}');

      // Ne jamais afficher les Access Tokens ou ID Tokens.
      return authResult;
    } catch (e) {
      print('Silent token acquisition error: $e');
      rethrow;
    }
  }

  /// Token Microsoft Graph existant.
  Future<String> getAccessToken({List<String>? scopes}) async {
    final authResult = await acquireTokenSilent(scopes: scopes);

    return authResult.accessToken;
  }

  /// Récupération du token APPS CartePro.Read.
  ///
  /// 1. Essaye de récupérer le token silencieusement.
  /// 2. Si la récupération silencieuse échoue, demande
  ///    une authentification interactive avec le scope APPS.
  Future<String> getCarteProAccessToken() async {
    try {
      final authResult = await acquireTokenSilent(scopes: carteProScopes);

      return authResult.accessToken;
    } catch (_) {
      final authResult = await signIn(scopes: carteProScopes);

      return authResult.accessToken;
    }
  }

  Future<Map<String, dynamic>?> getCurrentAccount() async {
    return MsalAuth.getCurrentAccount();
  }

  Future<void> signOut() async {
    await MsalAuth.signOut();
    print('Microsoft sign out successful.');
  }
}
