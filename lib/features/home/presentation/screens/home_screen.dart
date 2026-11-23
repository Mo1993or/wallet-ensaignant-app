import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalance = false;

  // Données de démonstration issues de la maquette HTML.
  // Elles seront remplacées par les données de l'API.
  final String _teacherName = 'Idrissa N’Diaye';
  final String _mainBalance = '287 450';
  final String _formationBalance = '75 000';
  final String _cardNumber = '4821';

  static const Color _darkGreen = Color(0xFF0A3620);
  static const Color _mediumGreen = Color(0xFF145C38);
  static const Color _gold = Color(0xFFF0D898);

  // Transactions de démonstration
  final List<_Transaction> _transactions = [
    _Transaction(
      title: 'Crédit salaire',
      subtitle: 'Aujourd’hui · 09:42',
      amount: '+ 250 000',
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF168047),
      background: const Color(0xFFE5F4EA),
      isIncoming: true,
    ),
    _Transaction(
      title: 'Transfert envoyé',
      subtitle: 'Hier · 16:20',
      amount: '- 15 000',
      icon: Icons.send_rounded,
      color: const Color(0xFFC64B3C),
      background: const Color(0xFFFCEBE8),
      isIncoming: false,
    ),
    _Transaction(
      title: 'Achat librairie',
      subtitle: '04 nov. · 11:35',
      amount: '- 8 500',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFFA87519),
      background: const Color(0xFFFFF3DC),
      isIncoming: false,
    ),
    _Transaction(
      title: 'Forfait téléphonique',
      subtitle: '03 nov. · 08:12',
      amount: '- 2 000',
      icon: Icons.smartphone_rounded,
      color: const Color(0xFF3169B5),
      background: const Color(0xFFEAF1FC),
      isIncoming: false,
    ),
  ];

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sera bientôt disponible.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goTo(String route) {
    context.go(route);
  }

  String _balanceText(String value) {
    return _hideBalance ? '••••••' : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 115),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 18),

              _buildBalanceCard(),

              const SizedBox(height: 16),

              _buildBankCard(),

              const SizedBox(height: 28),

              _buildSectionHeader(
                'Dernières opérations',
                'Tout voir',
                onTap: () => _showComingSoon('Historique des opérations'),
              ),

              const SizedBox(height: 12),

              _buildRecentOperations(),

              const SizedBox(height: 16),

              _buildBenefitsCard(),

              const SizedBox(height: 20),
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
        GestureDetector(
          onTap: () => _goTo('/profile'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1D8250), Color(0xFF0F5A35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: const Center(
              child: Text(
                'IN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour,',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _teacherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () => _showComingSoon('Notifications'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.textPrimary,
                    size: 23,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE34B43),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // BALANCE CARD
  // --------------------------------------------------

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [_mediumGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -65,
            right: -55,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.07),
                  width: 1,
                ),
              ),
            ),
          ),

          Positioned(
            top: -35,
            right: -25,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _gold.withOpacity(0.12), width: 1),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        color: const Color(0xFF00853F),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 4,
                        color: const Color(0xFFFDEF42),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 4,
                        color: const Color(0xFFE31B23),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Solde disponible',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            setState(() {
                              _hideBalance = !_hideBalance;
                            });
                          },
                          icon: Icon(
                            _hideBalance
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white,
                            size: 21,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _balanceText(_mainBalance),
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 5),
                            child: Text(
                              'FCFA',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () => _showComingSoon('Formation et équipement'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Formation et équipement',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.86),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _hideBalance ? '•••••' : _formationBalance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 19),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.add_rounded,
                            label: 'Recharger',
                            onTap: () {
                              context.push('/recharge');
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.send_rounded,
                            label: 'Transférer',
                            onTap: () {
                              context.push('/transfer');
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Payer',
                            onTap: () {
                              context.push('/pay');
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.grid_view_rounded,
                            label: 'Services',
                            onTap: () {
                              context.push('/services');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // VISA CARD PREVIEW
  // --------------------------------------------------

  Widget _buildBankCard() {
    return InkWell(
      onTap: () => _goTo('/card'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 65,
              height: 43,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E6F45), Color(0xFF0A3A22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 6,
                    left: 7,
                    child: Row(
                      children: [
                        _flagPart(const Color(0xFF00853F)),
                        _flagPart(const Color(0xFFFDEF42)),
                        _flagPart(const Color(0xFFE31B23)),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 6,
                    bottom: 3,
                    child: Text(
                      'VISA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visa •••• $_cardNumber',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sans contact activé',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F2E8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Color(0xFF16834D), size: 7),
                  SizedBox(width: 5),
                  Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFF16834D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flagPart(Color color) {
    return Container(width: 5, height: 8, color: color);
  }

  // --------------------------------------------------
  // SECTION HEADER
  // --------------------------------------------------

  Widget _buildSectionHeader(
    String title,
    String action, {
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Text(
              action,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // RECENT OPERATIONS
  // --------------------------------------------------

  Widget _buildRecentOperations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_transactions.length, (index) {
          final transaction = _transactions[index];

          return Column(
            children: [
              _buildTransactionItem(transaction),

              if (index != _transactions.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.7,
                  color: AppTheme.border.withOpacity(0.8),
                  indent: 55,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTransactionItem(_Transaction transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          // Icône de transaction
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: transaction.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(transaction.icon, color: transaction.color, size: 20),
          ),

          const SizedBox(width: 12),

          // Libellé et date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transaction.subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Montant et statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.amount} F',
                style: TextStyle(
                  color: transaction.isIncoming
                      ? const Color(0xFF168047)
                      : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF168047),
                    size: 10,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Réussi',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // BENEFITS
  // --------------------------------------------------

  Widget _buildBenefitsCard() {
    return InkWell(
      onTap: () => _goTo('/benefits'),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF4E4),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFEFE3C6)),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFF2E5C5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFF8E6A22),
                size: 23,
              ),
            ),

            const SizedBox(width: 13),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3 avantages disponibles',
                    style: TextStyle(
                      color: Color(0xFF3D321D),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Équipement numérique, librairie et forfaits '
                    'mobiles négociés par le Ministère.',
                    style: TextStyle(
                      color: Color(0xFF756747),
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8E6A22),
              size: 23,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// TRANSACTION MODEL
// --------------------------------------------------

class _Transaction {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color color;
  final Color background;
  final bool isIncoming;

  const _Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    required this.background,
    required this.isIncoming,
  });
}
