import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/app_theme.dart';
import '../../data/models/teacher_card_model.dart';
import '../providers/teacher_card_provider.dart';

class ProfessionalCardScreen extends ConsumerWidget {
  const ProfessionalCardScreen({super.key});

  static const Color _darkGreen = Color(0xFF0A3620);
  static const Color _mediumGreen = Color(0xFF145C38);
  static const Color _gold = Color(0xFFE8CD8C);

  String _display(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Non renseigné';
    }
    return value.trim();
  }

  String _personnelType(String? type) {
    switch (type) {
      case 'corps_enseignant':
        return 'Corps enseignant';
      case 'contractuel_structure':
        return 'Contractuel de structure';
      default:
        return 'Personnel de l’Éducation';
    }
  }

  bool _hasQrCode(TeacherCardModel card) {
    return card.qrCode != null && card.qrCode!.trim().isNotEmpty;
  }

  ImageProvider? _photoProvider(TeacherCardModel card) {
    final base64Image = card.photo?.base64;

    if (base64Image == null || base64Image.trim().isEmpty) {
      return null;
    }

    try {
      final cleaned = base64Image.contains(',')
          ? base64Image.split(',').last
          : base64Image;

      return MemoryImage(base64Decode(cleaned));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardState = ref.watch(teacherCardProvider);

    return cardState.when(
      loading: () => _buildLoadingScreen(),
      error: (error, stackTrace) => _buildErrorScreen(context, ref, error),
      data: (card) => _buildContent(context, card),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, Object error) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 55,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Carte professionnelle indisponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(teacherCardProvider.notifier).reload();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TeacherCardModel card) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildIntro(),
                  const SizedBox(height: 22),
                  _buildProfessionalCard(card),
                  const SizedBox(height: 24),
                  _buildQrSection(card),
                  const SizedBox(height: 24),
                  _buildInformationSection(card),
                  const SizedBox(height: 24),
                  _buildPrivacySection(),
                  const SizedBox(height: 18),
                  _buildSyncNotice(card),
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
                'MON ESPACE ENSEIGNANT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Carte professionnelle',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.8,
                ),
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
          child: Icon(Icons.badge_outlined, color: AppTheme.primary, size: 23),
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Text(
      'Votre identité professionnelle numérique. Présentez votre carte pour justifier votre qualité de personnel de l’Éducation nationale.',
      style: TextStyle(
        fontSize: 13,
        height: 1.55,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildProfessionalCard(TeacherCardModel card) {
    final photo = _photoProvider(card);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkGreen, _mediumGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -55,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 25,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 5,
            child: Icon(
              Icons.account_balance_outlined,
              size: 105,
              color: Colors.white.withOpacity(0.045),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSenegalFlag(),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'RÉPUBLIQUE DU SÉNÉGAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.7,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ministère de l’Éducation nationale',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(card),
                ],
              ),
              const SizedBox(height: 25),
              Container(height: 1, color: Colors.white.withOpacity(0.16)),
              const SizedBox(height: 17),
              const Text(
                'CARTE PROFESSIONNELLE',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _personnelType(card.typePersonnel),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 21),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      image: photo == null
                          ? null
                          : DecorationImage(image: photo, fit: BoxFit.cover),
                    ),
                    child: photo == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                            size: 42,
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _display(card.fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _display(card.function),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _display(card.structure?.libelle),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.16)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _cardData('MATRICULE', _display(card.matricule)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _cardData('IEN', _display(card.ien))),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 15,
                    color: _gold,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Identité professionnelle APPS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    'SIMEN',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
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

  Widget _buildSenegalFlag() {
    return Container(
      width: 31,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 3),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: Container(color: const Color(0xFF00853F))),
          Expanded(
            child: Container(
              color: Colors.yellow,
              child: const Center(
                child: Icon(Icons.star, color: Color(0xFF00853F), size: 12),
              ),
            ),
          ),
          Expanded(child: Container(color: const Color(0xFFE31B23))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TeacherCardModel card) {
    // APPS ne fournit pas actuellement de statut ACTIVE/SUSPENDED.
    // On affiche donc la source de la carte, sans inventer un statut.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF73E3A1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'APPS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardData(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildQrSection(TeacherCardModel card) {
    final qrData = card.qrCode;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: AppTheme.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code professionnel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'QR code fourni par APPS',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.verified_user_rounded,
                color: AppTheme.primary,
                size: 23,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: qrData == null || qrData.trim().isEmpty
                  ? SizedBox(
                      width: 190,
                      height: 190,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 55,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'QR code indisponible',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  : QrImageView(
                      key: ValueKey(qrData),
                      data: qrData,
                      version: QrVersions.auto,
                      size: 190,
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
            ),
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 17, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasQrCode(card)
                      ? 'Ce QR code est fourni par APPS et associé à votre identité professionnelle.'
                      : 'Aucun QR code professionnel n’est actuellement fourni par APPS.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(TeacherCardModel card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Informations administratives',
          'Les informations associées à votre carte',
        ),
        const SizedBox(height: 13),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _infoRow(
                Icons.badge_outlined,
                'Matricule',
                _display(card.matricule),
                copyable: true,
              ),
              _infoDivider(),
              _infoRow(
                Icons.fingerprint_rounded,
                'Identifiant IEN',
                _display(card.ien),
                copyable: true,
              ),
              _infoDivider(),
              _infoRow(Icons.school_outlined, 'Corps', _display(card.corps)),
              _infoDivider(),
              _infoRow(
                Icons.work_outline_rounded,
                'Fonction',
                _display(card.function),
              ),
              _infoDivider(),
              _infoRow(
                Icons.account_balance_outlined,
                'Structure',
                _display(card.structure?.libelle),
              ),
              _infoDivider(),
              _infoRow(
                Icons.alternate_email_rounded,
                'Email professionnel',
                _display(card.professionalEmail),
                copyable: true,
              ),
              _infoDivider(),
              _infoRow(
                Icons.phone_outlined,
                'Téléphone',
                _display(card.telephone),
                copyable: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (copyable && value != 'Non renseigné')
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              icon: Icon(
                Icons.copy_rounded,
                size: 17,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoDivider() {
    return Divider(height: 1, thickness: 1, indent: 65, color: AppTheme.border);
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Confidentialité',
          'Gardez le contrôle de vos informations',
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4ED),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFD6E9DA)),
          ),
          child: Column(
            children: [
              _privacyRow(
                Icons.check_circle_rounded,
                const Color(0xFF16834D),
                'Informations professionnelles',
                'Identité, matricule, fonction et structure.',
              ),
              const SizedBox(height: 16),
              _privacyRow(
                Icons.lock_rounded,
                const Color(0xFFB54B42),
                'Informations toujours privées',
                'Numéro de carte bancaire, solde et opérations.',
              ),
              const SizedBox(height: 16),
              _privacyRow(
                Icons.verified_user_rounded,
                const Color(0xFF416A9A),
                'Données issues d’APPS',
                'Les informations affichées proviennent de votre carte professionnelle synchronisée.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _privacyRow(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncNotice(TeacherCardModel card) {
    final syncedAt = card.syncedAt;

    final syncText = syncedAt == null
        ? 'Date de synchronisation indisponible'
        : 'Synchronisée le '
              '${syncedAt.day.toString().padLeft(2, '0')}/'
              '${syncedAt.month.toString().padLeft(2, '0')}/'
              '${syncedAt.year}';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sync_rounded, size: 17, color: AppTheme.textSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$syncText • Source : ${_display(card.source)}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
