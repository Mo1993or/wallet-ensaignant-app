import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class TransferScreen extends StatefulWidget {
  final int availableBalance;

  const TransferScreen({super.key, this.availableBalance = 287450});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  static const Color _green = Color(0xFF173D32);
  static const Color _blue = Color(0xFF2878B8);
  static const Color _orange = Color(0xFFF56624);
  static const Color _background = Color(0xFFFAF8F3);
  static const Color _muted = Color(0xFF89938E);
  static const Color _border = Color(0xFFE8ECE9);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int _step = 0;
  int _amount = 0;
  String? _errorMessage;
  _Beneficiary? _selectedBeneficiary;

  final List<_Beneficiary> _beneficiaries = const [
    _Beneficiary(
      id: 'b1',
      name: 'Awa Diop',
      role: 'Professeure de lettres, Lycée de Grand-Yoff',
      ien: '0412 8876 03',
      phone: '77 412 88 76',
    ),
    _Beneficiary(
      id: 'b2',
      name: 'Moussa Fall',
      role: 'Directeur d’école, Sicap Liberté',
      ien: '0398 1102 17',
      phone: '76 398 11 02',
    ),
    _Beneficiary(
      id: 'b3',
      name: 'Fatou Sarr',
      role: 'Institutrice, EE Médina 2',
      ien: '0577 2049 22',
      phone: '78 577 20 49',
    ),
    _Beneficiary(
      id: 'b4',
      name: 'Ousmane Ba',
      role: 'Inspecteur, IEF de Pikine',
      ien: '0221 6640 09',
      phone: '77 221 66 40',
    ),
  ];

  int get _balance => widget.availableBalance;

  int get _remainingBalance => _balance - _amount;

  bool get _isValidAmount {
    return _amount >= 100 && _amount <= 300000 && _amount <= _balance;
  }

  List<_Beneficiary> get _filteredBeneficiaries {
    final query = _searchController.text.toLowerCase().replaceAll(
      RegExp(r'\s'),
      '',
    );

    if (query.isEmpty) return _beneficiaries;

    return _beneficiaries.where((beneficiary) {
      final searchable =
          (beneficiary.name + beneficiary.ien + beneficiary.phone)
              .toLowerCase()
              .replaceAll(RegExp(r'\s'), '');

      return searchable.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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

  String _initials(String name) {
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();
  }

  void _selectBeneficiary(_Beneficiary beneficiary) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedBeneficiary = beneficiary;
      _step = 1;
      _errorMessage = null;
    });
  }

  void _setAmount(int amount) {
    setState(() {
      _amount = amount;
      _amountController.text = _formatAmount(amount);
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
      _validateAmount();
    });
  }

  void _onAmountChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;

    setState(() {
      _amount = amount;
      _validateAmount();
    });
  }

  void _validateAmount() {
    if (_amount == 0) {
      _errorMessage = null;
    } else if (_amount < 100) {
      _errorMessage = 'Le montant minimum est de 100 FCFA.';
    } else if (_amount > 300000) {
      _errorMessage = 'Le plafond par transfert est de 300 000 FCFA.';
    } else if (_amount > _balance) {
      _errorMessage =
          'Solde insuffisant : ${_formatAmount(_balance)} FCFA disponibles.';
    } else {
      _errorMessage = null;
    }
  }

  void _continueToSummary() {
    if (!_isValidAmount || _selectedBeneficiary == null) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _step = 2;
    });
  }

  void _confirmTransfer() {
    FocusScope.of(context).unfocus();

    // Aucun transfert réel n'est effectué.
    // Cette étape sera connectée à l'API de transfert.
    setState(() {
      _step = 3;
    });
  }

  void _goBack() {
    if (_step == 3) {
      setState(() => _step = 2);
    } else if (_step == 2) {
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 0);
    } else {
      context.pop();
    }
  }

  void _newTransfer() {
    setState(() {
      _step = 0;
      _amount = 0;
      _errorMessage = null;
      _selectedBeneficiary = null;
      _searchController.clear();
      _amountController.clear();
      _noteController.clear();
    });
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
              ? 'Transférer'
              : _step == 1
              ? 'Montant'
              : _step == 2
              ? 'Vérification'
              : 'Transfert',
          style: const TextStyle(
            color: _green,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == 0
              ? _buildBeneficiaryPage()
              : _step == 1
              ? _buildAmountPage()
              : _step == 2
              ? _buildSummaryPage()
              : _buildResultPage(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ÉTAPE 1 : BÉNÉFICIAIRE
  // ------------------------------------------------------------

  Widget _buildBeneficiaryPage() {
    final beneficiaries = _filteredBeneficiaries;

    return SingleChildScrollView(
      key: const ValueKey('beneficiary'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 25),
          const Text(
            'Transférer de l’argent',
            style: TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envoyez de l’argent à un autre titulaire de la carte, '
            'gratuitement et instantanément.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 22),
          _buildBalanceCard(),
          const SizedBox(height: 25),
          const Text(
            'Choisir un bénéficiaire',
            style: TextStyle(
              color: _green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _buildSearchField(),
          const SizedBox(height: 15),
          if (beneficiaries.isEmpty)
            _buildEmptySearch()
          else
            Container(
              decoration: _whiteCardDecoration(),
              child: Column(
                children: [
                  for (var i = 0; i < beneficiaries.length; i++) ...[
                    _buildBeneficiaryTile(beneficiaries[i]),
                    if (i != beneficiaries.length - 1)
                      const Divider(height: 1, indent: 65, color: _border),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 18),
          _buildDemoNotice(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  'Portefeuille principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(_balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'FCFA',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _muted, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Nom, IEN ou téléphone',
                hintStyle: TextStyle(color: Color(0xFFADB6B0), fontSize: 13),
              ),
              style: const TextStyle(
                color: _green,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.close_rounded, color: _muted, size: 19),
            ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryTile(_Beneficiary beneficiary) {
    return InkWell(
      onTap: () => _selectBeneficiary(beneficiary),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _initials(beneficiary.name),
                style: const TextStyle(
                  color: _blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beneficiary.name,
                    style: const TextStyle(
                      color: _green,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    beneficiary.role,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 23),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, color: _muted, size: 34),
          SizedBox(height: 10),
          Text(
            'Aucun titulaire trouvé',
            style: TextStyle(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Vérifiez le nom, l’IEN ou le numéro saisi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ÉTAPE 2 : MONTANT
  // ------------------------------------------------------------

  Widget _buildAmountPage() {
    final beneficiary = _selectedBeneficiary!;

    return SingleChildScrollView(
      key: const ValueKey('amount'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 25),
          const Text(
            'Montant du transfert',
            style: TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Indiquez le montant que vous souhaitez envoyer.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 23),
          _buildSelectedBeneficiary(beneficiary),
          const SizedBox(height: 25),
          const Text(
            'Montant à envoyer',
            style: TextStyle(
              color: _green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _buildAmountField(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red.shade700,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 17),
          _buildQuickAmounts(),
          const SizedBox(height: 25),
          const Text(
            'Motif du transfert',
            style: TextStyle(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _buildNoteField(),
          const SizedBox(height: 22),
          _buildAvailableBalance(),
          const SizedBox(height: 25),
          _buildPrimaryButton(
            label: 'Continuer',
            onPressed: _isValidAmount ? _continueToSummary : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBeneficiary(_Beneficiary beneficiary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Row(
        children: [
          _buildAvatar(beneficiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beneficiary.name,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'IEN ${beneficiary.ien}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text(
              'Changer',
              style: TextStyle(
                color: _green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(_Beneficiary beneficiary) {
    return Container(
      width: 43,
      height: 43,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _initials(beneficiary.name),
        style: const TextStyle(
          color: _blue,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [_ThousandsSeparatorInputFormatter()],
            onChanged: _onAmountChanged,
            style: const TextStyle(
              color: _green,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(
                color: Color(0xFFB7C0BB),
                fontSize: 27,
                fontWeight: FontWeight.w800,
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
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    const amounts = [5000, 10000, 25000, 50000];

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: amounts.map((amount) {
        final selected = _amount == amount;

        return InkWell(
          onTap: () => _setAmount(amount),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _green : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: selected ? _green : _border),
            ),
            child: Text(
              _formatAmount(amount),
              style: TextStyle(
                color: selected ? Colors.white : _green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _noteController,
        maxLength: 40,
        maxLines: 2,
        minLines: 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: 'Cotisation tontine, remboursement…',
          hintStyle: TextStyle(color: Color(0xFFADB6B0), fontSize: 12),
          labelText: 'Facultatif',
          labelStyle: TextStyle(color: _muted, fontSize: 11),
        ),
        style: const TextStyle(color: _green, fontSize: 13),
      ),
    );
  }

  Widget _buildAvailableBalance() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: _green,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Solde disponible',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          Text(
            '${_formatAmount(_balance)} FCFA',
            style: const TextStyle(
              color: _green,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ÉTAPE 3 : RÉCAPITULATIF
  // ------------------------------------------------------------

  Widget _buildSummaryPage() {
    final beneficiary = _selectedBeneficiary!;

    return SingleChildScrollView(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 25),
          const Text(
            'Vérifiez le transfert',
            style: TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vérifiez les informations avant de confirmer.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Text(
                  'MONTANT DU TRANSFERT',
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
                    'Transfert entre titulaires',
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
          const Text(
            'Détails du transfert',
            style: TextStyle(
              color: _green,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: _whiteCardDecoration(),
            child: Column(
              children: [
                _buildSummaryRow('Bénéficiaire', beneficiary.name),
                _buildSummaryDivider(),
                _buildSummaryRow('IEN', beneficiary.ien),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Motif',
                  _noteController.text.trim().isEmpty
                      ? 'Aucun'
                      : _noteController.text.trim(),
                ),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Frais',
                  'Gratuit',
                  valueColor: const Color(0xFF26845B),
                ),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Solde après transfert',
                  '${_formatAmount(_remainingBalance)} FCFA',
                  isHighlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _buildSecurityNotice(),
          const SizedBox(height: 25),
          _buildPrimaryButton(
            label: 'Confirmer avec mon code',
            icon: Icons.lock_outline_rounded,
            onPressed: _confirmTransfer,
          ),
          const SizedBox(height: 12),
          _buildSecondaryButton(
            label: 'Modifier',
            onPressed: () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
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
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return const Divider(height: 1, color: _border);
  }

  // ------------------------------------------------------------
  // ÉTAPE 4 : RÉSULTAT
  // ------------------------------------------------------------

  Widget _buildResultPage() {
    final beneficiary = _selectedBeneficiary!;

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
              color: const Color.fromARGB(255, 222, 255, 227),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.check_circle, color: _green, size: 42),
          ),
          const SizedBox(height: 22),
          const Text(
            'Demande éffectuée',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Votre transfer a été effectué',
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
                _buildSummaryRow('Bénéficiaire', beneficiary.name),
                _buildSummaryDivider(),
                _buildSummaryRow('IEN', beneficiary.ien),
                _buildSummaryDivider(),
                _buildSummaryRow('Statut', 'Effectué', valueColor: _green),
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
                Icon(Icons.info_outline_rounded, color: _orange, size: 21),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucun argent n’a été envoyé et votre solde '
                    'n’a pas été modifié. La connexion à l’API '
                    'de transfert sera nécessaire pour effectuer '
                    'une vraie opération.',
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
            label: 'Nouveau transfert',
            onPressed: _newTransfer,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // COMPOSANTS COMMUNS
  // ------------------------------------------------------------

  Widget _buildProgress() {
    final labels = ['Bénéficiaire', 'Montant', 'Vérification'];

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Column(
            children: [
              Container(
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _step >= i ? _green : const Color(0xFFE7ECE8),
                  shape: BoxShape.circle,
                ),
                child: _step > i
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: _step >= i ? Colors.white : _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  color: _step >= i ? _green : _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (i != labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 17),
                color: _step > i ? _green : const Color(0xFFE2E8E3),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildDemoNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _blue, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Les bénéficiaires affichés sont des données de '
              'démonstration. La liste réelle sera chargée depuis '
              'le service des titulaires.',
              style: TextStyle(
                color: Color(0xFF45677F),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
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
              'Vérifiez toujours le nom et l’IEN du bénéficiaire '
              'avant de confirmer un transfert.',
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

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
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

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _border),
    );
  }
}

class _Beneficiary {
  final String id;
  final String name;
  final String role;
  final String ien;
  final String phone;

  const _Beneficiary({
    required this.id,
    required this.name,
    required this.role,
    required this.ien,
    required this.phone,
  });
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 7) return oldValue;

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
