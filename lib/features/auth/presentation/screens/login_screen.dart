import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../../app/app_theme.dart';
import '../providers/device_auth_providers.dart';
import '../../../../../app/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';
  String _message = '';
  String _firstName = '';

  Future<void> _loadAccountName() async {
    final secureStorage = ref.read(secureStorageProvider);

    final firstName = await secureStorage.getAccountFirstName();

    if (!mounted) return;

    setState(() {
      _firstName = firstName ?? '';
    });
  }

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isAuthenticating = false;

  void _addDigit(String digit) {
    if (_pin.length >= 4 || _isAuthenticating) return;

    setState(() {
      _pin += digit;
      _message = '';
    });

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 180), _submitPin);
    }
  }

  void _deleteDigit() {
    if (_pin.isEmpty || _isAuthenticating) return;

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _message = '';
    });
  }

  Future<void> _submitPin() async {
    if (!mounted || _isAuthenticating || _pin.length != 4) return;

    final enteredPin = _pin;

    setState(() {
      _isAuthenticating = true;
      _message = '';
    });

    try {
      final secureStorage = ref.read(secureStorageProvider);
      final phone = await secureStorage.getAccountPhone();

      if (phone == null || phone.isEmpty) {
        if (!mounted) return;

        context.go('/connexion');
        return;
      }

      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.login(phone: phone, pin: enteredPin);

      if (!mounted) return;

      if (result.requiresOtp) {
        context.go('/connexion', extra: {'requiresOtp': true});
        return;
      }

      if (result.success &&
          result.accessToken != null &&
          result.refreshToken != null) {
        context.go('/home');
        return;
      }

      setState(() {
        _pin = '';
        _message = result.message.isNotEmpty
            ? result.message
            : 'Impossible de vous connecter.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _pin = '';
        _message = 'Connexion impossible. Vérifiez votre code et réessayez.';
      });
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _forgotPin() {
    context.push('/forgot-pin');
  }

  Future<void> _biometric() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _message = '';
    });

    try {
      final bool isSupported = await _localAuth.isDeviceSupported();

      final bool canCheck = await _localAuth.canCheckBiometrics;

      if (!isSupported || !canCheck) {
        _showBiometricMessage(
          'La biométrie n’est pas disponible sur cet appareil.',
        );
        return;
      }

      final biometrics = await _localAuth.getAvailableBiometrics();

      if (biometrics.isEmpty) {
        _showBiometricMessage(
          'Configure Face ID ou ton empreinte dans les réglages du téléphone.',
        );
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour ouvrir Mon espace enseignant',
        biometricOnly: true,
      );

      if (!mounted || !authenticated) return;

      // La biométrie déverrouille localement l'accès.
      // Le serveur valide ensuite la session avec le refresh token.
      final authService = ref.read(deviceAuthServiceProvider);

      await authService.refreshSession();

      if (!mounted) return;

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      _showBiometricMessage(
        'Votre session doit être renouvelée. Connectez-vous avec votre PIN.',
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _showBiometricMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildFlag() {
    return Container(
      width: 28,
      height: 19,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Row(
        children: [
          Expanded(child: ColoredBox(color: Color(0xFF00853F))),
          Expanded(child: ColoredBox(color: Color(0xFFFDEF42))),
          Expanded(child: ColoredBox(color: Color(0xFFE31B23))),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Align(alignment: Alignment.centerLeft, child: _buildFlag());
  }

  Widget _buildProfile(bool compact) {
    return Column(
      children: [
        Container(
          width: compact ? 68 : 78,
          height: compact ? 68 : 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.08),
            border: Border.all(color: AppTheme.accent, width: 3),
          ),
          child: Icon(
            Icons.person_rounded,
            size: compact ? 36 : 42,
            color: AppTheme.primary,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          'Bonjour${_firstName.isNotEmpty ? ', $_firstName' : ''}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Saisissez votre code pour ouvrir\nMon espace enseignant',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final active = index < _pin.length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.primary : Colors.transparent,
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.border,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumberKey(String number) {
    return _buildKey(
      onTap: () => _addDigit(number),
      child: Text(
        number,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _buildKey(
      onTap: onTap,
      child: Icon(icon, color: AppTheme.primary, size: 26),
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: AppTheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _isAuthenticating ? null : onTap,
        child: Center(child: child),
      ),
    );
  }

  Widget _buildKeypad(double availableWidth) {
    const spacing = 12.0;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: 1.4,
      children: [
        for (int i = 1; i <= 9; i++) _buildNumberKey('$i'),
        _buildActionKey(icon: Icons.fingerprint, onTap: _biometric),
        _buildNumberKey('0'),
        _buildActionKey(icon: Icons.backspace_outlined, onTap: _deleteDigit),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAccountName();
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _forgotPin,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Code oublié ?',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.055),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 680;

                final horizontalPadding = constraints.maxWidth < 360
                    ? 20.0
                    : 26.0;

                final availableWidth =
                    constraints.maxWidth - horizontalPadding * 2;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 8 : 16,
                    horizontalPadding,
                    8,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (compact ? 16 : 24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        SizedBox(height: compact ? 14 : 22),
                        _buildProfile(compact),
                        SizedBox(height: compact ? 18 : 26),
                        _buildPinDots(),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 20,
                          child: _isAuthenticating
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.accent,
                                  ),
                                )
                              : Text(
                                  _message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        SizedBox(height: compact ? 8 : 14),
                        _buildKeypad(availableWidth),
                        _buildFooter(),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Créer un compte enseignant',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
