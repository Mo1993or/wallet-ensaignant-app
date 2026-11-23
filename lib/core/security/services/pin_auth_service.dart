import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinAuthService {
  PinAuthService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _pinKey = 'wallet_security_pin';

  static int _failedAttempts = 0;
  static DateTime? _lockUntil;

  static const int maxAttempts = 3;
  static const Duration lockDuration = Duration(seconds: 30);

  /// Vérifie si un code PIN est déjà enregistré.
  static Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Enregistre ou remplace le code PIN.
  /// À appeler après confirmation du nouveau PIN.
  static Future<void> savePin(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError('Le code PIN doit contenir 4 chiffres.');
    }

    await _storage.write(key: _pinKey, value: pin);

    _failedAttempts = 0;
    _lockUntil = null;
  }

  /// Vérifie le PIN saisi.
  static Future<bool> verifyPin(String pin) async {
    if (isLocked) return false;

    final savedPin = await _storage.read(key: _pinKey);

    if (savedPin == null) return false;

    if (pin == savedPin) {
      _failedAttempts = 0;
      _lockUntil = null;
      return true;
    }

    _failedAttempts++;

    if (_failedAttempts >= maxAttempts) {
      _failedAttempts = 0;
      _lockUntil = DateTime.now().add(lockDuration);
    }

    return false;
  }

  static bool get isLocked {
    final lock = _lockUntil;

    if (lock == null) return false;

    if (DateTime.now().isBefore(lock)) return true;

    _lockUntil = null;
    return false;
  }

  static int get remainingAttempts => maxAttempts - _failedAttempts;

  static int get remainingLockSeconds {
    final lock = _lockUntil;

    if (lock == null) return 0;

    final remaining = lock.difference(DateTime.now()).inSeconds;

    return remaining > 0 ? remaining + 1 : 0;
  }

  /// Réinitialisation du PIN après authentification préalable.
  static Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    _failedAttempts = 0;
    _lockUntil = null;
  }
}
