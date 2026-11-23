import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';

class MainNavigationScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    final color = selected ? AppTheme.primary : AppTheme.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _onDestinationSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalTab({required bool selected}) {
    return Expanded(
      child: InkWell(
        onTap: () => _onDestinationSelected(2),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                top: -25,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2FA36A), Color(0xFF1D8250)],
                        ),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: AppTheme.surface, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1D8250,
                            ).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Carte pro',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTab(
                      index: 0,
                      icon: Icons.home_rounded,
                      label: 'Accueil',
                      selected: currentIndex == 0,
                    ),
                    _buildTab(
                      index: 1,
                      icon: Icons.credit_card_rounded,
                      label: 'Carte',
                      selected: currentIndex == 1,
                    ),
                    _buildProfessionalTab(selected: currentIndex == 2),
                    _buildTab(
                      index: 3,
                      icon: Icons.card_giftcard_rounded,
                      label: 'Avantages',
                      selected: currentIndex == 3,
                    ),
                    _buildTab(
                      index: 4,
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      selected: currentIndex == 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
