class AppConfig {
  AppConfig._();

  static const String appName = 'Mon espace enseignant';

  static const String apiBaseUrl = String.fromEnvironment(
    'http://localhost:3000/api/v1/',
    defaultValue: 'http://localhost:3000/api/v1/',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
