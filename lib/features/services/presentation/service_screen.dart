import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/security/widgets/pin_auth_modal.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const Color _green = Color(0xFF173D32);
  static const Color _orange = Color(0xFFF56624);
  static const Color _background = Color(0xFFFAF8F3);
  static const Color _muted = Color(0xFF89938E);
  static const Color _border = Color(0xFFE8ECE9);

  int _step = 0;
  String? _selectedId;
  bool _isLoading = false;
  String _search = '';

  final Map<String, TextEditingController> _controllers = {};

  _ServiceOperator? get _selected {
    for (final item in _operators) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  bool get _isMaritime => _selected?.category == 'maritime';

  int get _amount {
    final value = _controllers['amount']?.text ?? '';
    return int.tryParse(value.replaceAll(' ', '')) ?? 0;
  }

  int get _fee {
    if (_selected == null) return 0;

    if (_isMaritime) {
      final calculated = ((_amount * 0.01) / 50).round() * 50;
      return calculated.clamp(500, 5000).toInt();
    }

    return 100;
  }

  int get _total => _invoiceAmount + _fee;

  int _invoiceAmount = 0;
  String _invoiceNumber = '';
  String _invoiceReference = '';
  String _receiptReference = '';
  String _receiptDate = '';
  bool _paid = false;

  final List<_ServiceOperator> _operators = const [
    _ServiceOperator(
      id: 'woyofal',
      name: 'Woyofal',
      subtitle: 'Électricité prépayée',
      organization: 'Senelec',
      category: 'utility',
      color: Color(0xFFF4B000),
      initials: 'W',
      icon: Icons.bolt_rounded,
      domain: 'senelec.sn',
      fields: [
        _ServiceField(
          keyName: 'meter',
          label: 'Numéro de compteur',
          hint: '11 chiffres',
          example: '14212345678',
          digitsOnly: true,
          minLength: 11,
          maxLength: 11,
        ),
        _ServiceField(
          keyName: 'amount',
          label: 'Montant à recharger (FCFA)',
          hint: 'Ex. 10 000',
          example: '10000',
          digitsOnly: true,
          minLength: 4,
          maxLength: 7,
        ),
      ],
    ),
    _ServiceOperator(
      id: 'seneau',
      name: 'Sen’Eau',
      subtitle: 'Eau potable',
      organization: 'SEN’EAU',
      category: 'utility',
      color: Color(0xFF0A6CB4),
      initials: 'SE',
      icon: Icons.water_drop_rounded,
      domain: 'seneau.sn',
      fields: [
        _ServiceField(
          keyName: 'invoice',
          label: 'Numéro de facture',
          hint: '10 chiffres',
          example: '2610458823',
          digitsOnly: true,
          minLength: 10,
          maxLength: 10,
        ),
        _ServiceField(
          keyName: 'client',
          label: 'Référence client',
          hint: '9 chiffres',
          example: '004512778',
          digitsOnly: true,
          minLength: 9,
          maxLength: 9,
        ),
      ],
    ),
    _ServiceOperator(
      id: 'canal',
      name: 'Canal+',
      subtitle: 'Abonnement télévision',
      organization: 'Canal+',
      category: 'tv',
      color: Color(0xFF171717),
      initials: 'C+',
      icon: Icons.live_tv_rounded,
      domain: 'canalplus-afrique.com',
      fields: [
        _ServiceField(
          keyName: 'invoice',
          label: 'Numéro d’abonné',
          hint: 'Entre 8 et 14 chiffres',
          example: '24510077813',
          digitsOnly: true,
          minLength: 8,
          maxLength: 14,
        ),
        _ServiceField(
          keyName: 'client',
          label: 'Code client',
          hint: 'Entre 6 et 10 chiffres',
          example: '7781203',
          digitsOnly: true,
          minLength: 6,
          maxLength: 10,
        ),
      ],
    ),
    _ServiceOperator(
      id: 'msc',
      name: 'MSC',
      subtitle: 'Armateur maritime',
      organization: 'Armateur',
      category: 'maritime',
      color: Color(0xFF292929),
      initials: 'MSC',
      icon: Icons.directions_boat_rounded,
      domain: 'msc.com',
      sampleInvoice: 'SN26-0045812',
      sampleClient: 'MSC-10458',
      sampleContainer: 'MSCU 123456-7',
    ),
    _ServiceOperator(
      id: 'cmacgm',
      name: 'CMA CGM',
      subtitle: 'Armateur maritime',
      organization: 'Armateur',
      category: 'maritime',
      color: Color(0xFF0B2E6B),
      initials: 'CMA',
      icon: Icons.directions_boat_rounded,
      domain: 'cma-cgm.com',
      sampleInvoice: 'SNDKR26-112045',
      sampleClient: 'CMA-88217',
      sampleContainer: 'CMAU 123456-7',
    ),
    _ServiceOperator(
      id: 'grimaldi',
      name: 'Grimaldi',
      subtitle: 'Transport maritime et conteneurs',
      organization: 'Armateur',
      category: 'maritime',
      color: Color(0xFFB3122E),
      initials: 'GR',
      icon: Icons.directions_boat_rounded,
      domain: 'grimaldi.napoli.it',
      sampleInvoice: 'GRI-26-07731',
      sampleClient: 'GR-3104',
      sampleContainer: 'GCNU 123456-7',
    ),
    _ServiceOperator(
      id: 'dkt',
      name: 'Dakar Terminal',
      subtitle: 'Terminal à conteneurs',
      organization: 'Terminal portuaire',
      category: 'maritime',
      color: Color(0xFF0E6E8C),
      initials: 'DT',
      icon: Icons.anchor_rounded,
      domain: 'aglgroup.com',
      sampleInvoice: 'DKT-2611-3398',
      sampleClient: 'DT-55021',
      sampleContainer: 'TGHU 123456-7',
    ),
    _ServiceOperator(
      id: 'agl',
      name: 'AGL',
      subtitle: 'Logistique et manutention portuaire',
      organization: 'Terminal portuaire',
      category: 'maritime',
      color: Color(0xFFD9531E),
      initials: 'AGL',
      icon: Icons.local_shipping_rounded,
      domain: 'aglgroup.com',
      sampleInvoice: 'AGLSN-264519',
      sampleClient: 'AGL-7720',
      sampleContainer: 'TCLU 123456-7',
    ),
    _ServiceOperator(
      id: 'atl',
      name: 'ATL',
      subtitle: 'Transit et logistique',
      organization: 'Transit',
      category: 'maritime',
      color: Color(0xFF5B3A9B),
      initials: 'ATL',
      icon: Icons.inventory_2_rounded,
      domain: 'atl.com',
      sampleInvoice: 'ATL-26-11872',
      sampleClient: 'ATL-3391',
      sampleContainer: 'SEGU 123456-7',
    ),
  ];

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prepareOperator(_ServiceOperator operator) {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();
    _selectedId = operator.id;

    if (operator.category == 'maritime') {
      _controllers['invoice'] = TextEditingController(
        text: operator.sampleInvoice,
      );
      _controllers['client'] = TextEditingController(
        text: operator.sampleClient,
      );
    } else {
      for (final field in operator.fields) {
        _controllers[field.keyName] = TextEditingController();
      }
    }

    setState(() {
      _step = 1;
      _invoiceAmount = 0;
      _paid = false;
    });
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String? _validateForm() {
    final operator = _selected;
    if (operator == null) return 'Choisissez un opérateur.';

    if (operator.category == 'maritime') {
      final invoice = _controllers['invoice']!.text.trim();
      final client = _controllers['client']!.text.trim();

      if (!RegExp(r'^[A-Za-z0-9\-/]{6,20}$').hasMatch(invoice)) {
        return 'Le numéro de facture doit contenir entre 6 et 20 caractères.';
      }

      if (!RegExp(r'^[A-Za-z0-9\-]{4,12}$').hasMatch(client)) {
        return 'Le code client doit contenir entre 4 et 12 caractères.';
      }

      return null;
    }

    for (final field in operator.fields) {
      final value = _controllers[field.keyName]?.text.trim() ?? '';

      if (value.isEmpty) {
        return 'Veuillez renseigner : ${field.label}.';
      }

      if (value.length < field.minLength || value.length > field.maxLength) {
        return '${field.label} : format invalide.';
      }

      if (field.keyName == 'amount') {
        final amount = int.tryParse(value.replaceAll(' ', '')) ?? 0;

        if (amount < 1000 || amount > 500000) {
          return 'Le montant doit être compris entre 1 000 et 500 000 FCFA.';
        }
      }
    }

    return null;
  }

  Future<void> _verifyInvoice() async {
    FocusScope.of(context).unfocus();

    final error = _validateForm();

    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1100));

    if (!mounted) return;

    final operator = _selected!;
    final invoice =
        _controllers['invoice']?.text.trim() ??
        _controllers['meter']?.text.trim() ??
        '';
    final client = _controllers['client']?.text.trim() ?? '';

    int amount;

    switch (operator.category) {
      case 'utility':
        amount = operator.id == 'woyofal' ? _amount : 12500;
        break;
      case 'tv':
        amount = 10000;
        break;
      default:
        amount = 95000;
    }

    setState(() {
      _isLoading = false;
      _invoiceNumber = invoice;
      _invoiceReference = client;
      _invoiceAmount = amount;
      _step = 2;
    });
  }

  Future<void> _confirmPayment() async {
    final operator = _selected;
    if (operator == null || _isLoading) return;

    FocusScope.of(context).unfocus();

    final confirmed = await PinAuthModal.show(
      context,
      title: 'Confirmer le paiement',
      subtitle: 'Confirmez ${_formatAmount(_total)} FCFA à ${operator.name}',
      allowBiometrics: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _paid = true;
      _step = 3;
      _receiptReference =
          'FAC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      _receiptDate = _dateNow();
    });
  }

  String _dateNow() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} à $hour:$minute';
  }

  String _buildMaritimeQrData(_ServiceOperator operator) {
    return [
      'MON ESPACE ENSEIGNANT',
      'RECU DE PAIEMENT - DEMONSTRATION',
      'Operateur: ${operator.name}',
      'Reference: $_receiptReference',
      'Facture: $_invoiceNumber',
      'Client: $_invoiceReference',
      'Conteneur: ${operator.sampleContainer ?? ''}',
      'Montant facture: $_invoiceAmount FCFA',
      'Frais: $_fee FCFA',
      'Total: $_total FCFA',
      'Date: $_receiptDate',
      'Statut: SIMULATION',
    ].join('\n');
  }

  void _goBack() {
    if (_step == 3) {
      setState(() {
        _step = 0;
        _selectedId = null;
      });
    } else if (_step > 0) {
      setState(() {
        _step = _step == 2 ? 1 : 0;
      });
    } else {
      context.pop();
    }
  }

  void _reset() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();

    setState(() {
      _step = 0;
      _selectedId = null;
      _invoiceAmount = 0;
      _invoiceNumber = '';
      _invoiceReference = '';
      _receiptReference = '';
      _receiptDate = '';
      _paid = false;
      _search = '';
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
          icon: const Icon(Icons.arrow_back_rounded, color: _green),
        ),
        title: Text(
          _step == 0
              ? 'Services'
              : _step == 1
              ? _selected?.name ?? 'Informations'
              : _step == 2
              ? 'Vérification'
              : 'Reçu de paiement',
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
              ? _buildServicesPage()
              : _step == 1
              ? _buildFormPage()
              : _step == 2
              ? _buildInvoicePage()
              : _buildReceiptPage(),
        ),
      ),
    );
  }

  Widget _buildServicesPage() {
    final utilities = _operators
        .where((item) => item.category != 'maritime')
        .toList();

    final maritime = _operators
        .where((item) => item.category == 'maritime')
        .toList();

    final filteredMaritime = maritime.where((item) {
      return _search.isEmpty ||
          item.name.toLowerCase().contains(_search.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      key: const ValueKey('services'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.receipt_long_rounded, color: Colors.white, size: 29),
                SizedBox(height: 15),
                Text(
                  'Vos factures, en toute simplicité',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Retrouvez vos services du quotidien et vos opérations '
                  'maritimes depuis votre espace enseignant.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _sectionTitle('Factures et abonnements'),
          const SizedBox(height: 13),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: utilities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: 1.23,
            ),
            itemBuilder: (context, index) => _serviceTile(utilities[index]),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: _sectionTitle('Services maritimes')),
              Text(
                '${maritime.length} opérateurs',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Armateurs, terminaux et transitaires du Port de Dakar.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _border),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                icon: Icon(Icons.search_rounded, color: _muted),
                hintText: 'Rechercher un opérateur',
                hintStyle: TextStyle(color: _muted, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                for (var i = 0; i < filteredMaritime.length; i++)
                  _operatorRow(
                    filteredMaritime[i],
                    showDivider: i != filteredMaritime.length - 1,
                  ),
                if (filteredMaritime.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Aucun opérateur trouvé.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _simulationNotice(),
        ],
      ),
    );
  }

  Widget _serviceTile(_ServiceOperator operator) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _prepareOperator(operator),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _operatorLogo(operator, size: 43),
              const Spacer(),
              Text(
                operator.name,
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                operator.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _operatorRow(_ServiceOperator operator, {bool showDivider = true}) {
    return Column(
      children: [
        InkWell(
          onTap: () => _prepareOperator(operator),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                _operatorLogo(operator, size: 43),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operator.name,
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        operator.subtitle,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
                  size: 23,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 68, color: _border),
      ],
    );
  }

  Widget _operatorLogo(_ServiceOperator operator, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: operator.color,
              alignment: Alignment.center,
              child: Text(
                operator.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: operator.initials.length > 2 ? 10 : 14,
                ),
              ),
            ),
            if (operator.domain != null)
              Image.network(
                'https://www.google.com/s2/favicons?domain=${operator.domain}&sz=128',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPage() {
    final operator = _selected;
    if (operator == null) return const SizedBox.shrink();

    final fields = operator.category == 'maritime'
        ? [
            _ServiceField(
              keyName: 'invoice',
              label: 'Numéro de facture',
              hint: 'Ex. ${operator.sampleInvoice}',
              example: operator.sampleInvoice ?? '',
              minLength: 6,
              maxLength: 20,
            ),
            _ServiceField(
              keyName: 'client',
              label: 'Code client',
              hint: 'Ex. ${operator.sampleClient}',
              example: operator.sampleClient ?? '',
              minLength: 4,
              maxLength: 12,
            ),
          ]
        : operator.fields;

    return SingleChildScrollView(
      key: const ValueKey('service-form'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 27),
          Row(
            children: [
              _operatorLogo(operator, size: 58),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operator.name,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      operator.subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 27),
          const Text(
            'Informations de paiement',
            style: TextStyle(
              color: _green,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Renseignez les informations figurant sur votre facture '
            'ou votre contrat.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 22),
          ...fields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: _buildInputField(field),
            ),
          ),
          if (operator.category == 'maritime') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _green,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Exemple de conteneur : ${operator.sampleContainer}. '
                      'Le numéro de conteneur pourra être demandé '
                      'sur votre facture.',
                      style: const TextStyle(
                        color: Color(0xFF63736A),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (operator.id == 'woyofal') ...[
            _buildAmountQuickChoices(),
            const SizedBox(height: 14),
            const Text(
              'Montant minimum : 1 000 FCFA · Maximum : 500 000 FCFA',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 25),
          _primaryButton(
            label: 'Vérifier la facture',
            onPressed: _isLoading ? null : _verifyInvoice,
            loading: _isLoading,
          ),
          const SizedBox(height: 12),
          _secondaryButton(
            label: 'Changer d’opérateur',
            onPressed: () => setState(() => _step = 0),
          ),
          const SizedBox(height: 16),
          _simulationNotice(),
        ],
      ),
    );
  }

  Widget _buildInputField(_ServiceField field) {
    final isAmount = field.keyName == 'amount';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            color: _green,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controllers[field.keyName],
                  keyboardType: field.digitsOnly || isAmount
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters: [
                    if (field.digitsOnly || isAmount)
                      FilteringTextInputFormatter.digitsOnly,
                    if (isAmount) _AmountInputFormatter(),
                    if (field.maxLength > 0)
                      LengthLimitingTextInputFormatter(field.maxLength),
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: field.hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFFB7C0BB),
                      fontSize: 13,
                    ),
                  ),
                  style: const TextStyle(
                    color: _green,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isAmount)
                const Text(
                  'FCFA',
                  style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountQuickChoices() {
    const amounts = [5000, 10000, 25000, 50000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Montants rapides',
          style: TextStyle(
            color: _green,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amounts.map((amount) {
            return InkWell(
              onTap: () {
                final controller = _controllers['amount']!;
                controller.text = _formatAmount(amount);
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
                setState(() {});
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _formatAmount(amount),
                  style: const TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInvoicePage() {
    final operator = _selected;
    if (operator == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey('invoice'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 28),
          const Text(
            'Facture retrouvée',
            style: TextStyle(
              color: _green,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Vérifiez les informations avant de confirmer le paiement.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _operatorLogo(operator, size: 54),
                const SizedBox(height: 14),
                Text(
                  operator.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '${_formatAmount(_invoiceAmount)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
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
                    'Facture à régler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Détails de la facture'),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _detailRow('Opérateur', operator.name),
                _detailDivider(),
                _detailRow(
                  operator.id == 'woyofal'
                      ? 'Numéro de compteur'
                      : 'Numéro de facture',
                  _invoiceNumber,
                ),
                if (_invoiceReference.isNotEmpty) ...[
                  _detailDivider(),
                  _detailRow('Référence client', _invoiceReference),
                ],
                if (operator.category == 'utility' &&
                    operator.id == 'woyofal') ...[
                  _detailDivider(),
                  _detailRow('Type', 'Recharge prépayée'),
                ],
                if (operator.category == 'tv') ...[
                  _detailDivider(),
                  _detailRow('Formule', 'Abonnement · 1 mois'),
                ],
                if (operator.category == 'maritime') ...[
                  _detailDivider(),
                  _detailRow('Objet', 'Facture de prestation maritime'),
                  _detailDivider(),
                  _detailRow('Conteneur', operator.sampleContainer ?? ''),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Récapitulatif'),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _detailRow(
                  'Montant de la facture',
                  '${_formatAmount(_invoiceAmount)} FCFA',
                ),
                _detailDivider(),
                _detailRow('Frais de service', '${_formatAmount(_fee)} FCFA'),
                _detailDivider(),
                _detailRow(
                  'Total à payer',
                  '${_formatAmount(_total)} FCFA',
                  highlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _securityNotice(),
          const SizedBox(height: 24),
          _primaryButton(
            label: 'Payer ${_formatAmount(_total)} FCFA',
            onPressed: _isLoading ? null : _confirmPayment,
            loading: _isLoading,
          ),
          const SizedBox(height: 12),
          _secondaryButton(
            label: 'Modifier les informations',
            onPressed: () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REÇU DE PAIEMENT — STYLE TICKET HTML
  // ---------------------------------------------------------------------------

  Widget _buildReceiptPage() {
    final operator = _selected;
    if (operator == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey('receipt'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          _buildProgress(),
          const SizedBox(height: 28),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFE2F5E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: _green, size: 42),
          ),
          const SizedBox(height: 17),
          const Text(
            'Paiement effectué',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre opération de démonstration est terminée.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 25),

          _buildReceiptTicket(operator),

          if (operator.id == 'woyofal') ...[
            const SizedBox(height: 17),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3E4D2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code de recharge de démonstration',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '4821 7360 1945 8273 6104',
                    style: TextStyle(
                      color: _green,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Ce code est fictif et ne peut pas être utilisé sur un compteur.',
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 17),
          _simulationNotice(),
          const SizedBox(height: 24),
          _primaryButton(label: 'Terminer', onPressed: () => context.pop()),
          const SizedBox(height: 12),
          _secondaryButton(
            label: 'Effectuer une autre opération',
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTicket(_ServiceOperator operator) {
    return PhysicalShape(
      clipper: _ReceiptClipper(),
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x26000000),
      child: CustomPaint(
        foregroundPainter: const _ReceiptBorderPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(19, 23, 19, 20),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête du ticket
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'MON ESPACE',
                    style: TextStyle(
                      color: _green,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'REÇU DE PAIEMENT',
                    style: TextStyle(
                      color: Color(0xFF68776E),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 17),

              // Bloc opérateur encadré
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5EBE7)),
                ),
                child: Row(
                  children: [
                    _operatorLogo(operator, size: 45),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            operator.name,
                            style: const TextStyle(
                              color: Color(0xFF16201A),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            operator.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF68776E),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Montant principal
              Padding(
                padding: const EdgeInsets.only(top: 19, bottom: 15),
                child: Column(
                  children: [
                    const Text(
                      'MONTANT TOTAL',
                      style: TextStyle(
                        color: Color(0xFF68776E),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatAmount(_total)} FCFA',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF16201A),
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF178A4F),
                          width: 1.3,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '✓  Effectué',
                        style: TextStyle(
                          color: Color(0xFF178A4F),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _receiptDashedDivider(),

              const SizedBox(height: 10),
              _receiptRow('Statut', 'Effectué'),
              _receiptRow('Référence', _receiptReference),
              _receiptRow('Date', _receiptDate),
              _receiptRow('Facture', _invoiceNumber),

              if (_invoiceReference.isNotEmpty)
                _receiptRow('Référence client', _invoiceReference),

              if (operator.category == 'maritime')
                _receiptRow('Conteneur', operator.sampleContainer ?? ''),

              const SizedBox(height: 9),
              _receiptDashedDivider(),
              const SizedBox(height: 9),

              _receiptRow(
                'Montant facture',
                '${_formatAmount(_invoiceAmount)} FCFA',
              ),
              _receiptRow('Frais de service', '${_formatAmount(_fee)} FCFA'),

              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.only(top: 11),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFD6DED8), width: 1.2),
                  ),
                ),
                child: _receiptRow(
                  'TOTAL PAYÉ',
                  '${_formatAmount(_total)} FCFA',
                  isTotal: true,
                ),
              ),

              // QR code placé en pied de ticket pour les opérations maritimes
              if (operator.category == 'maritime') ...[
                const SizedBox(height: 13),
                _receiptDashedDivider(),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFD6DED8),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: _buildMaritimeQrData(operator),
                        version: QrVersions.auto,
                        size: 76,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VOTRE REÇU',
                            style: TextStyle(
                              color: Color(0xFF16201A),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Scannez ce QR code pour consulter les '
                            'informations de cette opération.',
                            style: TextStyle(
                              color: Color(0xFF68776E),
                              fontSize: 10,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'QR code de démonstration.',
                            style: TextStyle(
                              color: Color(0xFF89938E),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 13),
                _receiptDashedDivider(),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Merci d’utiliser Mon espace enseignant.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF68776E),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'DOCUMENT DE DÉMONSTRATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF89938E),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 1 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                color: isTotal
                    ? const Color(0xFF16201A)
                    : const Color(0xFF68776E),
                fontSize: isTotal ? 12 : 10.5,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: const Color(0xFF16201A),
                fontSize: isTotal ? 13 : 10.5,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptDashedDivider() {
    return const SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }

  Widget _buildProgress() {
    const labels = ['Informations', 'Vérification', 'Paiement'];

    return Row(
      children: List.generate(3, (index) {
        final active = _step >= index + 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: active ? _green : const Color(0xFFE7ECE8),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: active && _step > index + 1
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
                    labels[index],
                    style: TextStyle(
                      color: active ? _green : _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (index != 2)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(
                      left: 7,
                      right: 7,
                      bottom: 17,
                    ),
                    color: _step > index + 1 ? _green : const Color(0xFFE2E8E3),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _green,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool highlighted = false,
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
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? _green,
                fontSize: 12,
                fontWeight: highlighted ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() {
    return const Divider(height: 1, color: _border);
  }

  Widget _securityNotice() {
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
              'Ne communiquez jamais votre véritable code PIN à un opérateur. '
              'La confirmation affichée ici est uniquement une simulation.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF79512F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simulationNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _orange, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Mode démonstration : aucune facture réelle n’est consultée, '
              'aucun paiement n’est envoyé et aucun solde n’est débité. '
              'La connexion à l’API sera nécessaire pour activer le service.',
              style: TextStyle(
                color: Color(0xFF79512F),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _border),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
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
        child: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _secondaryButton({
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

// -----------------------------------------------------------------------------
// FORMES ET BORDURES DU TICKET
// -----------------------------------------------------------------------------

class _ReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const scallopRadius = 6.0;
    const scallopSpacing = 14.0;

    final path = Path();
    final topY = scallopRadius;
    final bottomY = size.height - scallopRadius;

    path.moveTo(0, topY);

    // Bord gauche
    path.lineTo(0, bottomY);

    // Bord inférieur festonné
    var x = 0.0;
    while (x < size.width) {
      final nextX = (x + scallopSpacing).clamp(0.0, size.width).toDouble();
      final middleX = (x + nextX) / 2;

      path.quadraticBezierTo(
        middleX,
        size.height + scallopRadius,
        nextX,
        bottomY,
      );

      x = nextX;
    }

    // Bord droit
    path.lineTo(size.width, topY);

    // Bord supérieur festonné
    x = size.width;
    while (x > 0) {
      final nextX = (x - scallopSpacing).clamp(0.0, size.width).toDouble();
      final middleX = (x + nextX) / 2;

      path.quadraticBezierTo(middleX, -scallopRadius, nextX, topY);

      x = nextX;
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ReceiptClipper oldClipper) => false;
}

class _ReceiptBorderPainter extends CustomPainter {
  const _ReceiptBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const scallopRadius = 6.0;
    const scallopSpacing = 14.0;

    final paint = Paint()
      ..color = const Color(0xFFE0E7E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    final topY = scallopRadius;
    final bottomY = size.height - scallopRadius;

    path.moveTo(0, topY);
    path.lineTo(0, bottomY);

    var x = 0.0;
    while (x < size.width) {
      final nextX = (x + scallopSpacing).clamp(0.0, size.width).toDouble();
      path.quadraticBezierTo(
        (x + nextX) / 2,
        size.height + scallopRadius,
        nextX,
        bottomY,
      );
      x = nextX;
    }

    path.lineTo(size.width, topY);

    x = size.width;
    while (x > 0) {
      final nextX = (x - scallopSpacing).clamp(0.0, size.width).toDouble();
      path.quadraticBezierTo((x + nextX) / 2, -scallopRadius, nextX, topY);
      x = nextX;
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReceiptBorderPainter oldDelegate) => false;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD6DED8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    var startX = 0.0;

    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width).toDouble();

      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );

      startX = endX + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// MODÈLES
// -----------------------------------------------------------------------------

class _ServiceOperator {
  final String id;
  final String name;
  final String subtitle;
  final String organization;
  final String category;
  final Color color;
  final String initials;
  final IconData icon;
  final String? domain;
  final String? sampleInvoice;
  final String? sampleClient;
  final String? sampleContainer;
  final List<_ServiceField> fields;

  const _ServiceOperator({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.organization,
    required this.category,
    required this.color,
    required this.initials,
    required this.icon,
    this.domain,
    this.sampleInvoice,
    this.sampleClient,
    this.sampleContainer,
    this.fields = const [],
  });
}

class _ServiceField {
  final String keyName;
  final String label;
  final String hint;
  final String example;
  final bool digitsOnly;
  final int minLength;
  final int maxLength;

  const _ServiceField({
    required this.keyName,
    required this.label,
    required this.hint,
    required this.example,
    this.digitsOnly = false,
    this.minLength = 1,
    this.maxLength = 50,
  });
}

class _AmountInputFormatter extends TextInputFormatter {
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
