import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/security/widgets/pin_auth_modal.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({super.key, this.availableBalance = 287450});

  final int availableBalance;

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  static const Color _green = Color(0xFF173D32);
  static const Color _orange = Color(0xFFF56624);
  static const Color _background = Color(0xFFFAF8F3);

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _showMyQr = false;
  bool _isProcessing = false;
  bool _isScanned = false;

  String? _merchantName;
  int? _paymentAmount;

  final String _personalQr =
      'ENSEIGNANT|WALLET|MAT-2026-00125|MON-ESPACE-ENSEIGNANT';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    final value = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(value[i]);
    }

    return buffer.toString();
  }

  void _switchMode(bool showMyQr) {
    if (_showMyQr == showMyQr) return;

    setState(() {
      _showMyQr = showMyQr;
    });

    if (showMyQr) {
      unawaited(_scannerController.stop());
    } else if (!_isScanned) {
      unawaited(_scannerController.start());
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned || _showMyQr || _isProcessing) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value == null || value.isEmpty) continue;

      final payment = _parseQrCode(value);

      if (payment == null) {
        _showInvalidQrMessage();
        continue;
      }

      setState(() {
        _isScanned = true;
        _merchantName = payment.$1;
        _paymentAmount = payment.$2;
      });

      unawaited(_scannerController.stop());
      break;
    }
  }

  (String, int)? _parseQrCode(String value) {
    // Format : SYCAPAY-MERCHANT|NOM DU COMMERÇANT|7500

    if (value.startsWith('SYCAPAY-MERCHANT|')) {
      final parts = value.split('|');

      if (parts.length >= 3) {
        final merchant = parts[1].trim();
        final amount = int.tryParse(parts[2].trim());

        if (merchant.isNotEmpty && amount != null && amount > 0) {
          return (merchant, amount);
        }
      }
    }

    // Format JSON :
    // {"merchant":"Pharmacie","amount":7500}

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map<String, dynamic>) {
        final merchant =
            (decoded['merchant'] ?? decoded['merchantName'] ?? decoded['name'])
                ?.toString();

        final rawAmount = decoded['amount'] ?? decoded['total'];

        final amount = rawAmount is num
            ? rawAmount.toInt()
            : int.tryParse(rawAmount?.toString() ?? '');

        if (merchant != null &&
            merchant.trim().isNotEmpty &&
            amount != null &&
            amount > 0) {
          return (merchant.trim(), amount);
        }
      }
    } catch (_) {
      // QR code non JSON.
    }

    return null;
  }

  void _showInvalidQrMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'QR code non reconnu. Vous pouvez continuer la simulation avec Payer.',
          ),
        ),
      );
  }

  Future<void> _resetScanner() async {
    setState(() {
      _isScanned = false;
      _merchantName = null;
      _paymentAmount = null;
    });

    await _scannerController.start();
  }

  Future<void> _startPayment() async {
    // Sans QR scanné, on utilise les données de démonstration.
    final merchant = _merchantName ?? 'Pharmacie du Plateau';
    final amount = _paymentAmount ?? 7500;

    final confirmed = await _showPaymentConfirmation(
      merchant: merchant,
      amount: amount,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    final authenticated = await PinAuthModal.show(
      context,
      title: 'Confirmer le paiement',
      subtitle: 'Authentifiez-vous pour continuer',
      allowBiometrics: true,
    );

    if (!mounted) return;

    if (!authenticated) {
      setState(() => _isProcessing = false);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    await _showPaymentResult(merchant: merchant, amount: amount);
  }

  Future<bool?> _showPaymentConfirmation({
    required String merchant,
    required int amount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Confirmer le paiement',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _green,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: _green,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant,
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Paiement marchand',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF269B65),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Montant à payer',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatAmount(amount)} FCFA',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 22),
              _summaryLine('Frais de paiement', 'Gratuit'),
              const SizedBox(height: 12),
              _summaryLine(
                'Solde disponible',
                '${_formatAmount(widget.availableBalance)} FCFA',
              ),
              const Divider(height: 28),
              _summaryLine(
                'Total à payer',
                '${_formatAmount(amount)} FCFA',
                bold: true,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Confirmer et continuer',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryLine(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? _green : Colors.grey.shade600,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: _green,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _showPaymentResult({
    required String merchant,
    required int amount,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF269B65),
                  size: 45,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Paiement effectué',
                style: TextStyle(
                  color: _green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Le paiement de ${_formatAmount(amount)} FCFA '
                'chez $merchant a été payé avec succès.\n\n'
                'Aucun montant n’a été débité de votre portefeuille.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Terminer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    _buildModeSelector(),
                    const SizedBox(height: 25),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _showMyQr ? _buildMyQrCard() : _buildScannerCard(),
                    ),
                    const SizedBox(height: 20),
                    if (_isScanned && !_showMyQr) _buildScannedDetails(),
                    _buildInformation(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                height: 44,
                width: 44,
                child: Icon(Icons.arrow_back_rounded, color: _green),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Paiement QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _green,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFECEDE8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              title: 'Scanner',
              icon: Icons.qr_code_scanner_rounded,
              selected: !_showMyQr,
              onTap: () => _switchMode(false),
            ),
          ),
          Expanded(
            child: _modeButton(
              title: 'Mon QR code',
              icon: Icons.qr_code_rounded,
              selected: _showMyQr,
              onTap: () => _switchMode(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? _green : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? _green : Colors.grey.shade600,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      key: const ValueKey('scanner'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Scanner un QR code',
            style: TextStyle(
              color: _green,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _isScanned
                ? 'QR code détecté avec succès.'
                : 'Placez le QR code du commerçant dans le cadre.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: _isScanned
                  ? Container(
                      color: const Color(0xFFF1F5F1),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF269B65),
                          size: 70,
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                          errorBuilder: (context, error) {
                            return Container(
                              color: const Color(0xFF202923),
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'Impossible d’accéder à la caméra.\n'
                                  '${error.errorCode.name}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Container(
                              height: 210,
                              width: 210,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  _scannerCorner(top: true, left: true),
                                  _scannerCorner(top: true, left: false),
                                  _scannerCorner(top: false, left: true),
                                  _scannerCorner(top: false, left: false),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Lecture automatique',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 17),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 17,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 7),
              Text(
                _isScanned
                    ? 'QR code prêt pour le paiement'
                    : 'Pointez la caméra vers le QR code',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          if (_isScanned) ...[
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scanner un autre QR code'),
              style: TextButton.styleFrom(foregroundColor: _green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scannerCorner({required bool top, required bool left}) {
    const length = 28.0;
    const thickness = 4.0;

    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: SizedBox(
        height: length,
        width: length,
        child: Stack(
          children: [
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: length,
                height: thickness,
                color: _orange,
              ),
            ),
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: thickness,
                height: length,
                color: _orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedDetails() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF269B65),
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Commerçant détecté',
                style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _merchantName ?? '',
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Montant demandé',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              Text(
                '${_formatAmount(_paymentAmount ?? 0)} FCFA',
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyQrCard() {
    return Container(
      key: const ValueKey('my-qr'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Mon QR code',
            style: TextStyle(
              color: _green,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Présentez ce QR code pour recevoir un paiement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE9EDE9)),
            ),
            child: QrImageView(
              data: _personalQr,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: _green,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: _green,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'MON ESPACE ENSEIGNANT',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Matricule : MAT-2026-00125',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, color: _green, size: 17),
                SizedBox(width: 8),
                Text(
                  'QR code personnel',
                  style: TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformation() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: _orange, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _showMyQr
                  ? 'Montrez votre QR code au commerçant pour recevoir un paiement.'
                  : 'Scannez le QR code du commerçant. Vous pouvez aussi lancer une simulation avec le bouton Payer.',
              style: const TextStyle(color: _green, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _startPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _orange.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 19),
                      SizedBox(width: 9),
                      Text(
                        'Payer',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
