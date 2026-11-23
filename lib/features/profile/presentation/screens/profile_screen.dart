import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../auth/presentation/providers/device_auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  String _appearance = 'Auto';
  bool _isLoggingOut = false;

  // Données provisoires : elles seront remplacées par le profil connecté.
  final String _name = 'Idrissa N’Diaye';
  final String _function = 'Personnel éducatif';
  final String _post = 'Professeur';
  final String _ien = '123456789';
  final String _cardNumber = 'CPE-2026-004821';
  final String _assignment = 'IA de Dakar';

  Future<void> _performLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    var serverError = false;

    try {
      await ref.read(deviceAuthServiceProvider).logout();
    } catch (_) {
      // Les tokens locaux sont supprimés dans le finally
      // du DeviceAuthService, même si le serveur est inaccessible.
      serverError = true;
    }

    if (!mounted) return;

    setState(() => _isLoggingOut = false);

    if (serverError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session locale supprimée. La révocation côté serveur '
            'n’a pas pu être confirmée.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }

    if (widget.onLogout != null) {
      widget.onLogout!();
    } else {
      context.go('/login');
    }
  }

  void _showInformation({
    required String title,
    required String description,
    IconData icon = Icons.info_outline_rounded,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 15, 22, 28),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
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
                const SizedBox(height: 25),
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    if (_isLoggingOut) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Déconnexion',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Voulez-vous vraiment vous déconnecter de votre espace enseignant ?',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC94B43),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
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
                  _buildIdentityCard(),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Informations administratives'),
                  const SizedBox(height: 12),
                  _buildAdministrativeCard(),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Services administratifs'),
                  const SizedBox(height: 12),
                  _buildServicesCard(),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Préférences'),
                  const SizedBox(height: 12),
                  _buildPreferencesCard(),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Aide et confidentialité'),
                  const SizedBox(height: 12),
                  _buildHelpCard(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                  const SizedBox(height: 22),
                  _buildFooter(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon profil',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Gérez votre espace personnel.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(Icons.settings_outlined, color: AppTheme.primary),
        ),
      ],
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4B062),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_function · $_post',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: Color(0xFFD9C18E),
                ),
                SizedBox(width: 6),
                Text(
                  'Personnel de l’Éducation nationale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildAdministrativeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _buildInformationRow('IEN', _ien),
          _buildDivider(),
          _buildInformationRow('Carte professionnelle', _cardNumber),
          _buildDivider(),
          _buildInformationRow('Affectation', _assignment),
        ],
      ),
    );
  }

  Widget _buildInformationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.description_outlined,
            title: 'Attestation de service',
            subtitle: 'Délivrée sous 48 h, signée électroniquement',
            iconColor: const Color(0xFF4B79B5),
            onTap: () {
              _showInformation(
                title: 'Attestation de service',
                description:
                    'Votre attestation de service sera accessible ici. '
                    'Elle pourra être générée et signée électroniquement '
                    'après connexion au service administratif.',
                icon: Icons.description_outlined,
              );
            },
          ),
          _buildDivider(),
          _buildActionRow(
            icon: Icons.open_in_new_rounded,
            title: 'Plateformes du SIMEN',
            subtitle: 'Applications et services numériques',
            iconColor: const Color(0xFF4B79B5),
            onTap: () {
              _showInformation(
                title: 'Plateformes du SIMEN',
                description:
                    'Retrouvez les plateformes numériques de '
                    'l’Éducation nationale : apps.education.sn, '
                    'TAGGATU et PLANÈTE.',
                icon: Icons.language_rounded,
              );
            },
          ),
          _buildDivider(),
          _buildActionRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Bulletins de salaire',
            subtitle: 'Disponible en 2027-2028',
            iconColor: AppTheme.textSecondary,
            trailing: _comingSoonBadge(),
            onTap: () {
              _showInformation(
                title: 'Bulletins de salaire',
                description:
                    'Ce service sera disponible dans une prochaine '
                    'version de Mon espace enseignant.',
                icon: Icons.account_balance_wallet_outlined,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _buildSwitchRow(
            icon: Icons.face_retouching_natural_rounded,
            title: 'Déverrouillage biométrique',
            subtitle: 'Utiliser Face ID ou empreinte digitale',
            value: _biometricEnabled,
            onChanged: (value) {
              setState(() => _biometricEnabled = value);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Activation biométrique à connecter au service de sécurité.'
                        : 'Déverrouillage biométrique désactivé.',
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSwitchRow(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications en temps réel',
            subtitle: 'Paiements, versements et sécurité',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          _buildDivider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 21,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Apparence',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.only(left: 33),
                  child: Text(
                    'Suit le réglage du téléphone en mode Auto',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      _buildAppearanceOption('Auto'),
                      _buildAppearanceOption('Clair'),
                      _buildAppearanceOption('Sombre'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceOption(String value) {
    final selected = _appearance == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _appearance = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.headset_mic_outlined,
            title: 'Assistance',
            subtitle: 'Du lundi au samedi, de 8 h à 20 h',
            iconColor: const Color(0xFF36805B),
            onTap: () {
              _showInformation(
                title: 'Assistance',
                description:
                    'Notre équipe d’assistance est prévue pour vous '
                    'accompagner du lundi au samedi, de 8 h à 20 h. '
                    'Les coordonnées de contact seront ajoutées ici.',
                icon: Icons.headset_mic_outlined,
              );
            },
          ),
          _buildDivider(),
          _buildActionRow(
            icon: Icons.shield_outlined,
            title: 'Mes données personnelles',
            subtitle: 'Confidentialité et utilisation de vos données',
            iconColor: const Color(0xFF36805B),
            onTap: () {
              _showInformation(
                title: 'Mes données personnelles',
                description:
                    'Vos informations personnelles sont utilisées '
                    'pour gérer votre espace enseignant, votre identité '
                    'professionnelle et les services associés. '
                    'Les modalités détaillées de traitement seront '
                    'présentées dans la politique de confidentialité.',
                icon: Icons.shield_outlined,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
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

  Widget _comingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'À venir',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
        icon: _isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFC94B43),
                ),
              )
            : const Icon(Icons.logout_rounded, size: 19),
        label: Text(
          _isLoggingOut ? 'Déconnexion en cours...' : 'Se déconnecter',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC94B43),
          side: const BorderSide(color: Color(0xFFE9C9C6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'MON ESPACE ENSEIGNANT',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ministère de l’Éducation nationale · DPTIC',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          'Version de démonstration',
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      indent: 15,
      endIndent: 15,
      color: AppTheme.border,
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppTheme.border),
    );
  }
}
