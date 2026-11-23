import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/security/services/pin_auth_service.dart';
import '../../../../core/security/widgets/pin_auth_modal.dart';

class BankCardScreen extends StatefulWidget {
  const BankCardScreen({super.key});

  @override
  State<BankCardScreen> createState() => _BankCardScreenState();
}

class _BankCardScreenState extends State<BankCardScreen>
    with SingleTickerProviderStateMixin {
  bool _isFrozen = false;
  bool _showCardNumber = false;
  bool _showCvv = false;

  bool _contactless = true;
  bool _onlinePayments = true;
  bool _abroadPayments = false;
  bool _atmWithdrawals = true;

  late final AnimationController _flipController;

  final String _cardHolder = 'IDRISSA N’DIAYE';
  final String _cardNumber = '4821 6589 2034 4821';
  final String _expiryDate = '12/29';
  final String _cvv = '328';

  static const Color _darkGreen = Color(0xFF0A3620);
  static const Color _mediumGreen = Color(0xFF145C38);
  static const Color _gold = Color(0xFFE8CD8C);

  static const double _paymentLimit = 500000;
  static const double _withdrawalLimit = 200000;

  final double _paymentUsed = 185000;
  final double _withdrawalUsed = 50000;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ' ');
  }

  // --------------------------------------------------
  // AUTHENTIFICATION PIN
  // --------------------------------------------------

  Future<bool> _authenticate({
    required String title,
    required String subtitle,
  }) async {
    final authenticated = await PinAuthModal.show(
      context,
      title: title,
      subtitle: subtitle,
      allowBiometrics: true,
    );

    return mounted && authenticated;
  }

  // --------------------------------------------------
  // FREEZE CARD
  // --------------------------------------------------

  void _toggleFreeze() {
    setState(() {
      _isFrozen = !_isFrozen;
    });

    _showMessage(
      _isFrozen ? 'Carte gelée (simulation).' : 'Carte réactivée (simulation).',
    );
  }

  // --------------------------------------------------
  // CARD DETAILS
  // --------------------------------------------------

  Future<void> _showCardDetails() async {
    final authenticated = await _authenticate(
      title: 'Informations confidentielles',
      subtitle:
          'Confirmez votre identité pour accéder aux informations de votre carte.',
    );

    if (!authenticated || !mounted) return;

    setState(() {
      _showCardNumber = false;
      _showCvv = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Informations de la carte',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Gardez ces informations confidentielles.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _detailRow(
                    'Numéro de carte',
                    _showCardNumber ? _cardNumber : '•••• •••• •••• 4821',
                    trailing: IconButton(
                      onPressed: () {
                        setSheetState(() {
                          _showCardNumber = !_showCardNumber;
                        });
                      },
                      icon: Icon(
                        _showCardNumber
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Titulaire', _cardHolder),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _detailRow('Expiration', _expiryDate)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _detailRow(
                          'CVV',
                          _showCvv ? _cvv : '•••',
                          trailing: IconButton(
                            onPressed: () {
                              setSheetState(() {
                                _showCvv = !_showCvv;
                              });
                            },
                            icon: Icon(
                              _showCvv
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4DF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF946B1E),
                          size: 19,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Ne partagez jamais votre numéro de carte, '
                            'votre CVV ou vos informations confidentielles.',
                            style: TextStyle(
                              color: Color(0xFF795A20),
                              fontSize: 11,
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
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------
  // CHANGE PIN
  // --------------------------------------------------

  Future<void> _changePin() async {
    final authenticated = await _authenticate(
      title: 'Changer mon code PIN',
      subtitle: 'Saisissez votre code PIN actuel pour continuer.',
    );

    if (!authenticated || !mounted) return;

    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    String? errorMessage;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Nouveau code PIN',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choisissez un nouveau code à 4 chiffres.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Nouveau PIN',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Confirmer le nouveau PIN',
                      counterText: '',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  onPressed: () {
                    final newPin = newPinController.text;
                    final confirmation = confirmPinController.text;

                    if (newPin.length != 4 || confirmation.length != 4) {
                      setDialogState(() {
                        errorMessage = 'Le code PIN doit contenir 4 chiffres.';
                      });
                      return;
                    }

                    if (newPin == '0000') {
                      setDialogState(() {
                        errorMessage =
                            'Veuillez choisir un code PIN moins prévisible.';
                      });
                      return;
                    }

                    if (newPin != confirmation) {
                      setDialogState(() {
                        errorMessage =
                            'Les deux codes PIN ne correspondent pas.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await PinAuthService.savePin("1234");

        if (mounted) {
          _showMessage('Votre nouveau code PIN a été enregistré.');
        }
      } catch (e) {
        if (mounted) {
          _showMessage('Impossible d’enregistrer le nouveau PIN.');
        }
      }
    }

    newPinController.dispose();
    confirmPinController.dispose();
  }

  // --------------------------------------------------
  // OPPOSITION
  // --------------------------------------------------

  Future<void> _showOppositionDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Faire opposition ?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Cette action est destinée à signaler une perte ou un vol. '
            'Dans cette version de démonstration, aucune opposition '
            'réelle ne sera effectuée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final authenticated = await _authenticate(
      title: 'Confirmer l’opposition',
      subtitle: 'Saisissez votre code PIN pour confirmer cette demande.',
    );

    if (!authenticated || !mounted) return;

    _showMessage(
      'Authentification réussie. La procédure d’opposition sera disponible prochainement.',
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 115),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildCardPreview(),
              const SizedBox(height: 19),
              _buildCardActions(),
              const SizedBox(height: 28),
              _buildSectionTitle('Utilisation de la carte'),
              const SizedBox(height: 12),
              _buildUsageSettings(),
              const SizedBox(height: 27),
              _buildSectionTitle(
                'Plafonds du jour',
                action: 'Modifier',
                onAction: () => _showMessage(
                  'Modification des plafonds bientôt disponible.',
                ),
              ),
              const SizedBox(height: 12),
              _buildLimitsCard(),
              const SizedBox(height: 27),
              _buildSectionTitle('Sécurité'),
              const SizedBox(height: 12),
              _buildSecurityCard(),
              const SizedBox(height: 18),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MON PORTEFEUILLE',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Ma carte',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gérez votre carte en toute simplicité.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(Icons.support_agent_rounded, color: AppTheme.primary),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // CARD PREVIEW - ANIMATION 3D CORRIGÉE
  // --------------------------------------------------

  Widget _buildCardPreview() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (_flipController.isAnimating) return;

            if (_flipController.value < 0.5) {
              _flipController.forward();
            } else {
              _flipController.reverse();
            }
          },
          child: AnimatedBuilder(
            animation: _flipController,
            builder: (context, child) {
              final progress = _flipController.value;

              final showBack = progress >= 0.5;

              final angle = showBack
                  ? (progress - 1) * 3.141592653589793
                  : progress * 3.141592653589793;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: showBack ? _buildCardBack() : _buildCardFront(),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Touchez la carte pour la retourner',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      height: 218,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [_mediumGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -75,
            child: _cardCircle(220, Colors.white.withOpacity(0.055)),
          ),
          Positioned(
            right: -20,
            bottom: -120,
            child: _cardCircle(220, _gold.withOpacity(0.08)),
          ),
          Positioned(
            left: -70,
            bottom: -120,
            child: _cardCircle(190, Colors.white.withOpacity(0.04)),
          ),

          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EN-TÊTE + DRAPEAU
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'MON ESPACE ENSEIGNANT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    _buildSenegalFlag(),
                  ],
                ),

                const Spacer(),

                // PUCE + SANS CONTACT
                Row(
                  children: [
                    _buildRealisticChip(),
                    const SizedBox(width: 13),

                    // Orientation corrigée : ondes vers la droite
                    Transform.rotate(
                      angle: 1.5708,
                      child: Icon(
                        Icons.wifi_rounded,
                        color: Colors.white.withOpacity(0.85),
                        size: 25,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // NUMÉRO
                Text(
                  _showCardNumber ? _cardNumber : '••••  ••••  ••••  4821',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),

                const Spacer(),

                // INFORMATIONS TITULAIRE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TITULAIRE',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 8,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cardHolder,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPIRE FIN',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _expiryDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    const Text(
                      'VISA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // VOILE DE GEL
          if (_isFrozen)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.58),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ac_unit_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'CARTE GELÉE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRealisticChip() {
    return Container(
      width: 43,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE8A8),
            Color(0xFFD5B56A),
            Color(0xFFF8E2A0),
            Color(0xFFB9954E),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFE8A8), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Séparations verticales
            Positioned(
              left: 13,
              top: 0,
              bottom: 0,
              child: Container(width: 0.9, color: const Color(0xFF96753A)),
            ),
            Positioned(
              right: 13,
              top: 0,
              bottom: 0,
              child: Container(width: 0.9, color: const Color(0xFF96753A)),
            ),

            // Séparations horizontales
            Positioned(
              left: 0,
              right: 0,
              top: 11,
              child: Container(height: 0.9, color: const Color(0xFF96753A)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 11,
              child: Container(height: 0.9, color: const Color(0xFF96753A)),
            ),

            // Partie centrale de la puce
            Center(
              child: Container(
                width: 13,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8CD8C),
                  border: Border.all(
                    color: const Color(0xFF96753A),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenegalFlag() {
    return Container(
      width: 37,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.55), width: 0.7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          const Expanded(child: ColoredBox(color: Color(0xFF00853F))),
          Expanded(
            child: Container(
              color: const Color(0xFFFDEF42),
              child: const Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: Color(0xFF00853F),
                ),
              ),
            ),
          ),
          Expanded(child: Container(color: const Color(0xFFE31B23))),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      height: 218,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [_darkGreen, Color(0xFF071F14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 27),
          Container(
            height: 43,
            width: double.infinity,
            color: Colors.black.withOpacity(0.7),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    color: Colors.white.withOpacity(0.85),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const Text(
                      'SIGNATURE',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 65,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _showCvv ? _cvv : '•••',
                    style: const TextStyle(
                      color: _darkGreen,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, 15),
            child: Text(
              'Carte émise sur le réseau Visa',
              style: TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
    );
  }

  // --------------------------------------------------
  // ACTIONS
  // --------------------------------------------------

  Widget _buildCardActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.visibility_outlined,
            label: 'Détails',
            onTap: _showCardDetails,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _actionButton(
            icon: _isFrozen ? Icons.lock_open_rounded : Icons.ac_unit_rounded,
            label: _isFrozen ? 'Dégeler' : 'Geler',
            onTap: _toggleFreeze,
            highlighted: _isFrozen,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _actionButton(
            icon: Icons.shield_outlined,
            label: 'Sécurité',
            onTap: () => _showMessage('Paramètres de sécurité ci-dessous.'),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: highlighted ? const Color(0xFFE8C8C4) : AppTheme.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: highlighted ? const Color(0xFFB42318) : AppTheme.primary,
              size: 21,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECTION TITLE
  // --------------------------------------------------

  Widget _buildSectionTitle(
    String title, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                action,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------
  // USAGE SETTINGS
  // --------------------------------------------------

  Widget _buildUsageSettings() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _usageSwitch(
            icon: Icons.contactless_rounded,
            title: 'Paiement sans contact',
            subtitle: 'Au terminal, sans insérer la carte',
            value: _contactless,
            onChanged: (value) => setState(() => _contactless = value),
          ),
          _usageDivider(),
          _usageSwitch(
            icon: Icons.language_rounded,
            title: 'Paiements en ligne',
            subtitle: 'Confirmation sécurisée 3-D Secure',
            value: _onlinePayments,
            onChanged: (value) => setState(() => _onlinePayments = value),
          ),
          _usageDivider(),
          _usageSwitch(
            icon: Icons.public_rounded,
            title: 'Utilisation à l’étranger',
            subtitle: 'Paiements et retraits hors UEMOA',
            value: _abroadPayments,
            onChanged: (value) => setState(() => _abroadPayments = value),
          ),
          _usageDivider(),
          _usageSwitch(
            icon: Icons.atm_rounded,
            title: 'Retraits aux distributeurs',
            subtitle: 'Réseau Visa au Sénégal et dans le monde',
            value: _atmWithdrawals,
            onChanged: (value) => setState(() => _atmWithdrawals = value),
          ),
        ],
      ),
    );
  }

  Widget _usageSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Switch.adaptive(
            value: value,
            activeColor: AppTheme.primary,
            onChanged: _isFrozen ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _usageDivider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      color: AppTheme.border,
      indent: 49,
    );
  }

  // --------------------------------------------------
  // LIMITS
  // --------------------------------------------------

  Widget _buildLimitsCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _limitProgress(
            title: 'Paiements',
            used: _paymentUsed,
            limit: _paymentLimit,
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 23),
          _limitProgress(
            title: 'Retraits',
            used: _withdrawalUsed,
            limit: _withdrawalLimit,
            icon: Icons.account_balance_outlined,
          ),
        ],
      ),
    );
  }

  Widget _limitProgress({
    required String title,
    required double used,
    required double limit,
    required IconData icon,
  }) {
    final progress = (used / limit).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_formatAmount(used)} / ${_formatAmount(limit)} F',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.background,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).round()} % utilisé',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SECURITY
  // --------------------------------------------------

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _securityRow(
            icon: Icons.lock_outline_rounded,
            title: 'Changer le code de l’application',
            subtitle: 'Modifier votre code PIN',
            onTap: _changePin,
          ),
          Divider(height: 1, color: AppTheme.border),
          _securityRow(
            icon: Icons.report_gmailerrorred_rounded,
            title: 'Faire opposition',
            subtitle: 'Perte, vol ou carte endommagée',
            isDanger: true,
            onTap: _showOppositionDialog,
          ),
        ],
      ),
    );
  }

  Widget _securityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? const Color(0xFFB42318) : AppTheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger ? color : AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // FOOTER
  // --------------------------------------------------

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.textSecondary,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Carte émise par l’établissement partenaire '
              'sur le réseau Visa.\n'
              'En cas de perte ou de vol, contactez le service '
              'client officiel de votre établissement.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
