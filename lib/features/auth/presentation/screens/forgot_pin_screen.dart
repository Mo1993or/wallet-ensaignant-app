import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../../app/app_theme.dart';
import '../providers/device_auth_providers.dart';
import '../../domain/entities/auth_exception.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  final PageController _pageController = PageController();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  final Color _primary = AppTheme.primary;

  int _currentStep = 0;
  bool _isLoading = false;

  String? _verificationToken;

  String get _phoneE164 {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '+221$digits';
  }

  final List<String> _titles = [
    'Votre numéro de téléphone',
    'Vérification du numéro',
    'Nouveau code PIN',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // ============================================================
  // NAVIGATION ENTRE LES ÉTAPES
  // ============================================================

  void _goToStep(int step) {
    if (!mounted) return;

    setState(() {
      _currentStep = step;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _nextStep() async {
    if (_isLoading) return;

    final isValid = _formKeys[_currentStep].currentState?.validate() ?? false;

    if (!isValid) return;

    FocusScope.of(context).unfocus();

    switch (_currentStep) {
      case 0:
        await _sendOtp();
        break;

      case 1:
        await _verifyOtp();
        break;

      case 2:
        await _completeReset();
        break;
    }
  }

  void _previousStep() {
    if (_isLoading) return;

    if (_currentStep == 0) {
      context.pop();
      return;
    }

    _goToStep(_currentStep - 1);
  }

  // ============================================================
  // ÉTAPE 1 : DEMANDE OTP
  // ============================================================

  Future<void> _sendOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.sendPinResetOtp(phone: _phoneE164);

      if (!mounted) return;

      if (result['success'] == true) {
        _otpController.clear();
        _verificationToken = null;

        _showMessage(
          result['message']?.toString() ??
              'Si un compte correspond à ce numéro, un code sera envoyé par SMS.',
        );

        _goToStep(1);
      } else {
        _showMessage(
          result['message']?.toString() ??
              'Impossible de demander le code de vérification.',
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Impossible de demander le code SMS. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // ÉTAPE 2 : VÉRIFICATION OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.verifyPinResetOtp(
        phone: _phoneE164,
        code: _otpController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final token = result['verificationToken'];

        if (token == null || token.toString().isEmpty) {
          _showMessage('Le serveur n’a pas retourné le jeton de vérification.');
          return;
        }

        _verificationToken = token.toString();

        _goToStep(2);
        return;
      }

      _otpController.clear();

      _showMessage(
        result['message']?.toString() ?? 'Code de vérification invalide.',
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _otpController.clear();
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;

      _otpController.clear();
      _showMessage('Vérification impossible. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // RENVOI DU CODE SMS
  // ============================================================

  Future<void> _resendOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.sendPinResetOtp(phone: _phoneE164);

      if (!mounted) return;

      if (result['success'] == true) {
        _otpController.clear();
        _verificationToken = null;

        _showMessage(
          result['message']?.toString() ??
              'Une nouvelle demande de code a été effectuée.',
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
      _showMessage('Impossible de renvoyer le code SMS.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // ÉTAPE 3 : RÉINITIALISATION DU PIN
  // ============================================================

  Future<void> _completeReset() async {
    if (_isLoading) return;

    if (_pinController.text != _confirmPinController.text) {
      _showMessage('Les deux codes PIN ne correspondent pas.');
      return;
    }

    if (_verificationToken == null) {
      _showMessage('Votre vérification a expiré. Veuillez recommencer.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(deviceAuthServiceProvider);

      final result = await authService.resetPin(
        phone: _phoneE164,
        verificationToken: _verificationToken!,
        newPin: _pinController.text,
        confirmPin: _confirmPinController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _verificationToken = null;

        _showSuccessDialog();
        return;
      }

      _showMessage(
        result['message']?.toString() ??
            'Impossible de réinitialiser votre code PIN.',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Une erreur est survenue pendant la réinitialisation.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // SUCCÈS
  // ============================================================

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppTheme.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'PIN réinitialisé !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Votre nouveau code PIN a été enregistré avec succès. '
                'Veuillez vous reconnecter pour continuer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go('/connexion');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Me connecter',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
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
  // CHAMPS PIN / OTP
  // ============================================================

  Widget _buildPinInput({
    required TextEditingController controller,
    required int length,
    required String label,
    required bool obscureText,
    required String errorMessage,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;

            final pinWidth = ((availableWidth - (length - 1) * 8) / length)
                .clamp(30.0, 48.0)
                .toDouble();

            final responsiveTheme = PinTheme(
              width: pinWidth,
              height: 54,
              textStyle: const TextStyle(
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

            return Center(
              child: Pinput(
                controller: controller,
                length: length,
                keyboardType: TextInputType.number,
                obscureText: obscureText,
                obscuringCharacter: '●',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator:
                    validator ??
                    (value) {
                      if (value == null || value.length != length) {
                        return errorMessage;
                      }
                      return null;
                    },
                defaultPinTheme: responsiveTheme,
                focusedPinTheme: responsiveTheme.copyWith(
                  decoration: responsiveTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.primary, width: 1.8),
                  ),
                ),
                submittedPinTheme: responsiveTheme.copyWith(
                  decoration: responsiveTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.secondary),
                  ),
                ),
                errorPinTheme: responsiveTheme.copyWith(
                  decoration: responsiveTheme.decoration!.copyWith(
                    border: Border.all(color: Colors.red),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
          const Text(
            'Entrez le numéro de téléphone associé à votre compte enseignant.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Numéro de téléphone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
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
          _buildInfoBox(
            icon: Icons.sms_outlined,
            message: 'Un code de confirmation sera envoyé au numéro renseigné.',
          ),
        ],
      ),
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
  // ÉTAPE 2 : OTP
  // ============================================================

  Widget _buildOtpStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saisissez le code à 6 chiffres envoyé par SMS sur votre téléphone.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 30),
          _buildPinInput(
            controller: _otpController,
            length: 6,
            label: 'Code de confirmation',
            obscureText: false,
            errorMessage: 'Entrez les 6 chiffres du code',
          ),
          const SizedBox(height: 22),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: const Text(
                'Renvoyer le code',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _buildInfoBox(
            icon: Icons.timer_outlined,
            message:
                'Votre code de vérification est valable pendant 3 minutes.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÉTAPE 3 : NOUVEAU PIN
  // ============================================================

  Widget _buildNewPinStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez un nouveau code PIN à 4 chiffres pour sécuriser votre espace enseignant.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          _buildPinInput(
            controller: _pinController,
            length: 4,
            label: 'Nouveau code PIN',
            obscureText: true,
            errorMessage: 'Le PIN doit contenir 4 chiffres',
          ),
          const SizedBox(height: 26),
          _buildPinInput(
            controller: _confirmPinController,
            length: 4,
            label: 'Confirmer le nouveau PIN',
            obscureText: true,
            errorMessage: 'Confirmez les 4 chiffres',
            validator: (value) {
              if (value == null || value.length != 4) {
                return 'Confirmez les 4 chiffres';
              }

              if (value != _pinController.text) {
                return 'Les codes PIN ne correspondent pas';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPOSANTS UI
  // ============================================================

  Widget _buildInfoBox({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(3, (index) {
        final isCompleted = index <= _currentStep;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            height: 5,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.primary : AppTheme.border,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == 2;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _previousStep,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Étape ${_currentStep + 1}/3',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildProgress(),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children:
                    [_buildPhoneStep(), _buildOtpStep(), _buildNewPinStep()]
                        .map(
                          (page) => SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            child: page,
                          ),
                        )
                        .toList(),
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
                    backgroundColor: AppTheme.primary,
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLastStep ? 'Confirmer le nouveau PIN' : 'Continuer',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
