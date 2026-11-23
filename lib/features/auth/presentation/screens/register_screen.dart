import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:wallet_enseignant/app/app_theme.dart';
import 'package:wallet_enseignant/core/auth/microsoft_auth_service.dart';

import '../../domain/entities/auth_exception.dart';
import '../providers/auth_providers.dart';
import '../../../../../app/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();

  final List<GlobalKey<FormState>> _formKeys = List.generate(
    4,
    (_) => GlobalKey<FormState>(),
  );

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  int _currentStep = 0;
  int _otpRemainingSeconds = 0;

  bool _acceptedTerms = false;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isRegistering = false;
  bool _isVerifyingTeacher = false;

  bool _otpVerified = false;
  bool _teacherVerified = false;

  Map<String, dynamic>? _verifiedTeacher;

  String? _verificationToken;
  String? _professionalCardVerificationToken;

  Timer? _otpTimer;

  final Color _primary = AppTheme.primary;

  bool get _isLoading =>
      _isSendingOtp || _isVerifyingOtp || _isRegistering || _isVerifyingTeacher;

  final List<String> _titles = [
    'Informations personnelles',
    'Numéro de téléphone',
    'Vérification du numéro',
    'Créer votre code PIN',
  ];

  final List<String> _subtitles = [
    'Renseignez vos informations personnelles.',
    'Votre identité professionnelle sera récupérée automatiquement.',
    'Saisissez le code de vérification reçu par SMS.',
    'Ce code vous permettra de vous connecter.',
  ];

  @override
  void dispose() {
    _otpTimer?.cancel();
    _pageController.dispose();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();

    super.dispose();
  }

  String get _internationalPhone {
    final localPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '+221$localPhone';
  }

  String get _otpCountdown {
    final minutes = (_otpRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ------------------------------------------------------------
  // MICROSOFT SSO + RÉCUPÉRATION AUTOMATIQUE APPS
  // ------------------------------------------------------------

  bool _isMicrosoftCancellation(Object error) {
    final message = error.toString().toLowerCase();

    return message.contains('cancel') ||
        message.contains('cancelled') ||
        message.contains('canceled') ||
        message.contains('user_cancel') ||
        message.contains('user cancelled') ||
        message.contains('user canceled');
  }

  String _cleanMicrosoftError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('PlatformException(', '')
        .trim();
  }

  Future<void> _verifyTeacher() async {
    if (_isLoading || _teacherVerified) return;

    final microsoftAuth = MicrosoftAuthService();

    if (!microsoftAuth.isConfigured) {
      _showMessage('La configuration Microsoft est incomplète.');
      return;
    }

    setState(() {
      _isVerifyingTeacher = true;
      _teacherVerified = false;
      _verifiedTeacher = null;
      _professionalCardVerificationToken = null;
    });

    try {
      // 1. Initialisation Microsoft.
      await microsoftAuth.initialize();

      // 2. Authentification Microsoft.
      // Cette action est déclenchée automatiquement par Continuer.
      await microsoftAuth.signIn();

      if (!mounted) return;

      // 3. Récupération du token dédié à APPS.
      final appsAccessToken = await microsoftAuth.getCarteProAccessToken();

      const chunkSize = 500;

      for (var i = 0; i < appsAccessToken.length; i += chunkSize) {
        final end = (i + chunkSize < appsAccessToken.length)
            ? i + chunkSize
            : appsAccessToken.length;

        print(
          'TOKEN PART ${i ~/ chunkSize + 1}: '
          '${appsAccessToken.substring(i, end)}',
        );
      }

      if (!mounted) return;

      if (appsAccessToken.isEmpty) {
        throw Exception(
          'Microsoft n’a pas fourni de token pour la carte professionnelle.',
        );
      }

      // 4. Vérification APPS auprès du backend.
      // Aucun matricule ni IEN n'est envoyé depuis Flutter.
      final verification = await ref.read(
        verifyProfessionalCardUseCaseProvider,
      )(accessToken: appsAccessToken);

      if (!mounted) return;

      if (!verification.success || verification.verificationToken.isEmpty) {
        throw Exception(
          verification.message.isNotEmpty
              ? verification.message
              : 'La vérification professionnelle a échoué.',
        );
      }

      // 5. Conservation des informations retournées par APPS.
      final appsFirstName = verification.prenom?.trim() ?? '';
      final appsLastName = verification.nom?.trim() ?? '';
      final appsEmail = verification.emailPro?.trim() ?? '';

      // Les données APPS sont prioritaires pour l'identité.
      if (appsFirstName.isNotEmpty) {
        _firstNameController.text = appsFirstName;
      }

      if (appsLastName.isNotEmpty) {
        _lastNameController.text = appsLastName;
      }

      if (appsEmail.isNotEmpty) {
        _emailController.text = appsEmail;
      }

      setState(() {
        _verifiedTeacher = {
          'matricule': verification.matricule,
          'ien': verification.ien,
          'prenom': verification.prenom,
          'nom': verification.nom,
          'nomComplet': verification.nomComplet,
          'displayName': verification.displayName,
          'emailPro': verification.emailPro,
          'telephone': verification.telephone,
          'corps': verification.corps,
          'fonction': verification.fonction,
          'typePersonnel': verification.typePersonnel,
          'structure': verification.structure,
        };

        _professionalCardVerificationToken = verification.verificationToken;

        _teacherVerified = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _teacherVerified = false;
        _verifiedTeacher = null;
        _professionalCardVerificationToken = null;
      });

      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _teacherVerified = false;
        _verifiedTeacher = null;
        _professionalCardVerificationToken = null;
      });

      if (_isMicrosoftCancellation(e)) {
        _showMessage(
          'Authentification Microsoft annulée. Vous pouvez réessayer.',
        );
      } else {
        _showMessage(
          'Vérification professionnelle impossible : '
          '${_cleanMicrosoftError(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingTeacher = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // OTP
  // ------------------------------------------------------------

  void _startOtpCountdown(int seconds) {
    _otpTimer?.cancel();

    setState(() {
      _otpRemainingSeconds = seconds;
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_otpRemainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          _otpRemainingSeconds = 0;
        });

        return;
      }

      setState(() {
        _otpRemainingSeconds--;
      });
    });
  }

  Future<void> _sendOtp({bool advanceToOtpStep = false}) async {
    if (_isLoading) return;

    setState(() => _isSendingOtp = true);

    try {
      final result = await ref.read(sendOtpUseCaseProvider)(
        phone: _internationalPhone,
      );

      if (!mounted) return;

      if (!result.success) {
        _showMessage(result.message);
        return;
      }

      _otpVerified = false;
      _verificationToken = null;
      _otpController.clear();

      _startOtpCountdown(result.expiresIn);

      _showMessage(result.message);

      if (advanceToOtpStep) {
        _goToStep(2);
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Impossible d’envoyer le code SMS. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    if (_otpRemainingSeconds <= 0) {
      _showMessage('Votre code OTP a expiré. Demandez un nouveau code.');
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final result = await ref.read(verifyOtpUseCaseProvider)(
        phone: _internationalPhone,
        code: _otpController.text.trim(),
      );

      if (!mounted) return;

      if (!result.success || !result.verified) {
        _showMessage(result.message);
        return;
      }

      _otpTimer?.cancel();

      setState(() {
        _otpVerified = true;
        _verificationToken = result.verificationToken;
        _otpRemainingSeconds = 0;
      });

      _showMessage('Numéro de téléphone vérifié avec succès.');

      _goToStep(3);
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Impossible de vérifier le code. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  // ------------------------------------------------------------
  // INSCRIPTION
  // ------------------------------------------------------------

  Future<void> _submitRegistration() async {
    if (_isLoading) return;

    if (!_teacherVerified ||
        _verifiedTeacher == null ||
        _professionalCardVerificationToken == null) {
      _showMessage(
        'La récupération de votre identité professionnelle est nécessaire.',
      );
      _goToStep(1);
      return;
    }

    if (!_otpVerified || _verificationToken == null) {
      _showMessage('Veuillez d’abord vérifier votre numéro de téléphone.');
      _goToStep(2);
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      _showMessage('Les deux codes PIN ne correspondent pas.');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final result = await ref.read(registerUseCaseProvider)(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _internationalPhone,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim().toLowerCase(),
        pin: _pinController.text,
        confirmPin: _confirmPinController.text,
        verificationToken: _verificationToken!,
        professionalCardVerificationToken: _professionalCardVerificationToken!,
      );

      if (!mounted) return;

      if (!result.success) {
        _showMessage(result.message);
        return;
      }

      final secureStorage = ref.read(secureStorageProvider);

      await secureStorage.saveAccountPhone(_internationalPhone);

      await secureStorage.saveAccountName(
        firstName: result.user.firstName,
        lastName: result.user.lastName,
      );

      await secureStorage.markAccountConfigured();

      if (!mounted) return;

      _showRegistrationSuccess(result.message);
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Impossible de créer votre compte. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  void _showRegistrationSuccess(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: Icon(Icons.check_circle_outline, color: _primary, size: 52),
          title: const Text('Compte créé !', textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Aller à la connexion'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // NAVIGATION ENTRE LES ÉTAPES
  // ------------------------------------------------------------

  Future<void> _nextStep() async {
    if (_isLoading) return;

    final isValid = _formKeys[_currentStep].currentState?.validate() ?? false;

    if (!isValid) return;

    // Étape 1 : informations personnelles.
    if (_currentStep == 0) {
      if (!_acceptedTerms) {
        _showMessage('Veuillez accepter les conditions d’utilisation.');
        return;
      }

      _goToStep(1);
      return;
    }

    // Étape 2 : téléphone + récupération automatique APPS.
    if (_currentStep == 1) {
      if (!_teacherVerified) {
        await _verifyTeacher();
      }

      if (!mounted || !_teacherVerified) return;

      await _sendOtp(advanceToOtpStep: true);
      return;
    }

    // Étape 3 : vérification OTP.
    if (_currentStep == 2) {
      await _verifyOtp();
      return;
    }

    // Étape 4 : création du compte.
    if (_currentStep == 3) {
      await _submitRegistration();
    }
  }

  Future<void> _resendOtp() async {
    if (_otpRemainingSeconds > 0) {
      _showMessage(
        'Vous pourrez demander un nouveau code dans $_otpCountdown.',
      );
      return;
    }

    await _sendOtp();
  }

  void _previousStep() {
    if (_isLoading) return;

    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    _goToStep(_currentStep - 1);
  }

  void _goToStep(int step) {
    if (!mounted) return;

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );

    setState(() => _currentStep = step);
  }

  // ------------------------------------------------------------
  // UI COMMUNE
  // ------------------------------------------------------------

  Widget _buildProgress() {
    return Row(
      children: List.generate(4, (index) {
        final active = index <= _currentStep;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 5,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 7),
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
              onPressed: _isLoading ? null : _previousStep,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.textPrimary,
            ),
            const Spacer(),
            Text(
              'ÉTAPE ${_currentStep + 1}/4',
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

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: _decoration(
        label,
        icon,
        hint: hint,
      ).copyWith(suffixIcon: suffixIcon),
    );
  }

  Widget _buildPinInput({
    required TextEditingController controller,
    required int length,
    required String label,
    required bool obscureText,
    String? Function(String?)? validator,
  }) {
    final defaultTheme = PinTheme(
      width: 48,
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

  // ------------------------------------------------------------
  // ÉTAPE 1 : INFORMATIONS PERSONNELLES
  // ------------------------------------------------------------

  Widget _buildPersonalInformation() {
    return Form(
      key: _formKeys[0],
      child: Column(
        children: [
          _field(
            label: 'Prénom',
            icon: Icons.person_outline,
            controller: _firstNameController,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Entrez votre prénom'
                : null,
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Nom',
            icon: Icons.person_outline,
            controller: _lastNameController,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Entrez votre nom'
                : null,
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Adresse e-mail',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Entrez votre adresse e-mail';
              }

              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                return 'Adresse e-mail invalide';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: _primary,
            title: Text(
              'J’accepte les conditions d’utilisation.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ÉTAPE 2 : TÉLÉPHONE UNIQUEMENT
  // ------------------------------------------------------------

  Widget _buildPhoneStep() {
    return Form(
      key: _formKeys[1],
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
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: _primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Votre identité professionnelle sera vérifiée '
                    'automatiquement auprès du ministère. '
                    'Votre matricule et votre IEN seront récupérés '
                    'directement depuis APPS, sans saisie manuelle.',
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
          if (_teacherVerified) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Identité professionnelle récupérée avec succès.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ÉTAPE 3 : OTP
  // ------------------------------------------------------------

  Widget _buildOtpStep() {
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
            child: Icon(Icons.sms_outlined, color: _primary, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'Code envoyé au',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 5),
          Text(
            _internationalPhone,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 28),
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
          const SizedBox(height: 16),
          if (_otpRemainingSeconds > 0)
            Text(
              'Le code expire dans $_otpCountdown',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            const Text(
              'Votre code a expiré.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading || _otpRemainingSeconds > 0
                ? null
                : _resendOtp,
            child: Text(
              _otpRemainingSeconds > 0
                  ? 'Renvoyer dans $_otpCountdown'
                  : 'Renvoyer le code',
              style: TextStyle(
                color: _otpRemainingSeconds > 0
                    ? AppTheme.textSecondary
                    : _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ÉTAPE 4 : PIN
  // ------------------------------------------------------------

  Widget _buildPinStep() {
    return Form(
      key: _formKeys[3],
      child: Column(
        children: [
          _buildPinInput(
            controller: _pinController,
            length: 4,
            label: 'Choisir votre code PIN',
            obscureText: true,
            validator: (value) {
              if (value == null || value.length != 4) {
                return 'Le PIN doit contenir 4 chiffres';
              }

              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildPinInput(
            controller: _confirmPinController,
            length: 4,
            label: 'Confirmer votre code PIN',
            obscureText: true,
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

  // ------------------------------------------------------------
  // BOUTONS
  // ------------------------------------------------------------

  Widget _buildLoadingButton() {
    String label = 'Continuer';

    if (_isVerifyingTeacher) {
      label = 'Vérification de votre identité...';
    } else if (_isSendingOtp) {
      label = 'Envoi du SMS...';
    } else if (_isVerifyingOtp) {
      label = 'Vérification...';
    } else if (_isRegistering) {
      label = 'Création du compte...';
    } else if (_currentStep == 3) {
      label = 'Créer mon compte';
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget haveAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          context.push('/connexion');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _primary,
          disabledBackgroundColor: _primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "J'ai déjà un compte",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

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
                    child: _buildPersonalInformation(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildPhoneStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildOtpStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildPinStep(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: _buildLoadingButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: haveAccountButton(),
            ),
          ],
        ),
      ),
    );
  }
}
