import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

enum BenefitCategory { all, equipment, books, mobile }

class Benefit {
  final String id;
  final String title;
  final String partner;
  final String description;
  final IconData icon;
  final BenefitCategory category;
  final bool available;
  final String? availabilityDate;
  final int? discount;
  final String? exampleLabel;
  final int? examplePrice;

  const Benefit({
    required this.id,
    required this.title,
    required this.partner,
    required this.description,
    required this.icon,
    required this.category,
    required this.available,
    this.availabilityDate,
    this.discount,
    this.exampleLabel,
    this.examplePrice,
  });
}

class BenefitsScreen extends StatefulWidget {
  const BenefitsScreen({super.key});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  BenefitCategory _selectedCategory = BenefitCategory.all;

  final List<Benefit> _benefits = const [
    Benefit(
      id: 'equipment',
      title: '−12 % sur les ordinateurs et tablettes',
      partner: 'Jàngtech, distributeur agréé',
      description:
          'Profitez d’une remise sur une sélection d’ordinateurs et de tablettes. '
          'La remise est appliquée au paiement avec votre carte.',
      icon: Icons.laptop_mac_rounded,
      category: BenefitCategory.equipment,
      available: true,
      discount: 12,
      exampleLabel: 'Tablette 10 pouces',
      examplePrice: 145000,
    ),
    Benefit(
      id: 'mobile',
      title: 'Forfait Éducation 20 Go',
      partner: 'Opérateur partenaire',
      description:
          'Un forfait mobile spécialement négocié pour les personnels de '
          'l’Éducation nationale. Souscription et renouvellement avec votre carte.',
      icon: Icons.phone_android_rounded,
      category: BenefitCategory.mobile,
      available: true,
      exampleLabel: 'Forfait Éducation 20 Go',
      examplePrice: 5000,
    ),
    Benefit(
      id: 'books',
      title: '−10 % sur les manuels et fournitures',
      partner: 'Librairie Jàng',
      description:
          'Bénéficiez d’une réduction sur les manuels scolaires, les ouvrages '
          'pédagogiques et les fournitures. Paiement avec votre portefeuille '
          'Formation et équipement.',
      icon: Icons.menu_book_rounded,
      category: BenefitCategory.books,
      available: true,
      discount: 10,
      exampleLabel: 'Manuels et fournitures',
      examplePrice: 24000,
    ),
    Benefit(
      id: 'transport',
      title: 'Tarifs réduits sur les transports',
      partner: 'TER, BRT et Dakar Dem Dikk',
      description:
          'Des tarifs préférentiels sur les transports en commun sont en cours '
          'de négociation pour les personnels de l’Éducation.',
      icon: Icons.directions_bus_rounded,
      category: BenefitCategory.all,
      available: false,
      availabilityDate: 'Prévu en 2027-2028',
    ),
    Benefit(
      id: 'health',
      title: 'Avantages santé',
      partner: 'Pharmacies et laboratoires partenaires',
      description:
          'Des tarifs négociés sur une sélection de prestations en pharmacie '
          'et en laboratoire sont en préparation.',
      icon: Icons.health_and_safety_outlined,
      category: BenefitCategory.all,
      available: false,
      availabilityDate: 'Prévu en 2027-2028',
    ),
    Benefit(
      id: 'culture',
      title: 'Culture et loisirs',
      partner: 'Musées, monuments et parcs nationaux',
      description:
          'Découvrez prochainement des conditions préférentielles pour visiter '
          'les lieux culturels et touristiques du Sénégal.',
      icon: Icons.account_balance_rounded,
      category: BenefitCategory.all,
      available: false,
      availabilityDate: 'Prévu en 2027-2028',
    ),
  ];

  List<Benefit> get _availableBenefits {
    return _benefits.where((benefit) {
      if (!benefit.available) return false;

      if (_selectedCategory == BenefitCategory.all) return true;

      return benefit.category == _selectedCategory;
    }).toList();
  }

  List<Benefit> get _upcomingBenefits {
    return _benefits.where((benefit) => !benefit.available).toList();
  }

  String _formatPrice(int amount) {
    final value = amount.toString();
    final result = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      result.write(value[i]);

      final remaining = value.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        result.write(' ');
      }
    }

    return '${result.toString()} FCFA';
  }

  int _discountedPrice(Benefit benefit) {
    if (benefit.examplePrice == null || benefit.discount == null) {
      return benefit.examplePrice ?? 0;
    }

    return benefit.examplePrice! -
        (benefit.examplePrice! * benefit.discount! ~/ 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildHeroCard(),
                  const SizedBox(height: 26),
                  _buildSectionTitle(
                    'Vos avantages',
                    '${_availableBenefits.length} disponibles',
                  ),
                  const SizedBox(height: 15),
                  _buildFilters(),
                  const SizedBox(height: 17),
                  ..._availableBenefits.map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildBenefitCard(benefit),
                    ),
                  ),
                  if (_selectedCategory == BenefitCategory.all) ...[
                    const SizedBox(height: 18),
                    _buildSectionTitle('Bientôt disponibles', 'En préparation'),
                    const SizedBox(height: 15),
                    ..._upcomingBenefits.map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildBenefitCard(benefit),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _buildInfoCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avantages',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Des privilèges pensés pour vous.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8D9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 105,
              color: const Color(0xFFB69A6B).withValues(alpha: 0.20),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 15,
                      color: Color(0xFF987343),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ESPACE PRIVILÈGES',
                      style: TextStyle(
                        color: Color(0xFF80643C),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Votre statut\nvous ouvre des portes.',
                style: TextStyle(
                  color: Color(0xFF263D32),
                  fontSize: 23,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Des offres négociées par le Ministère pour '
                'accompagner votre quotidien.',
                style: TextStyle(
                  color: Color(0xFF59665D),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF365C46),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Votre carte professionnelle suffit.',
                      style: TextStyle(
                        color: Color(0xFF365C46),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = [
      (BenefitCategory.all, 'Tous'),
      (BenefitCategory.equipment, 'Équipement'),
      (BenefitCategory.books, 'Librairie'),
      (BenefitCategory.mobile, 'Mobile'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedCategory == filter.$1;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = filter.$1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBenefitCard(Benefit benefit) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showBenefitDetails(benefit),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: benefit.available
                      ? const Color(0xFFF4EBDD)
                      : AppTheme.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  benefit.icon,
                  color: benefit.available
                      ? const Color(0xFF987343)
                      : AppTheme.textSecondary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit.title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      benefit.partner,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStatus(benefit),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(Benefit benefit) {
    final available = benefit.available;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE7F3EA) : const Color(0xFFF0F0ED),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 12,
            color: available ? const Color(0xFF287348) : AppTheme.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            available ? 'Disponible' : benefit.availabilityDate ?? 'À venir',
            style: TextStyle(
              color: available
                  ? const Color(0xFF287348)
                  : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Les offres présentées sont des exemples de démonstration. '
              'Les conditions définitives seront précisées lors de '
              'l’activation des partenariats.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBenefitDetails(Benefit benefit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            25 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 25),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E8D9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      benefit.icon,
                      size: 27,
                      color: const Color(0xFF987343),
                    ),
                  ),
                  const SizedBox(height: 19),
                  Text(
                    benefit.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    benefit.partner,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 17),
                  _buildStatus(benefit),
                  const SizedBox(height: 20),
                  Text(
                    benefit.description,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  if (benefit.available && benefit.examplePrice != null) ...[
                    const SizedBox(height: 22),
                    _buildPriceExample(benefit),
                  ],
                  if (!benefit.available) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              benefit.availabilityDate ?? 'Date à confirmer',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        benefit.available ? 'J’ai compris' : 'Fermer',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceExample(Benefit benefit) {
    final price = benefit.examplePrice!;
    final discount = benefit.discount ?? 0;
    final finalPrice = _discountedPrice(benefit);
    final saving = price - finalPrice;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXEMPLE DE TARIF',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            benefit.exampleLabel ?? '',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (discount > 0) ...[
            Row(
              children: [
                Text(
                  _formatPrice(price),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '−$discount %',
                  style: const TextStyle(
                    color: Color(0xFF287348),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
          Text(
            _formatPrice(finalPrice),
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (saving > 0) ...[
            const SizedBox(height: 5),
            Text(
              'Vous économisez ${_formatPrice(saving)}',
              style: const TextStyle(
                color: Color(0xFF287348),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            'Tarif indicatif de démonstration.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
