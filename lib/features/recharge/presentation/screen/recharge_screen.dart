import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  static const Color _green = Color(0xFF173D32);
  static const Color _orange = Color(0xFFF56624);
  static const Color _background = Color(0xFFFAF8F3);
  static const Color _muted = Color(0xFF89938E);

  final TextEditingController _amountController = TextEditingController();

  int _step = 0;
  String? _selectedSource;

  final List<_RechargeSource> _sources = const [
    _RechargeSource(
      id: 'wave',
      name: 'Wave',
      description: 'Paiement avec votre compte Wave',
      color: Color(0xFF1DC4FF),
      logoUrl: 'https://www.droitmediasfinance.com/images/juin/WAVE.png',
    ),
    _RechargeSource(
      id: 'orange',
      name: 'Orange Money',
      description: 'Paiement avec Orange Money',
      color: Color(0xFFFF7900),
      logoUrl:
          'https://orange.sn/sites/default/files/2021-09/Ouverture%20OM_0.jpg',
    ),
    _RechargeSource(
      id: 'free',
      name: 'Free Money',
      description: 'Paiement avec Free Money',
      color: Color(0xFFCD1E25),
      logoUrl:
          'https://www.boasenegal.com/wp-content/uploads/2020/04/fee-money-768x608.png',
    ),
    _RechargeSource(
      id: 'bank',
      name: 'Virement bancaire',
      description: 'Depuis votre compte bancaire',
      color: _green,
    ),
  ];

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0;

  _RechargeSource? get _source {
    for (final source in _sources) {
      if (source.id == _selectedSource) return source;
    }
    return null;
  }

  bool get _isBank => _selectedSource == 'bank';

  bool get _isValidAmount => _amount >= 500 && _amount <= 1000000;

  bool get _canContinue => _selectedSource != null && _isValidAmount;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    final value = amount.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(value[i]);
    }

    return buffer.toString();
  }

  void _selectAmount(int amount) {
    setState(() {
      _amountController.text = _formatAmount(amount);
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
    });
  }

  void _selectSource(String id) {
    setState(() {
      _selectedSource = id;
    });
  }

  void _goToSummary() {
    if (!_canContinue) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _step = 1;
    });
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step--;
      });
    } else {
      context.pop();
    }
  }

  void _confirmRecharge() {
    FocusScope.of(context).unfocus();

    // Aucun paiement réel n'est déclenché ici.
    // Cette étape sera reliée au prestataire de paiement via l'API.
    setState(() {
      _step = 2;
    });
  }

  Future<void> _copyBankMessage() async {
    const message =
        'Je souhaite obtenir les coordonnées bancaires officielles '
        'pour effectuer une recharge de mon portefeuille enseignant.';

    await Clipboard.setData(const ClipboardData(text: message));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _step == 0
              ? 'Recharger'
              : _step == 1
              ? 'Récapitulatif'
              : 'Recharge',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _green,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == 0
              ? _buildSelectionPage()
              : _step == 1
              ? _buildSummaryPage()
              : _buildResultPage(),
        ),
      ),
    );
  }

  Widget _buildSelectionPage() {
    return SingleChildScrollView(
      key: const ValueKey('selection'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntro(),
          const SizedBox(height: 25),
          _buildProgress(),
          const SizedBox(height: 25),
          _buildSectionTitle('Moyen de recharge'),
          const SizedBox(height: 12),
          ..._sources.map(_buildSourceTile),
          const SizedBox(height: 22),
          _buildSectionTitle('Montant à recharger'),
          const SizedBox(height: 12),
          _buildAmountField(),
          const SizedBox(height: 14),
          _buildQuickAmounts(),
          const SizedBox(height: 20),
          _buildLimits(),
          const SizedBox(height: 26),
          _buildPrimaryButton(
            label: 'Continuer',
            onPressed: _canContinue ? _goToSummary : null,
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Minimum 500 FCFA · Maximum 1 000 000 FCFA',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    final source = _source;

    return SingleChildScrollView(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 28),
          const Text(
            'Vérifiez votre recharge',
            style: TextStyle(
              color: _green,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Vérifiez les informations avant de poursuivre.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Text(
                  'MONTANT DE LA RECHARGE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatAmount(_amount)} FCFA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Portefeuille principal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildSectionTitle('Détails de la recharge'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: _whiteCardDecoration(),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Moyen de paiement',
                  source?.name ?? '',
                  trailing: source == null
                      ? null
                      : _buildLogo(source, size: 38),
                ),
                _buildSummaryDivider(),
                _buildSummaryRow('Montant', '${_formatAmount(_amount)} FCFA'),
                _buildSummaryDivider(),
                _buildSummaryRow('Frais', 'À confirmer par le prestataire'),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Crédit attendu',
                  '${_formatAmount(_amount)} FCFA',
                  isHighlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_isBank) _buildBankInformation(),
          _buildSecurityNotice(),
          const SizedBox(height: 25),
          _buildPrimaryButton(
            label: _isBank ? 'Continuer la demande' : 'Confirmer la demande',
            onPressed: _confirmRecharge,
          ),
          const SizedBox(height: 12),
          _buildSecondaryButton(
            label: 'Modifier les informations',
            onPressed: () {
              setState(() => _step = 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultPage() {
    final source = _source;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
      child: Column(
        children: [
          _buildProgress(),
          const SizedBox(height: 35),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 222, 255, 226),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.check_circle, color: _green, size: 42),
          ),
          const SizedBox(height: 22),
          const Text(
            'Recharge éffectuée',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Votre recharge a été effectuer avec succès ',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _whiteCardDecoration(),
            child: Column(
              children: [
                _buildSummaryRow('Montant', '${_formatAmount(_amount)} FCFA'),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Moyen',
                  source?.name ?? '',
                  trailing: source == null
                      ? null
                      : _buildLogo(source, size: 35),
                ),
                _buildSummaryDivider(),
                _buildSummaryRow('Statut', 'Effectué', valueColor: _orange),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _orange, size: 21),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucun paiement n’a été déclenché et aucun montant '
                    'n’a été ajouté à votre portefeuille. La connexion '
                    'à l’API de paiement est nécessaire pour finaliser '
                    'une vraie recharge.',
                    style: TextStyle(
                      color: Color(0xFF79512F),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _buildPrimaryButton(
            label: 'Terminer',
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 12),
          _buildSecondaryButton(
            label: 'Nouvelle recharge',
            onPressed: () {
              setState(() {
                _step = 0;
                _selectedSource = null;
                _amountController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wallet_rounded, color: Colors.white, size: 28),
          SizedBox(height: 15),
          Text(
            'Alimentez votre portefeuille',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Choisissez votre moyen de paiement et le montant '
            'que vous souhaitez ajouter.',
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [
        _buildProgressItem(0, 'Informations'),
        Expanded(
          child: Container(
            height: 2,
            color: _step >= 1 ? _green : const Color(0xFFE2E8E3),
          ),
        ),
        _buildProgressItem(1, 'Vérification'),
        Expanded(
          child: Container(
            height: 2,
            color: _step >= 2 ? _green : const Color(0xFFE2E8E3),
          ),
        ),
        _buildProgressItem(2, 'Résultat'),
      ],
    );
  }

  Widget _buildProgressItem(int index, String label) {
    final active = _step >= index;

    return Column(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: active ? _green : const Color(0xFFE7ECE8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: active && index < _step
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active ? Colors.white : _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? _green : _muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _green,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSourceTile(_RechargeSource source) {
    final selected = _selectedSource == source.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectSource(source.id),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _green : const Color(0xFFE8ECE9),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                _buildLogo(source, size: 48),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        source.description,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? _green : Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(_RechargeSource source, {double size = 48}) {
    if (source.logoUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: source.color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.account_balance_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          source.logoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: source.color,
              alignment: Alignment.center,
              child: Text(
                source.id == 'wave'
                    ? 'W'
                    : source.id == 'orange'
                    ? 'OM'
                    : 'FM',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [_ThousandsSeparatorInputFormatter()],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: _green,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(
                color: Color(0xFFB7C0BB),
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Positioned(
            right: 0,
            child: Text(
              'FCFA',
              style: TextStyle(
                color: _green,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    const amounts = [10000, 25000, 50000, 100000];

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: amounts.map((amount) {
        final selected = _amount == amount;

        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _selectAmount(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _green : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? _green : const Color(0xFFE5EAE6),
              ),
            ),
            child: Text(
              _formatAmount(amount),
              style: TextStyle(
                color: selected ? Colors.white : _green,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLimits() {
    final amount = _amount;
    String message = 'Minimum : 500 FCFA · Maximum : 1 000 000 FCFA';

    if (amount > 0 && amount < 500) {
      message = 'Le montant minimum est de 500 FCFA.';
    } else if (amount > 1000000) {
      message = 'Le montant maximum est de 1 000 000 FCFA.';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: _muted, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: amount > 1000000 || (amount > 0 && amount < 500)
                  ? Colors.red.shade700
                  : _muted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_outlined, color: _green),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Virement bancaire',
                  style: TextStyle(color: _green, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Les coordonnées bancaires officielles du compte '
            'bénéficiaire seront affichées ici après configuration '
            'du service.',
            style: TextStyle(
              color: Color(0xFF63736A),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _copyBankMessage,
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('Copier la demande de coordonnées'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: const BorderSide(color: _green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: _orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ne communiquez jamais votre code PIN ou votre mot '
              'de passe à un opérateur. La confirmation du paiement '
              'se fera dans le canal officiel du prestataire.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF79512F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Widget? trailing,
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: valueColor ?? _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 9), trailing],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return const Divider(height: 1, color: Color(0xFFE9EEEA));
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE8ECE9)),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: const Color(0xFFDCE3DE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          side: const BorderSide(color: Color(0xFFDCE3DE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 7) {
      return oldValue;
    }

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _format(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String value) {
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(value[i]);
    }

    return buffer.toString();
  }
}

class _RechargeSource {
  final String id;
  final String name;
  final String description;
  final Color color;
  final String? logoUrl;

  const _RechargeSource({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.logoUrl,
  });
}
