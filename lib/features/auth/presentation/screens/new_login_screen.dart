import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/app_providers.dart';
import '../providers/device_auth_providers.dart';
import '../../domain/entities/auth_exception.dart';

class NewLoginScreen extends ConsumerStatefulWidget {
  const NewLoginScreen({super.key});

  @override
  ConsumerState<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends ConsumerState<NewLoginScreen> {
  final PageController _pageController = PageController();

  final List<GlobalKey<FormState>> _formKeys = List.generate(
    3,
    (_) => GlobalKey<FormState>(),
  );

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();

  int _currentStep = 0;
  bool _obscurePin = true;
  bool _isLoading = false;
  int _resendCooldown = 0;

  Timer? _resendTimer;

  // true lorsque le PIN a déjà été validé dans LoginScreen.
  bool _otpOnlyFlow = false;

  final Color _primary = AppTheme.primary;

  final List<String> _titles = [
    'Retrouver votre compte',
    'Votre code PIN',
    'Vérification de sécurité',
  ];

  final List<String> _subtitles = [
    'Entrez le numéro associé à votre compte enseignant.',
    'Saisissez votre code PIN personnel pour continuer.',
    'Saisissez le code reçu par SMS pour confirmer votre identité.',
  ];

  String get _formattedPhone => '+221 ${_phoneController.text}';

  String get _phoneE164 {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '+221$digits';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFlow();
    });
  }

  Future<void> _initializeFlow() async {
    if (!mounted) return;

    final extra = GoRouterState.of(context).extra;
    final requiresOtp = extra is Map && extra['requiresOtp'] == true;

    if (!requiresOtp) return;

    final secureStorage = ref.read(secureStorageProvider);
    final phone = await secureStorage.getAccountPhone();

    if (!mounted) return;

    if (phone == null || phone.isEmpty) {
      _showMessage(
        'Numéro de téléphone introuvable. Recommencez la connexion.',
      );
      return;
    }

    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final localNumber = digits.startsWith('221') ? digits.substring(3) : digits;

    _phoneController.text = localNumber;
    _otpOnlyFlow = true;

    _startResendCooldown();

    _goToStep(2);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _pageController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // COMPTE À REBOURS DU RENVOI OTP
  // ============================================================

  void _startResendCooldown() {
    _resendTimer?.cancel();

    setState(() {
      _resendCooldown = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldown <= 1) {
        timer.cancel();

        setState(() {
          _resendCooldown = 0;
        });

        return;
      }

      setState(() {
        _resendCooldown--;
      });
    });
  }

  String _formatCooldown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$remainingSeconds';
  }

  // ============================================================
  // RENVOI DU CODE OTP
  // ============================================================

  Future<void> _resendDeviceOtp() async {
    if (_isLoading || _resendCooldown > 0) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.resendDeviceOtp(phone: _phoneE164);

      if (!mounted) return;

      if (result['success'] == true) {
        _otpController.clear();

        _startResendCooldown();

        _showMessage(
          result['message']?.toString() ??
              'Un nouveau code de vérification a été envoyé par SMS.',
        );
      } else {
        _showMessage(
          result['message']?.toString() ?? 'Impossible de renvoyer le code.',
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Impossible de renvoyer le code. Vérifiez votre connexion.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _nextStep() async {
    if (_isLoading) return;

    if (!(_formKeys[_currentStep].currentState?.validate() ?? false)) {
      return;
    }

    if (_currentStep == 0) {
      _goToStep(1);
      return;
    }

    if (_currentStep == 1) {
      await _loginWithPin();
      return;
    }

    if (_currentStep == 2) {
      await _confirmReconnection();
    }
  }

  Future<void> _loginWithPin() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.login(
        phone: _phoneE164,
        pin: _pinController.text,
      );

      if (!mounted) return;

      if (result.requiresOtp) {
        _otpOnlyFlow = true;
        _otpController.clear();

        _startResendCooldown();

        _goToStep(2);
        return;
      }

      if (result.success &&
          result.accessToken != null &&
          result.refreshToken != null) {
        context.go('/home');
        return;
      }

      _showMessage(
        result.message.isNotEmpty
            ? result.message
            : 'Impossible de retrouver votre compte.',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur inattendue : $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousStep() {
    if (_isLoading) return;

    if (_otpOnlyFlow && _currentStep == 2) {
      context.pop();
      return;
    }

    if (_currentStep == 0) {
      context.pop();
      return;
    }

    _goToStep(_currentStep - 1);
  }

  void _goToStep(int step) {
    if (!mounted) return;

    setState(() => _currentStep = step);

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(step);
        }
      });
    }
  }

  // ============================================================
  // CONFIRMATION OTP
  // ============================================================

  Future<void> _confirmReconnection() async {
    if (_isLoading) return;

    if (!(_formKeys[2].currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.verifyDeviceOtp(
        phone: _phoneE164,
        code: _otpController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        context.go('/home');
        return;
      }

      _showMessage(
        result.message.isNotEmpty
            ? result.message
            : 'Code de vérification invalide.',
      );

      _otpController.clear();
    } catch (e) {
      if (!mounted) return;

      _otpController.clear();

      _showMessage('Vérification impossible. Vérifiez le code reçu par SMS.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // HEADER ET PROGRESSION
  // ============================================================

  Widget _buildProgress() {
    return Row(
      children: List.generate(3, (index) {
        final active = index <= _currentStep;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 5,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
            decoration: BoxDecoration(
              color: active ? _primary : AppTheme.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.textPrimary,
            ),
            const Spacer(),
            Text(
              'ÉTAPE ${_currentStep + 1}/3',
              style: TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildProgress(),
        const SizedBox(height: 28),
        Text(
          _titles[_currentStep],
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subtitles[_currentStep],
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  // ============================================================
  // ÉTAPE 1 : TÉLÉPHONE
  // ============================================================

  Widget _buildPhoneStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration:
                _decoration(
                  'Numéro de téléphone',
                  Icons.phone_android_rounded,
                  hint: '77 123 45 67',
                ).copyWith(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇸🇳'),
                        const SizedBox(width: 7),
                        Text(
                          '+221',
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(height: 25, width: 1, color: AppTheme.border),
                      ],
                    ),
                  ),
                ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entrez votre numéro de téléphone';
              }

              if (!RegExp(r'^(70|75|76|77|78)\d{7}$').hasMatch(value)) {
                return 'Numéro sénégalais invalide';
              }

              return null;
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Utilisez le numéro de téléphone enregistré lors '
                    'de la création de votre compte enseignant.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHAMPS PIN ET OTP
  // ============================================================

  Widget _buildPinInput({
    required TextEditingController controller,
    required int length,
    required String label,
    required bool obscureText,
    String? Function(String?)? validator,
  }) {
    final defaultTheme = PinTheme(
      width: length == 4 ? 52 : 43,
      height: 55,
      textStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: AppTheme.primary,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Pinput(
            controller: controller,
            length: length,
            keyboardType: TextInputType.number,
            obscureText: obscureText,
            obscuringCharacter: '●',
            validator: validator,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            defaultPinTheme: defaultTheme,
            focusedPinTheme: defaultTheme.copyWith(
              decoration: defaultTheme.decoration!.copyWith(
                border: Border.all(color: AppTheme.primary, width: 1.8),
              ),
            ),
            submittedPinTheme: defaultTheme.copyWith(
              decoration: defaultTheme.decoration!.copyWith(
                border: Border.all(color: AppTheme.primary),
              ),
            ),
            errorPinTheme: defaultTheme.copyWith(
              decoration: defaultTheme.decoration!.copyWith(
                border: Border.all(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ÉTAPE 2 : PIN
  // ============================================================

  Widget _buildPinStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, color: _primary, size: 35),
          ),
          const SizedBox(height: 22),
          Text(
            _formattedPhone,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          _buildPinInput(
            controller: _pinController,
            length: 4,
            label: 'Entrez votre code PIN',
            obscureText: _obscurePin,
            validator: (value) {
              if (value == null || value.length != 4) {
                return 'Le code PIN doit contenir 4 chiffres';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: _isLoading ? null : () => context.push('/forgot-pin'),
            child: Text(
              'Code PIN oublié ?',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÉTAPE 3 : VÉRIFICATION OTP
  // ============================================================

  Widget _buildOtpStep() {
    final canResend = !_isLoading && _resendCooldown == 0;

    return Form(
      key: _formKeys[2],
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sms_outlined, color: _primary, size: 35),
          ),
          const SizedBox(height: 20),
          Text(
            'Un code de vérification a été envoyé au',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _formattedPhone,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 30),
          _buildPinInput(
            controller: _otpController,
            length: 6,
            label: 'Code de vérification SMS',
            obscureText: false,
            validator: (value) {
              if (value == null || value.length != 6) {
                return 'Entrez les 6 chiffres du code';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: canResend ? _resendDeviceOtp : null,
            child: Text(
              _resendCooldown > 0
                  ? 'Renvoyer le code dans ${_formatCooldown(_resendCooldown)}'
                  : 'Renvoyer le code',
              style: TextStyle(
                color: canResend ? _primary : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_resendCooldown > 0)
            Text(
              'Vous pourrez demander un nouveau SMS à la fin du délai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONSTRUCTION DE L'ÉCRAN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 12),
              child: _buildHeader(),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildPhoneStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildPinStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildOtpStep(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 2
                                  ? 'Confirmer et terminer'
                                  : 'Continuer',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
